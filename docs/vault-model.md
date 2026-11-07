# Keyel vault model and storage (payload schema v1)

Status: implemented in `crates/keyel_core` for phase 0.3.0. This document
describes the decrypted payload and the storage rules. The encrypted file
layout and key hierarchy are specified separately in
[`crypto-design.md`](crypto-design.md).

## 1. Payload

The encrypted body of `vault.keyel` contains CBOR:

```text
Vault {
  schema_version: u16,        // 1
  folders: [Folder],
  entries: [Entry],
}

Folder {
  id: UUID,                   // v7, time ordered
  name: string,
  order: u32,
}

Entry {
  id: UUID,                   // v7
  title: string,
  notes: string,              // secret
  tags: [string],
  folder_id: UUID | null,
  favorite: bool,
  created_at: u64,            // Unix seconds
  updated_at: u64,
  deleted_at: u64 | null,     // trash marker
  body: EntryBody,
}

EntryBody =
  | { login: Login }
  | { card: Card }
  | { note: Note }

Login {
  username: string,
  password: string,           // secret
  url: string,
  totp: TotpConfig | null,
  password_history: [PasswordHistoryEntry],
}

TotpConfig {
  secret: string,             // secret, base32
  algorithm: "sha1" | "sha256" | "sha512",
  digits: u8,                 // normally 6
  period: u32,                // normally 30
}

PasswordHistoryEntry {
  password: string,           // secret
  changed_at: u64,
}

Card {
  cardholder: string,
  number: string,             // secret
  expiry: string,
  cvv: string,                // secret
  brand: string | null,
}

Note {
  content: string,            // secret
}
```

The payload is encrypted with the vault key. It is only ever decoded in Rust;
the vault key and the decoded payload are never sent to Dart.

## 2. Identification and time

- New ids use UUID v7, so they sort by creation time.
- Timestamps are Unix seconds (`u64`). There are no timezone or formatting
  concerns in the core; the UI formats them.
- `schema_version` lives in the payload, independent of the file
  `format_version`. See §7.

## 3. Trash lifecycle

- `delete_entry` sets `deleted_at` (soft delete). Deleting an already-deleted
  entry keeps the first deletion time.
- `restore_entry` clears `deleted_at`.
- `purge_entry` removes an entry permanently.
- `purge_expired(now)` removes entries whose `deleted_at` is at least 30 days
  old. `Session::open` calls it immediately after unlock, so expired trash is
  cleaned without a separate background job. The cleanup is persisted on the
  next `save`.

Searches hide deleted entries by default; `EntryFilter::include_deleted`
includes them (needed for the trash screen).

## 4. Search

`vault::search(vault, query, filter)` returns `EntrySummary` values (see §5).

- Matching is linear over entry metadata. Vaults are small enough that an
  extra index would only add a second source of truth.
- Text is normalized with NFD, combining marks are removed, and the result is
  lowercased. `"Café"`, `"cafe"` and `"CAFÉ"` match.
- Searched fields: title, tags, login username, login URL, cardholder and
  card brand.
- Never searched: passwords, notes, card numbers, CVVs, TOTP secrets and
  history. This prevents a search from turning into a secret oracle.
- Filters: kind, folder, favorite, has-TOTP, include-deleted.
- Results are sorted by normalized title, then id.

## 5. Secret-free summaries

List screens only use `EntrySummary`:

```text
EntrySummary {
  id, kind, title, subtitle, favorite, folder_id, has_totp
}
```

`subtitle` is metadata only: login username or URL, card brand or cardholder,
or the literal `"Note"`. It never contains a password, note body or card
number.

## 6. Password history

When `Vault::update_entry` sees a login whose password changed, the previous
password is pushed onto `password_history` (newest first) and the list is
capped at 10 entries. The cap is `history::PASSWORD_HISTORY_CAP`.

## 7. Migration

`vault::migrate(vault, from_version)` upgrades the payload schema. Version 1 is
the current schema, so the only supported migration today is 1 → 1. Unknown
or future versions return `Error::UnsupportedVersion` and fail closed. A new
incompatible payload change adds one arm/step per version.

## 8. Storage and atomic saves

A `Session` owns the vault key, the authenticated file header and the decoded
`Vault`.

`Session::save` writes:

```text
vault.keyel.tmp   new ciphertext, fsync'ed
vault.keyel.bak   copy of the previous main file (if one exists)
vault.keyel       rename(tmp) over the old file, parent dir fsync'ed best-effort
```

Properties:

- A crash before the rename leaves the previous `vault.keyel` intact; a stale
  `.tmp` is ignored and overwritten by the next save.
- `rename` is atomic on the same filesystem, so a reader never sees a partly
  written main file.
- One previous version is kept in `.bak`.

### Recovery from `.bak`

`Session::open` falls back to `.bak` only when the main file fails
structurally: bad magic, truncation, invalid/canonical header, unsupported
version, or an undecodable payload. An AEAD failure (reported as
`WrongPassword`) is **not** retried against the backup.

The reason is that a backup can be older than a master-password change and may
therefore still be protected by the old password. Automatically opening it
would silently make the old password valid again. Structural failures cannot
be caused by a wrong password, so the fallback is safe there.

## 9. Memory hygiene

- The vault key and KEKs are `Zeroizing` and wipe on drop.
- The plaintext CBOR buffers used by create/save are wrapped in `Zeroizing`.
- `Vault` wipes secret fields (passwords, history, TOTP secrets, card numbers,
  CVVs, notes) when it is dropped, and when an entry is replaced, purged or
  expired. This is best-effort: `String` clones made by callers are outside
  the core's control, which is why the bridge will expose summaries only.

## 10. Tests

`crates/keyel_core` covers:

- 1,000 entries: create, save, lock, reopen, search, byte-identical data.
- Recovery-key open on a saved vault.
- Atomic save, `.bak` contents and structural-corruption fallback.
- Stale `.tmp` after a simulated crash.
- Trash delete/restore and 30-day purge on unlock.
- Folders, reordering, folder deletion moving entries to "No folder".
- Password history and its 10-entry cap.
- Serialization round-trip (unit and proptest).
- Migration 1 → 1 and rejection of unknown versions.
