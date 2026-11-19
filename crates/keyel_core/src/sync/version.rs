//! Per-item version vectors for sync conflict detection.
//!
//! A version vector maps each device id to a logical counter. Comparing two
//! vectors tells us whether one edit causally follows the other, or whether
//! the edits were concurrent (and therefore need a conflict copy).
//!
//! Wall-clock `Entry.updated_at` is intentionally **not** used for causality:
//! it is measured in seconds, so same-second edits on two devices would tie.

use serde::{Deserialize, Serialize};

/// Stable identifier of a sync participant (a random UUID v7 stored in the
/// vault's sync config). Non-secret.
pub type DeviceId = [u8; 16];

/// Relationship between two version vectors.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum VectorOrder {
    /// Identical vectors (same state).
    Equal,
    /// `self` is strictly behind `other`.
    Before,
    /// `self` is strictly ahead of `other`.
    After,
    /// Neither dominates; the edits are concurrent and must be reconciled.
    Concurrent,
}

/// A sorted map of device id → logical counter.
///
/// The vector is kept normalized (sorted, unique devices, no zero counters) by
/// [`VersionVector::bump`]. Lookups use a linear scan so a vector decoded from
/// older or third-party data is handled correctly even if it was not sorted.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct VersionVector(Vec<(DeviceId, u64)>);

impl VersionVector {
    /// An empty vector, used for items created before schema v5.
    pub fn new() -> Self {
        Self(Vec::new())
    }

    /// Counter recorded for `device`, or `0` if the device has no entry.
    pub fn get(&self, device: &DeviceId) -> u64 {
        self.0
            .iter()
            .find(|(id, _)| id == device)
            .map(|(_, counter)| *counter)
            .unwrap_or(0)
    }

    /// Increment the local device's counter, recording a first edit if needed.
    pub fn bump(&mut self, device: &DeviceId) {
        let current = self.get(device);
        if let Some((_, counter)) = self.0.iter_mut().find(|(id, _)| id == device) {
            *counter = current.saturating_add(1);
        } else {
            self.0.push((*device, 1));
        }
        self.normalize();
    }

    /// Compare causal ordering. See [`VectorOrder`].
    pub fn compare(&self, other: &Self) -> VectorOrder {
        let mut self_ahead = false;
        let mut other_ahead = false;

        for (device, _) in &self.0 {
            if self.get(device) > other.get(device) {
                self_ahead = true;
            } else if self.get(device) < other.get(device) {
                other_ahead = true;
            }
        }
        for (device, _) in &other.0 {
            if other.get(device) > self.get(device) {
                other_ahead = true;
            } else if other.get(device) < self.get(device) {
                self_ahead = true;
            }
        }

        match (self_ahead, other_ahead) {
            (false, false) => VectorOrder::Equal,
            (true, false) => VectorOrder::After,
            (false, true) => VectorOrder::Before,
            (true, true) => VectorOrder::Concurrent,
        }
    }

    /// Whether this vector is the same as or causally after `other`.
    pub fn dominates(&self, other: &Self) -> bool {
        matches!(self.compare(other), VectorOrder::After | VectorOrder::Equal)
    }

    /// Join two vectors, keeping the maximum counter of each device.
    ///
    /// The result dominates both inputs and is used after a conflict has been
    /// resolved so a repeated sync cannot create the same conflict copy twice.
    pub fn join(&self, other: &Self) -> Self {
        let mut joined = self.clone();
        for (device, counter) in &other.0 {
            if *counter > joined.get(device) {
                if let Some((_, current)) = joined.0.iter_mut().find(|(id, _)| id == device) {
                    *current = *counter;
                } else {
                    joined.0.push((*device, *counter));
                }
            }
        }
        joined.normalize();
        joined
    }

    /// Whether no device has ever edited this item.
    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }

    /// Iterate over `(device, counter)` pairs in normalized order.
    pub fn iter(&self) -> impl Iterator<Item = &(DeviceId, u64)> {
        self.0.iter()
    }

    fn normalize(&mut self) {
        self.0.sort_by_key(|(device, _)| *device);
        let mut normalized: Vec<(DeviceId, u64)> = Vec::with_capacity(self.0.len());
        for (device, counter) in self.0.drain(..) {
            if counter == 0 {
                continue;
            }
            if let Some(last) = normalized.last_mut() {
                if last.0 == device {
                    last.1 = last.1.max(counter);
                    continue;
                }
            }
            normalized.push((device, counter));
        }
        self.0 = normalized;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn device(n: u8) -> DeviceId {
        let mut id = [0u8; 16];
        id[15] = n;
        id
    }

    #[test]
    fn empty_vectors_are_equal() {
        assert_eq!(
            VersionVector::new().compare(&VersionVector::default()),
            VectorOrder::Equal
        );
        assert!(VersionVector::new().is_empty());
    }

    #[test]
    fn bump_records_and_increments_the_local_device() {
        let a = device(1);
        let mut v = VersionVector::new();
        assert_eq!(v.get(&a), 0);
        v.bump(&a);
        assert_eq!(v.get(&a), 1);
        v.bump(&a);
        assert_eq!(v.get(&a), 2);
        assert!(!v.is_empty());
    }

    #[test]
    fn causally_later_vector_dominates() {
        let a = device(1);
        let mut earlier = VersionVector::new();
        earlier.bump(&a);
        let mut later = earlier.clone();
        later.bump(&a);
        assert_eq!(later.compare(&earlier), VectorOrder::After);
        assert_eq!(earlier.compare(&later), VectorOrder::Before);
        assert!(later.dominates(&earlier));
        assert!(!earlier.dominates(&later));
    }

    #[test]
    fn concurrent_edits_are_detected() {
        let a = device(1);
        let b = device(2);
        let mut from_a = VersionVector::new();
        from_a.bump(&a);
        let mut from_b = VersionVector::new();
        from_b.bump(&b);
        assert_eq!(from_a.compare(&from_b), VectorOrder::Concurrent);
        assert!(!from_a.dominates(&from_b));
        assert!(!from_b.dominates(&from_a));
    }

    #[test]
    fn merged_vector_dominates_both_parents() {
        let a = device(1);
        let b = device(2);
        let mut from_a = VersionVector::new();
        from_a.bump(&a);
        let mut from_b = VersionVector::new();
        from_b.bump(&b);
        // A vector that has observed both edits dominates each parent.
        let mut merged = from_a.clone();
        merged.bump(&b);
        assert!(merged.dominates(&from_a));
        assert!(merged.dominates(&from_b));
        assert_eq!(merged.get(&a), 1);
        assert_eq!(merged.get(&b), 1);
    }

    #[test]
    fn join_dominates_both_inputs() {
        let a = device(1);
        let b = device(2);
        let mut from_a = VersionVector::new();
        from_a.bump(&a);
        let mut from_b = VersionVector::new();
        from_b.bump(&b);
        from_b.bump(&b);

        let joined = from_a.join(&from_b);
        assert!(joined.dominates(&from_a));
        assert!(joined.dominates(&from_b));
        assert_eq!(joined.get(&a), 1);
        assert_eq!(joined.get(&b), 2);
    }

    #[test]
    fn normalize_keeps_maximum_for_duplicate_devices() {
        let a = device(1);
        let mut v = VersionVector(vec![(a, 1), (a, 5), (device(2), 0)]);
        v.normalize();
        assert_eq!(v.iter().count(), 1);
        assert_eq!(v.get(&a), 5);
    }

    #[test]
    fn cbor_round_trip_preserves_ordering() {
        let a = device(1);
        let b = device(2);
        let mut v = VersionVector::new();
        v.bump(&a);
        v.bump(&b);
        v.bump(&a);
        let mut bytes = Vec::new();
        ciborium::into_writer(&v, &mut bytes).unwrap();
        let decoded: VersionVector = ciborium::from_reader(bytes.as_slice()).unwrap();
        assert_eq!(decoded, v);
        assert_eq!(decoded.compare(&v), VectorOrder::Equal);
    }
}
