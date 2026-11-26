# 1.5.0 — Opt-in user-controlled E2EE sync — Design draft

**Date:** 2026-11-19
**Status:** Implemented in 1.5.0. Builds on 1.3.0 (schema v3, custom fields),
1.4.0 (schema v4, passkeys) and the existing vault/crypto/session architecture.
**Scope:** architecture, wire format, pairing, merge strategy and backend
abstraction. This document is the reference for the 1.5.0 implementation.

---

## 0. Summary of decisions

| Topic | Decision |
|---|---|
| Hosting | **No Keyel server or account.** The user selects a local folder; their own tool (Syncthing, Nextcloud, a cloud-drive client, a USB stick) moves the bytes. |
| Backend | One file **per device** in the shared folder (`keyel-sync-<sync>-<device>.kys`). No write conflicts between devices; no network code in Keyel. |
| Key | A random 256-bit **sync key** established once by a pairing code. Stored as a secret inside each device's own vault; never sent to Dart, logs or the backend. |
| Payload | Full vault entries/folders, including secrets, re-encrypted under the sync key. The backend only ever sees ciphertext and non-secret routing metadata. |
| Change model | Per-item **version vectors** + explicit device id. Enables correct detection of concurrent edits rather than guessing from wall-clock time. |
| Merge | Deterministic 3-way merge; only-local / only-remote apply cleanly, concurrent edits keep both via a **conflict copy** (no silent overwrite). Deletes are tombstones; purges propagate. |
| Activation | Opt-in, manual, foreground, vault-unlocked only. Safe first-run restore with explicit confirmation. |
| Schema | Additive **v5** payload: sync config (secret), per-item sync metadata, tombstones. v1–v4 migrate forward losslessly. |

---

## 1. Goals and non-goals

### Goals
- Sync is strictly opt-in and works with a user-controlled location (no Keyel
  service/account, no new `INTERNET` usage).
- Sync payloads are end-to-end encrypted client-side; the backend never sees
  the vault key, master password, recovery key, sync key or plaintext.
- Multi-device edits converge predictably with conflict detection/merge,
  recoverable history and **no silent data loss**.
- Clear sync status, manual controls, and safe first-time pairing/restore.
- Tests cover the crypto envelope, pairing, merge matrix, tampered/corrupt
  remote state, and failure/retry behavior.

### Non-goals for 1.5.0
- Keyel-hosted relay, discovery, accounts or push notifications.
- Automatic background sync on mobile (manual + foreground only; battery and
  lock-state friendly).
- Native WebDAV/S3 clients — the file-based backend plus the user's existing
  sync tool already covers these transports.
- Multi-user shared vaults, attachments, or field-level interactive conflict
  resolution UI (conflict *copies* are sufficient for 1.5.0).

> **1.13.1 clarification:** sync room creation can now optionally run a
> LocalSend-style local-network discovery pass to *show nearby Keyel devices*.
> This is only a UI convenience for finding a peer on the same Wi-Fi/LAN; it is
> not a sync transport, it sends no vault data or pairing secret, and the
> `KYSYNC1-…` code remains the sole trust root. The file-based backend above is
> unchanged, and manual code entry still works when discovery is unavailable.

---

## 2. Relationship to existing crypto

Keyel already has a proven envelope in `crates/keyel_core/src/format/` and
`docs/crypto-design.md`:

- Vault key: 32 random bytes; never leaves Rust.
- Body: XChaCha20-Poly1305 with `body_aad = "KYL1" || version || vault_id`.
- Master KEK: Argon2id; recovery KEK: HKDF-SHA256; canonical CBOR header check.

Sync **reuses the primitives but not the vault key**:

```
local vault (unlocked in Rust)
      │  decrypt with vault_key (master/recovery)
      ▼
plain Vault { entries, folders }  ──merge──► merged Vault
      │  encrypt with sync_key
      ▼
keyel-sync-...kys  (shared folder, user's tool transports it)
```

The vault key stays inside the existing session. The sync key is a separate
secret, also confined to Rust. Nothing above the core sees either key.

---

## 3. Sync identity and pairing

### 3.1 Identifiers

```
sync_key[32]   = OS CSPRNG            // shared secret; never leaves Rust
sync_id[16]    = UUID v7              // sync group id; non-secret, in every blob header
device_id[16]  = UUID v7              // generated on first sync enable; non-secret
```

`sync_id` groups devices; `device_id` disambiguates concurrent writers and is
the key for version vectors.

### 3.2 Pairing code (one-time)

The first device shows a pairing code (QR + copyable text) once:

```
"KYSYNC1" + base32_nopad( sync_id[16] || sync_key[32] || tag[4] )
tag = SHA256( "KYSYNC1/pairing/v1" || sync_id || sync_key )[0..4]
```

- 52 bytes → 84 base32 characters + prefix; scannable as a QR code.
- The 4-byte tag detects typos/partial scans, not attackers — the key itself is
  authenticated by every blob's AEAD tag.
- The pairing code is a **bearer secret**: anyone who sees it can read all
  synced vaults. UI must show it once, require "I saved it" confirmation, and
  keep it off logs/screenshots (reuse the `FLAG_SECURE` pattern used for reveal).
- A joiner that scans it stores `sync_id` + `sync_key` in its **own** vault
  (schema v5 `sync_config`), so the secret is encrypted under that device's
  vault key and disappears when the vault locks.

### 3.3 Rotating / revoking a device

1.5.0 supports a single sync group with no revocation list. Removing a device
means creating a new sync group (new `sync_id` + `sync_key`) and re-pairing the
remaining devices; this is explicit and documented. Rotating the key in place
is deferred — it requires re-encrypting every device file and a cutover
marker.

---

## 4. Backend abstraction and file format

### 4.1 Backend trait (Rust core)

```rust
pub trait SyncBackend {
    /// Non-secret metadata for every sync file belonging to `sync_id`.
    fn list(&self, sync_id: &[u8; 16]) -> Result<Vec<RemoteFile>>;
    fn read(&self, file: &RemoteFile) -> Result<EncryptedSyncBlob>;
    fn write(&self, file: &RemoteFile, blob: &EncryptedSyncBlob) -> Result<()>;
}
```

First implementation: `FolderBackend { root: PathBuf }`.

- Lists `keyel-sync-<sync_id hex>-*.kys` under `root`.
- Reads/writes only files with the local device's id for push; pulls all files
  matching `sync_id`.
- Writes are atomic (`.tmp` → `fsync` → rename) with a sibling `.bak`, matching
  the vault/backup writer. A truncated file from a crash is read as `Corrupted`
  and surfaced, never applied.
- Dart resolves and passes the folder path (consistent with "Rust never
  hard-codes a path"). On Android this comes from the app-support dir or a
  user-picked document tree; on desktop from a file picker.

One file **per device** avoids the classic "two writers, one file" conflict:
each device only ever writes its own file, and the user's sync tool replicates
all of them. Convergence is achieved by merging *all* device files.

### 4.2 Encrypted blob (fixed binary header + AEAD)

```
offset  size  field
0       4     magic = "KYS1"    (0x4B 0x59 0x53 0x31)
4       2     format_version = 1 (u16 LE)
6       16    sync_id
22      16    writer_device_id
38      8     sequence (u64 LE)        // writer's monotonic counter
46      24    nonce
70      n     ciphertext (plaintext CBOR + 16-byte Poly1305 tag)
```

Constraints: minimum length `70 + 16`; `format_version` must be 1; every
integer is little-endian and fixed width (no CBOR aliases in the header).

```
aad = "KYS1-SYNC/v1" || format_version || sync_id || writer_device_id || sequence
ciphertext = XChaCha20-Poly1305(key = sync_key, nonce, plaintext = SyncPayload, aad)
```

The AAD binds routing metadata: changing `sync_id`, `writer_device_id` or
`sequence` fails authentication. A blob from a different sync group cannot be
re-labeled into this one.

### 4.3 Sync payload (CBOR, inside the blob)

```
SyncPayload {
  schema_version: u16,                  // 5 (vault payload schema)
  folders: [Folder],                    // each carries sync metadata
  entries: [Entry],                     // full entries incl. secrets
  tombstones: [Tombstone],
}

Tombstone {
  id: UUID,
  deleted_at: u64,                      // when the item was trashed, if ever
  purged_at: u64 | null,                // permanent removal marker
  version: VersionVector,
  kind: ItemKind,                       // Folder | Entry
}
```

All secrets are encrypted by the blob AEAD; the payload is never persisted in
plaintext and never crosses into Dart unencrypted.

---

## 5. Change model: version vectors

Wall-clock `updated_at` (Unix **seconds**) is for display and is too coarse to
decide causality. Each syncable item carries:

```
VersionVector = sorted [ (device_id: [u8;16], counter: u64) ]
SyncMeta {
  version: VersionVector,   // #[serde(default)] -> empty for pre-v5 items
  updated_by: [u8;16],      // zero for legacy items; set on first edit
}
```

- Every local mutation of an item increments the local device's component of
  its vector and sets `updated_by = device_id`.
- Compares: `A dominates B` iff every component of `A` ≥ `B` and at least one
  is greater. `A == B` means "no change". If neither dominates, the edits are
  **concurrent**.
- A delete is an edit that also sets `deleted_at`; it carries a vector, so
  "edit vs delete" is a normal concurrent case.
- A purge is a tombstone with its own vector; it propagates and wins over any
  live item with a dominated vector, preventing a purged entry from reappearing.

Legacy (v1–v4) items have an empty vector. On first local edit they adopt
`{ local_device: 1 }`; on merge with a remote empty-vector item, the two are
treated as concurrent only if their content differs (compared byte-for-byte on
the canonical payload), otherwise the remote is adopted as identical.

**Instrumentation point for implementation.** Today `Entry.updated_at` is set
by `Entry::new`, `Vault::update_entry`, `delete_entry`, `restore_entry` and
passkey use, but **not** by `Vault::move_entries`, folder rename/reorder, or
`delete_folder`, and there is no revision counter at all (the Dart
`vaultRevisionProvider` is an in-memory UI counter only). Every mutation path
that changes syncable state must bump the item's version vector in the same
call, including folder operations, moves and passkey `sign_count` updates.
`Vault::purge_entry`, `purge_expired` and folder deletion must emit a purge
tombstone (retained longer than the 30-day trash) while sync is enabled instead
of silently hard-removing data, so a remote copy cannot resurrect it.
`backup::read_encrypted` currently skips `vault::migrate`; a sync restore of an
older backup must migrate before merging.

---

## 6. Merge algorithm

Inputs: local `Vault` plus decrypted `SyncPayload`s from every remote device
file. Output: a merged `Vault`, a list of conflict copies, and a report.

For each id present in any input, compute the **winner** from the version
vectors:

| Case | Result |
|---|---|
| Only local | Keep local. |
| Only remote(s) | Adopt the dominant remote. |
| Local dominates all | Keep local. |
| One remote dominates local + others | Adopt it. |
| Concurrent edits (neither dominates) | Keep local under the original id; write each other distinct version as a **conflict copy** with a fresh UUID v7 and title `Original (conflict <date>)`. |
| Edit vs delete | Treat as concurrent: keep the edited version as a conflict copy; the delete (tombstone) wins for the original id. |
| Purge tombstone dominates | Drop the item entirely. |
| Identical vectors + identical payload | No-op (idempotent). |

Folders use the same algorithm with LWW on `(version, device_id)` for the
`order` field; a conflicting rename produces a second folder with a suffix.

**Idempotency is a hard requirement:** running sync twice with no intervening
edits must produce zero new conflict copies and leave the merged payload
byte-identical.

Conflict copies are ordinary entries the user can inspect, merge manually and
delete. Their UUIDs are new, so they never collide on later syncs.

### 6.1 Report (non-secret)

```
SyncReport {
  pulled_files, pushed_file, entries_added, entries_updated,
  conflicts_created, tombstones_applied, errors: [SyncError],
  started_at, finished_at,
}
```

No secret material in the report; safe for diagnostics.

---

## 7. Vault payload changes (schema v5)

Additive, `#[serde(default)]`, so v1–v4 payloads read unchanged:

```
Vault {
  schema_version: u16,                       // 5
  ...
  sync_config: Option<SyncConfig>,           // None = sync disabled
  tombstones: Vec<Tombstone>,                // #[serde(default)]
}

SyncConfig {
  enabled: bool,
  sync_id: [u8;16],
  device_id: [u8;16],
  sync_key: [u8;32],                         // SECRET: zeroized, never in DTOs
  folder_hint: String,                       // non-secret, informational
  last_sync_at: u64,
}

Entry / Folder {
  ...
  sync_meta: SyncMeta,                       // #[serde(default)]
}
```

Migration v4→v5 is a documented no-op per step (serde defaults supply the
values). `Entry::zeroize_secrets` must also wipe `sync_config.sync_key`.
`EntrySummary` and every DTO **exclude** `sync_config`, `sync_meta` and
tombstones (metadata only, no secrets either way). Encrypted backups round-trip
sync config; CSV export/import ignores it.

Device id generation: on first enable, `device_id = UUID v7` and is stored in
`sync_config`. If a device loses its vault and re-pairs, it gets a new
`device_id`; the old file in the folder is simply ignored once its vector no
longer participates.

---

## 8. API / session boundary (Rust → FRB → Dart)

All sync APIs live in Rust; the key never crosses the bridge.

```rust
// rust/src/api/sync.rs  (FRB-exposed, async where I/O is involved)
pub fn sync_status() -> SyncStatusDto;            // non-secret
pub fn sync_enable_pairing_code() -> Result<String>;  // returns code once
pub fn sync_join(code: String) -> Result<SyncStatusDto>;
pub fn sync_disable() -> Result<()>;              // local only; leaves remote bytes
pub fn sync_now(folder_path: String) -> Result<SyncReportDto>;
// "restore on new device" is sync_join + sync_now with explicit confirmation
```

Session rules:
- `sync_now` requires an unlocked session; it operates on the in-memory vault
  and saves through the existing atomic session save path.
- Pairing/join require unlock (the code/key is stored in the vault).
- If any remote blob fails authentication, `sync_now` aborts with a report;
  local state is untouched (no partial application).

Dart layer (`lib/features/sync/**`): settings page with enable/disable, folder
picker, pairing-code display/scan, status last-sync/errors, manual "Sync now"
and a first-run restore confirmation. UI never receives keys or plaintext
payloads. `INTERNET` permission is not used.

---

## 9. Security analysis

- **Backend is untrusted.** It sees only ciphertext plus `sync_id`,
  `writer_device_id`, `sequence`, file size and modification time. No vault
  key, master password, recovery key, sync key or plaintext.
- **Pairing code is the root secret.** Treat like the recovery key: one-time
  display, no logs, no screenshots, explicit user custody. A leaked code
  compromises the sync group; rotation is a new group (§3.3).
- **Replay / rollback.** `sequence` and version vectors are inside the
  authenticated AAD/payload. An attacker can copy an *older* valid blob back
  over a device file (the sync tool may do this after a conflict). The merge
  compares vectors, so an old blob cannot make an item regress — it is simply
  dominated by the newer state. Per-file monotonic `sequence` is exposed in
  status to flag stale files.
- **Tampering** with header or ciphertext fails AEAD authentication and is
  reported as `Corrupted`/`AuthenticationFailed`; no partial merge.
- **Secret hygiene.** `sync_key` is a `Zeroizing` value in Rust, never in
  `EntrySummary`/DTOs/search/index/diagnostics/logs; zeroized on drop/lock.
- **Lock state.** Sync is unavailable while locked; a locked device cannot
  leak the sync key or plaintext to the backend.

Residual risks: an attacker who obtains both a device file and the pairing code
can read that device's synced vault (equivalent to vault-file theft plus
recovery key). The attacker cannot forge updates without the sync key.

---

## 10. Testing plan

- **Envelope:** round trip, wrong key, tampered magic/version/sync_id/device/
  sequence/ciphertext, truncated and oversized blobs, no panics.
- **Pairing:** encode/decode round trip, typo detection, case/whitespace
  normalization like recovery keys, malformed input.
- **Merge matrix:** local-only, remote-only, local dominates, remote dominates,
  concurrent edits (two and three devices), edit vs delete, delete vs delete,
  purge propagation, folder order/rename, identical-state idempotency.
- **Failure/retry:** corrupt remote file aborts with no local change; retry
  after fixing the file converges; interrupted atomic write leaves `.tmp`/`.bak`
  handled.
- **Migration:** v1–v4 vaults open and write v5; sync config survives encrypted
  backup round trip; CSV ignores it.
- **Property tests:** arbitrary blob bytes never panic; merge is commutative
  and idempotent for arbitrary version vectors.

---

## 11. Implementation order

1. Schema v5 + change metadata (core, migration, zeroize, tests).
2. Sync envelope + pairing codec (core, tests).
3. Version-vector merge engine (core, exhaustive tests).
4. `FolderBackend` + atomic I/O (core, tests).
5. Session methods + FRB APIs + regenerated bindings.
6. Flutter settings/restore UI, capability/status, manual sync.
7. Threat-model review, docs, changelog, full verification.

---

## 12. Implementation resolutions / deferred items

- **Conflict-copy naming:** `Original (conflict YYYY-MM-DD)` in UTC, original id
  kept for the local winner, fresh UUID v7 for each copy; copies are ordinary
  entries (no dedicated conflict folder in 1.5.0).
- **Tombstone retention:** 90 days (`TOMBSTONE_RETENTION_SECS`), longer than the
  30-day trash; purged tombstones older than that are dropped.
- **Version-vector pruning:** not implemented in 1.5.0; vectors are small and a
  device revocation means creating a new sync group (§3.3). Revisit if groups
  accumulate many devices.
- **Folder path / QR:** Dart uses `file_picker.getDirectoryPath()` (or an app-
  support fallback); no native document-tree URI handling and no camera/QR scan
  in 1.5.0 — the pairing code is copied/entered as text. A QR scanner would add a
  camera permission flow and is deferred.
- **Key rotation:** deferred to after 1.6.0; rotating in place requires
  re-encrypting every device blob and a cutover marker.
- **Stale per-device file:** the local blob `sequence` is exposed in status; a
  replayed/older valid blob is dominated by the merge and cannot regress state.
  A dedicated warning badge is deferred.
