//! Deterministic, conflict-aware merge of vault states.
//!
//! The merge is driven entirely by per-item version vectors, never by wall
//! clock time. It is pure: inputs are borrowed, a new vault is returned, and
//! applying the same inputs twice never creates a second conflict copy.

use std::collections::{BTreeMap, HashMap};

use uuid::Uuid;
use zeroize::Zeroizing;

use crate::error::Error;
use crate::vault::model::{
    now_unix, Entry, Folder, Tombstone, Vault, TOMBSTONE_RETENTION_SECS, VAULT_SCHEMA_VERSION,
};

use super::payload::SyncPayload;
use super::version::{DeviceId, VectorOrder, VersionVector};

/// What the merge changed, for a non-secret status/report.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct MergeReport {
    pub entries_added: usize,
    pub entries_updated: usize,
    pub folders_added: usize,
    pub folders_updated: usize,
    pub conflicts_created: usize,
    pub tombstones_applied: usize,
}

/// Merge the local vault with every remote payload.
///
/// `local_device` is this device's sync id; it is used to stamp new conflict
/// copies so they cannot collide with a remote item on a later sync.
pub fn merge(
    local: &Vault,
    remotes: &[SyncPayload],
    local_device: &DeviceId,
) -> Result<(Vault, MergeReport), Error> {
    let now = now_unix();
    let mut report = MergeReport::default();
    let mut merged = local.clone();
    merged.schema_version = VAULT_SCHEMA_VERSION;

    let purge_tombstones = collect_tombstones(local, remotes, now);

    merged.entries = merge_items(
        local.entries.iter().collect(),
        remotes
            .iter()
            .flat_map(|payload| payload.entries.iter())
            .collect(),
        &purge_tombstones,
        local_device,
        now,
        false,
        &mut report,
    )?;

    merged.folders = merge_items(
        local.folders.iter().collect(),
        remotes
            .iter()
            .flat_map(|payload| payload.folders.iter())
            .collect(),
        &purge_tombstones,
        local_device,
        now,
        true,
        &mut report,
    )?;
    normalize_folder_order(&mut merged.folders);

    merged.tombstones = purge_tombstones
        .into_values()
        .map(|(tombstone, _)| tombstone)
        .collect();
    merged.tombstones.sort_by_key(|tombstone| tombstone.id);

    Ok((merged, report))
}

/// Union all tombstones, keeping the causally newest marker per id and
/// dropping markers older than the retention window.
fn collect_tombstones(
    local: &Vault,
    remotes: &[SyncPayload],
    now: u64,
) -> HashMap<Uuid, (Tombstone, Zeroizing<Vec<u8>>)> {
    let mut tombstones: HashMap<Uuid, (Tombstone, Zeroizing<Vec<u8>>)> = HashMap::new();
    for tombstone in local
        .tombstones
        .iter()
        .chain(remotes.iter().flat_map(|payload| payload.tombstones.iter()))
    {
        if tombstone
            .purged_at
            .is_some_and(|purged_at| now.saturating_sub(purged_at) >= TOMBSTONE_RETENTION_SECS)
        {
            continue;
        }
        let bytes = Zeroizing::new(serialize(tombstone));
        tombstones
            .entry(tombstone.id)
            .and_modify(|(kept, kept_bytes)| {
                if tombstone.version.dominates(&kept.version) {
                    *kept = tombstone.clone();
                    *kept_bytes = bytes.clone();
                }
            })
            .or_insert((tombstone.clone(), bytes));
    }
    tombstones
}

/// Merge entries or folders. `is_folder` selects the item-specific behavior
/// (folder order and conflict naming) while sharing the causal algorithm.
fn merge_items<'a, T: SyncItem + Clone + 'a>(
    locals: Vec<&'a T>,
    remote_items: Vec<&'a T>,
    tombstones: &HashMap<Uuid, (Tombstone, Zeroizing<Vec<u8>>)>,
    local_device: &DeviceId,
    now: u64,
    is_folder: bool,
    report: &mut MergeReport,
) -> Result<Vec<T>, Error> {
    let mut by_id: BTreeMap<Uuid, Vec<Candidate<'a, T>>> = BTreeMap::new();
    for (is_local, item) in locals
        .into_iter()
        .map(|item| (true, item))
        .chain(remote_items.into_iter().map(|item| (false, item)))
    {
        by_id
            .entry(item.id())
            .or_default()
            .push(Candidate::new(is_local, item)?);
    }

    let mut output = Vec::with_capacity(by_id.len());
    for (id, candidates) in by_id {
        if let Some((tombstone, _)) = tombstones.get(&id) {
            if candidates
                .iter()
                .all(|candidate| tombstone.version.dominates(&candidate.version))
            {
                // Purge wins; the item must not reappear.
                report.tombstones_applied += 1;
                continue;
            }
        }

        let had_local = candidates.iter().any(|candidate| candidate.is_local);
        let local_content = candidates
            .iter()
            .find(|candidate| candidate.is_local)
            .map(|candidate| candidate.bytes.clone());

        let mut winner = candidates[0].clone();
        let mut concurrent: Vec<Candidate<'a, T>> = Vec::new();
        for candidate in candidates.iter().skip(1) {
            // Pre-v5 items have no vector at all. Without causality information
            // we must not silently pick one of two divergent legacy versions.
            if winner.version.is_empty() && candidate.version.is_empty() {
                if candidate.bytes != winner.bytes {
                    concurrent.push(candidate.clone());
                }
                continue;
            }
            match winner.version.compare(&candidate.version) {
                VectorOrder::Equal => {
                    if candidate.bytes != winner.bytes && tie_break(&winner, candidate) {
                        winner = candidate.clone();
                    }
                }
                VectorOrder::After => {}
                VectorOrder::Before => winner = candidate.clone(),
                VectorOrder::Concurrent => concurrent.push(candidate.clone()),
            }
        }

        // Concurrent versions with identical content are the same state.
        concurrent.retain(|candidate| candidate.bytes != winner.bytes);
        // Two remote files can carry the same stale version; one copy is enough.
        concurrent.dedup_by(|a, b| a.version == b.version && a.bytes == b.bytes);

        let mut joined = winner.version.clone();
        for candidate in &concurrent {
            joined = joined.join(&candidate.version);
        }
        winner.version = joined;

        if !had_local {
            if is_folder {
                report.folders_added += 1;
            } else {
                report.entries_added += 1;
            }
        } else if local_content.as_ref() != Some(&winner.bytes) {
            if is_folder {
                report.folders_updated += 1;
            } else {
                report.entries_updated += 1;
            }
        }

        let mut item = (*winner.item).clone();
        item.set_version(winner.version, winner.updated_by);
        output.push(item);

        for candidate in &concurrent {
            let mut copy = (*candidate.item).clone();
            let fresh_id = Uuid::now_v7();
            copy.set_id(fresh_id);
            copy.rename_conflict(date_suffix(now));
            let mut version = candidate.version.clone();
            version.bump(local_device);
            copy.set_version(version, *local_device);
            output.push(copy);
            report.conflicts_created += 1;
        }
    }

    Ok(output)
}

/// A versioned item from one input, with its serialized content cached for
/// equality checks. `bytes` excludes nothing: duplicate detection must see the
/// whole item, including secrets, but the buffer is zeroized on drop.
struct Candidate<'a, T> {
    is_local: bool,
    item: &'a T,
    version: VersionVector,
    updated_by: DeviceId,
    bytes: Zeroizing<Vec<u8>>,
}

impl<'a, T: SyncItem> Clone for Candidate<'a, T> {
    fn clone(&self) -> Self {
        Self {
            is_local: self.is_local,
            item: self.item,
            version: self.version.clone(),
            updated_by: self.updated_by,
            bytes: self.bytes.clone(),
        }
    }
}

impl<'a, T: SyncItem> Candidate<'a, T> {
    fn new(is_local: bool, item: &'a T) -> Result<Self, Error> {
        Ok(Self {
            is_local,
            item,
            version: item.version().clone(),
            updated_by: item.updated_by(),
            bytes: Zeroizing::new(serialize(item)),
        })
    }
}

/// Deterministic tie-break for items with equal vectors but different content.
fn tie_break<T: SyncItem>(current: &Candidate<'_, T>, other: &Candidate<'_, T>) -> bool {
    other.updated_by.cmp(&current.updated_by).is_lt()
        || (other.updated_by == current.updated_by
            && other.bytes.as_slice() < current.bytes.as_slice())
}

/// Items handled by the merge (entries and folders).
pub(crate) trait SyncItem: serde::Serialize {
    fn id(&self) -> Uuid;
    fn version(&self) -> &VersionVector;
    fn updated_by(&self) -> DeviceId;
    fn set_version(&mut self, version: VersionVector, updated_by: DeviceId);
    fn set_id(&mut self, id: Uuid);
    fn rename_conflict(&mut self, date: String);
}

impl SyncItem for Entry {
    fn id(&self) -> Uuid {
        self.id
    }
    fn version(&self) -> &VersionVector {
        &self.sync_meta.version
    }
    fn updated_by(&self) -> DeviceId {
        self.sync_meta.updated_by
    }
    fn set_version(&mut self, version: VersionVector, updated_by: DeviceId) {
        self.sync_meta.version = version;
        self.sync_meta.updated_by = updated_by;
    }
    fn set_id(&mut self, id: Uuid) {
        self.id = id;
    }
    fn rename_conflict(&mut self, date: String) {
        self.title = format!("{} (conflict {})", self.title, date);
    }
}

impl SyncItem for Folder {
    fn id(&self) -> Uuid {
        self.id
    }
    fn version(&self) -> &VersionVector {
        &self.sync_meta.version
    }
    fn updated_by(&self) -> DeviceId {
        self.sync_meta.updated_by
    }
    fn set_version(&mut self, version: VersionVector, updated_by: DeviceId) {
        self.sync_meta.version = version;
        self.sync_meta.updated_by = updated_by;
    }
    fn set_id(&mut self, id: Uuid) {
        self.id = id;
    }
    fn rename_conflict(&mut self, date: String) {
        self.name = format!("{} (conflict {})", self.name, date);
    }
}

fn serialize<T: serde::Serialize>(item: &T) -> Vec<u8> {
    let mut bytes = Vec::new();
    ciborium::into_writer(item, &mut bytes).expect("serializing a vault item cannot fail");
    bytes
}

/// Keep folder order dense and deterministic after a merge.
fn normalize_folder_order(folders: &mut [Folder]) {
    folders.sort_by(|a, b| a.order.cmp(&b.order).then_with(|| a.id.cmp(&b.id)));
    for (index, folder) in folders.iter_mut().enumerate() {
        folder.order = index as u32;
    }
}

/// UTC `YYYY-MM-DD` for a Unix timestamp, without a date-time dependency.
fn date_suffix(timestamp: u64) -> String {
    let days = (timestamp / 86_400) as i64;
    let z = days + 719_468;
    let era = if z >= 0 { z } else { z - 146_096 } / 146_097;
    let day_of_era = z - era * 146_097;
    let year_of_era =
        (day_of_era - day_of_era / 1460 + day_of_era / 36_524 - day_of_era / 146_096) / 365;
    let year = year_of_era + era * 400;
    let day_of_year = day_of_era - (365 * year_of_era + year_of_era / 4 - year_of_era / 100);
    let month_prime = (5 * day_of_year + 2) / 153;
    let day = day_of_year - (153 * month_prime + 2) / 5 + 1;
    let month = month_prime + if month_prime < 10 { 3 } else { -9 };
    let year = year + i64::from(month <= 2);
    format!("{year:04}-{month:02}-{day:02}")
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::vault::model::{EntryBody, Note, TombstoneKind};

    fn device(n: u8) -> DeviceId {
        let mut id = [0u8; 16];
        id[15] = n;
        id
    }

    fn note(title: &str, content: &str) -> Entry {
        Entry::note(
            title,
            Note {
                content: content.into(),
            },
        )
    }

    fn versioned(mut entry: Entry, device: &DeviceId) -> Entry {
        entry.sync_meta.version.bump(device);
        entry.sync_meta.updated_by = *device;
        entry
    }

    fn payload(entries: Vec<Entry>) -> SyncPayload {
        SyncPayload {
            schema_version: VAULT_SCHEMA_VERSION,
            folders: Vec::new(),
            entries,
            tombstones: Vec::new(),
        }
    }

    fn purge(id: Uuid, version: &VersionVector) -> Tombstone {
        Tombstone {
            id,
            deleted_at: Some(now_unix()),
            purged_at: Some(now_unix()),
            version: version.clone(),
            kind: TombstoneKind::Entry,
        }
    }

    #[test]
    fn only_local_and_only_remote_are_preserved() {
        let a = device(1);
        let local_entry = versioned(note("local", "l"), &a);
        let mut local = Vault::new();
        local.add_entry(local_entry.clone());
        let remote_entry = versioned(note("remote", "r"), &a);
        let remotes = vec![payload(vec![remote_entry.clone()])];

        let (merged, report) = merge(&local, &remotes, &a).unwrap();
        assert_eq!(merged.entries.len(), 2);
        assert_eq!(report.entries_added, 1);
        assert!(merged.entries.iter().any(|entry| entry.title == "local"));
        assert!(merged.entries.iter().any(|entry| entry.title == "remote"));
    }

    #[test]
    fn dominant_versions_win() {
        let a = device(1);
        let older = versioned(note("item", "old"), &a);
        let mut newer = older.clone();
        newer = versioned(newer, &a);
        newer.title = "item".into();
        let newer = {
            let mut entry = newer;
            entry.notes = "new".into();
            entry.sync_meta.version.bump(&a);
            entry
        };
        let mut local = Vault::new();
        local.add_entry(older.clone());

        let (merged, report) = merge(&local, &[payload(vec![newer.clone()])], &a).unwrap();
        assert_eq!(merged.entries.len(), 1);
        assert_eq!(merged.entries[0].notes, "new");
        assert_eq!(report.entries_updated, 1);

        // The reverse: a local edit dominates a stale remote copy.
        let mut local2 = Vault::new();
        local2.add_entry(newer.clone());
        let (merged2, _) = merge(&local2, &[payload(vec![older])], &a).unwrap();
        assert_eq!(merged2.entries.len(), 1);
        assert_eq!(merged2.entries[0].notes, "new");
    }

    #[test]
    fn concurrent_edits_keep_a_conflict_copy_once() {
        let a = device(1);
        let b = device(2);
        let mut base = note("item", "base");
        base.sync_meta.version.bump(&a);
        let mut from_a = base.clone();
        from_a.notes = "a edit".into();
        from_a.sync_meta.version.bump(&a);
        from_a.sync_meta.updated_by = a;
        let mut from_b = base;
        from_b.notes = "b edit".into();
        from_b.sync_meta.version.bump(&b);
        from_b.sync_meta.updated_by = b;

        let mut local = Vault::new();
        local.add_entry(from_a);
        let remotes = vec![payload(vec![from_b])];

        let (merged, report) = merge(&local, &remotes, &a).unwrap();
        assert_eq!(merged.entries.len(), 2);
        assert_eq!(report.conflicts_created, 1);
        assert!(merged.entries.iter().any(|entry| entry.title == "item"));
        assert!(merged
            .entries
            .iter()
            .any(|entry| entry.title.starts_with("item (conflict ")));

        // Idempotency: merging the result again with the same remote file adds
        // nothing and leaves the state byte-identical.
        let (again, again_report) = merge(&merged, &remotes, &a).unwrap();
        assert_eq!(again_report.conflicts_created, 0);
        assert_eq!(again, merged);
    }

    #[test]
    fn identical_vectors_and_content_are_a_no_op() {
        let a = device(1);
        let entry = versioned(note("same", "value"), &a);
        let mut local = Vault::new();
        local.add_entry(entry.clone());
        let (merged, report) = merge(&local, &[payload(vec![entry])], &a).unwrap();
        assert_eq!(merged, local);
        assert_eq!(report, MergeReport::default());
    }

    #[test]
    fn edit_wins_over_delete_as_a_conflict_copy() {
        let a = device(1);
        let b = device(2);
        let mut base = note("item", "base");
        base.sync_meta.version.bump(&a);
        let mut deleted = base.clone();
        deleted.deleted_at = Some(now_unix());
        deleted.sync_meta.version.bump(&a);
        let mut edited = base;
        edited.notes = "edited".into();
        edited.sync_meta.version.bump(&b);

        let mut local = Vault::new();
        local.add_entry(deleted);
        let (merged, report) = merge(&local, &[payload(vec![edited])], &a).unwrap();
        assert_eq!(report.conflicts_created, 1);
        let live = merged
            .entries
            .iter()
            .find(|entry| !entry.title.contains("conflict"))
            .unwrap();
        assert!(live.deleted_at.is_some());
        assert!(merged.entries.iter().any(|entry| entry.notes == "edited"));
    }

    #[test]
    fn purge_tombstone_prevents_resurrection() {
        let a = device(1);
        let mut entry = versioned(note("gone", "secret"), &a);
        entry.sync_meta.version.bump(&a);
        let tombstone = purge(entry.id, &entry.sync_meta.version);
        let mut local = Vault::new();
        local.tombstones.push(tombstone);

        let (merged, _) = merge(&local, &[payload(vec![entry])], &a).unwrap();
        assert!(merged.entries.is_empty());
        assert_eq!(merged.tombstones.len(), 1);
    }

    #[test]
    fn folder_conflicts_and_order_are_idempotent() {
        let a = device(1);
        let b = device(2);
        let mut local = Vault::new();
        let id = local.add_folder("Work");
        let folder = local.folders[0].clone();
        let mut local_folder = folder.clone();
        local_folder.sync_meta.version.bump(&a);
        local_folder.sync_meta.updated_by = a;
        local.folders[0] = local_folder;

        let mut remote_folder = folder;
        remote_folder.name = "Work (renamed)".into();
        remote_folder.sync_meta.version.bump(&b);
        remote_folder.sync_meta.updated_by = b;
        let remotes = vec![SyncPayload {
            schema_version: VAULT_SCHEMA_VERSION,
            folders: vec![remote_folder],
            entries: Vec::new(),
            tombstones: Vec::new(),
        }];

        let (merged, report) = merge(&local, &remotes, &a).unwrap();
        assert_eq!(report.conflicts_created, 1);
        assert_eq!(merged.folders.len(), 2);
        assert!(merged.folders.iter().any(|folder| folder.name == "Work"));
        assert!(merged
            .folders
            .iter()
            .any(|folder| folder.name.contains("(conflict ")));

        let (again, again_report) = merge(&merged, &remotes, &a).unwrap();
        assert_eq!(again_report.conflicts_created, 0);
        assert_eq!(again.folders.len(), 2);
        for (index, folder) in again.folders.iter().enumerate() {
            assert_eq!(folder.order, index as u32);
        }
        assert_eq!(again.folders[0].id, id);
    }

    #[test]
    fn date_suffix_is_formatted_as_utc_date() {
        assert_eq!(date_suffix(0), "1970-01-01");
        assert_eq!(date_suffix(1_760_000_000), "2025-10-09");
    }

    #[test]
    fn legacy_empty_vectors_with_different_content_conflict() {
        let a = device(1);
        let mut local = Vault::new();
        let base = note("legacy", "local");
        local.add_entry(base.clone());
        let mut divergent = base;
        divergent.notes = "remote".into();
        let remotes = vec![payload(vec![divergent])];
        let (merged, report) = merge(&local, &remotes, &a).unwrap();
        assert_eq!(report.conflicts_created, 1);
        assert_eq!(merged.entries.len(), 2);
    }

    #[test]
    fn merge_never_emits_a_non_entry_body() {
        let a = device(1);
        let local_entry = versioned(note("a", "b"), &a);
        let mut local = Vault::new();
        local.add_entry(local_entry);
        let (merged, _) = merge(&local, &[], &a).unwrap();
        assert!(matches!(merged.entries[0].body, EntryBody::Note(_)));
    }
}
