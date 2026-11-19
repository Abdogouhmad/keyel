# Keyel vault model and storage (payload schema v4)

Status: implemented in `crates/keyel_core`. This document describes the
decrypted payload and the storage rules. The encrypted file layout and key
hierarchy are specified separately in [`crypto-design.md`](crypto-design.md).

## 1. Payload

The encrypted body of `vault.keyel` contains CBOR:

```text
Vault {
  schema_version: u16,        // 4
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
  icon: string | null,        // v2: optional user-chosen icon slug
  custom_fields: [CustomField], // v3: ordered user-defined extra fields
  created_at: u64,            // Unix seconds
  updated_at: u64,
  deleted_at: u64 | null,     // trash marker
  body: EntryBody,
}

CustomField {
  id: UUID,                   // v7, stable for UI addressing/reveal
  label: string,
  value: string,              // secret when kind == "hidden"
  kind: "text" | "hidden" | "url",
}

EntryBody =
  | { login: Login }
  | { card: Card }
  | { note: Note }
  | { passkey: Passkey }

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

Passkey {
  rp_id: string,              // relying party identifier (e.g. example.com)
  rp_name: string,
  credential_id: bytes,       // credential identifier
  user_handle: bytes,         // secret-adjacent RP user handle (zeroized)
  user_name: string,
  user_display_name: string,
  public_key: bytes,          // COSE public key
  private_key: bytes,         // secret: signing key material (zeroized, never exposed)
  algorithm: i32,             // COSE algorithm id (e.g. -7 ES256, -257 RS256, -8 EdDSA)
  sign_count: u32,
  created_at: u64,            // Unix seconds
  last_used_at: u64 | null,   // Unix seconds
  transports: [string],       // hints (internal/usb/nfc/ble/hybrid)
  discoverable: bool,
}
```

The payload is encrypted with the vault key. It is only ever decoded in Rust;
the vault key and the decoded payload are never sent to Dart. `icon` and
`custom_fields` use `#[serde(default)]`, so payloads written before schema v2/v3
remain readable. Passkeys are a schema-v4 addition; existing v3 payloads contain
no passkey entries and migrate losslessly.

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
  lowercased, so matching is case- and accent-insensitive (`Café` = `cafe`).
- The query matches the title, tags, and kind-specific metadata: username and
  URL for logins, cardholder and brand for cards, relying-party and user name
  fields for passkeys, and non-secret custom field labels/values (`text`/`url`).
  Secret content (passwords, TOTP secrets, card number/CVV, note content,
  login/card notes, `hidden` custom field values, and passkey private key
  material) is never searched. `EntryFilter` narrows by kind, folder, favorite,
  and `has_totp`.

## 5. Summaries and secrets

Listing and search return `EntrySummary { id, kind, title, subtitle, icon,
folder_id, favorite, has_totp, deleted_at, updated_at, custom_fields }` only. The
subtitle is the username or URL for a login, the brand or cardholder for a
card, the user name/display name/RP for a passkey, and `"Note"` for a note.

Secrets live only inside `EntryBody` (and in `Entry.notes` / `hidden` custom
fields). Nothing above the Rust core receives the vault key or the body; the UI
obtains a secret only through an explicit reveal/copy/ceremony path. For
logins/cards/notes and custom fields this is via explicit reveal APIs; for
passkeys, **private key material is never exposed to Dart/UI/DTOs/diagnostics**
and may only be used inside Rust/session boundaries for WebAuthn ceremonies
(planned for 1.4.0).

`Entry::zeroize_secrets` overwrites passwords, TOTP secrets, password history,
card number/CVV, note content, `notes`, hidden custom field values, and passkey
`private_key`/`user_handle`. `password_history` is capped at the 10 most recent
entries.

## 6. Storage location and atomic writes

- The vault file is a single `vault.keyel` under the app's documents directory,
  resolved by path_provider in Dart and passed to Rust.
- Rust never hard-codes a path; every operation takes an explicit path.
- Every save is atomic (temp file, fsync, rename) and leaves a `.bak` of the
  previous file. A leftover `.tmp` is removed on the next open. The writer holds
  an advisory lock for the duration of the write so concurrent save attempts do
  not race.
- `allow_backup="false"` and `dataExtractionRules` exclude the vault from
  Android Auto Backup and device-to-device transfer.

## 7. Migration and compatibility

- The file header carries a `format_version` (envelope). The payload carries
  `schema_version` (this document). They evolve independently.
- Migrations are stepwise in `vault::migrate`: v1→v2 adds the optional `icon`,
  v2→v3 adds ordered `custom_fields`, v3→v4 adds the `passkey` kind/body. For
  these changes the serde defaults already yield the correct value, so migration
  is a documented, lossless no-op per step.
- Unknown/future schema versions fail closed with `UnsupportedVersion`. v1, v2,
  and v3 payloads are accepted and migrated forward on open; the next save writes
  the current schema version.

## 8. Import/export and interoperability notes

- **Encrypted backup:** payload-based and round-trips schema-v4 entries (including
  passkeys) subject to the encrypted backup format.
- **CSV export (plaintext):** passkeys are not representable in the supported
  Bitwarden/Chrome CSV formats and contain private key material that must not be
  exported in plaintext; they are therefore excluded from CSV export. Preserve
  passkeys via encrypted backups.
- **CSV import:** passkeys are not produced by the supported CSV formats.

## 9. First-run and locks

A first-run is "no `vault.keyel` exists at the path". There is no separate
manifest file. The session holds the decrypted vault in memory while unlocked
and drops it on lock.
