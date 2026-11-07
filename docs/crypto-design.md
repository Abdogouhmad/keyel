# Keyel vault format (`vault.keyel`), version 1

Status: implemented in `crates/keyel_core` for phase 0.2.0. This document is
the normative description of the bytes on disk. It is intentionally boring:
standard primitives, explicit lengths, no custom cryptography.

## 1. Goals

- One file holds the whole vault.
- A master password and a one-time recovery key both unlock the same random
  vault key.
- Changing the master password must not rewrite the encrypted vault body.
- A malformed or tampered file must fail closed, without revealing which step
  failed.
- The parser must be safe to expose to untrusted bytes (fuzzed, no panics).

Non-goals for v1: incremental writes, multiple vaults per file, key rotation
of the vault key itself, sync metadata.

## 2. Primitives

| Purpose | Primitive |
|---|---|
| Password KDF | Argon2id v0x13 (`argon2` crate) |
| Recovery KDF | HKDF-SHA256 (`hkdf` + `sha2`) |
| Body and key wrapping | XChaCha20-Poly1305 (`chacha20poly1305`) |
| Randomness | OS CSPRNG (`rand::rngs::OsRng`) |
| Encoding | CBOR (`ciborium`) for the header; opaque bytes for the body |
| Secret wiping | `zeroize::Zeroizing` |

The vault key is 32 random bytes. It never leaves Rust and is never sent to
Dart.

## 3. File layout

All integers are little-endian. `u16` and `u32` are fixed-width.

```text
offset  size       field
0       4          magic = "KYL1" (0x4B 0x59 0x4C 0x31)
4       2          format_version = 1
6       4          header_len (u32)
10      header_len header (CBOR, canonical encoding)
...     24         body_nonce (XChaCha20 nonce)
...     n          body_ciphertext (n includes the 16-byte Poly1305 tag)
```

Constraints:

- `header_len` is 1..=65,536 bytes.
- The file must contain at least 24 + 16 bytes after the header.
- The header may contain 1..=4 keyslots.
- At most one `master` slot and one `recovery` slot; a `master` slot is
  required.
- `format_version` in the file must equal the `format_version` inside the
  header.

## 4. Header

```text
Header {
  format_version: u16,          // 1
  vault_id: [u8; 16],           // stable random identifier
  slots: [Keyslot],
}

Keyslot {
  kind: "master" | "recovery",
  kdf: Argon2id { m_kib: u32, t: u32, p: u32, salt: [u8; 16] }
     | HkdfSha256 { salt: [u8; 16] },
  nonce: [u8; 24],
  wrapped_key: [u8; 48],        // 32-byte vault key + 16-byte tag
}
```

The header is CBOR. Serde encodes fixed arrays as CBOR arrays of unsigned
integers (not byte strings); this is an implementation detail, but readers
should accept exactly the canonical encoding this implementation produces.

**Canonical-encoding check.** After decoding, the reader re-serializes the
header and requires the result to equal the stored header bytes. This closes
CBOR aliases where a changed length marker still deserializes to the same
struct (for example, changing an array marker from 16 to 17). It also rejects
unknown fields and non-canonical map orderings. A reader that accepts a header
without this check is not compatible with this format.

The header contains no secrets: only salts, nonces and ciphertexts.

## 5. Key hierarchy and keyslots

```text
master password ──Argon2id(salt, params)──> master KEK ──┐
                                                         ├── wraps vault_key
recovery key ─────HKDF-SHA256(salt, label)─> recovery KEK┘
```

Each keyslot is an independent AEAD blob:

```text
wrapped_key = XChaCha20-Poly1305(
    key = KEK,
    nonce = keyslot.nonce,
    plaintext = vault_key,
    aad = slot_aad(kind, kdf),
)
```

`slot_aad` is the byte string:

```text
"KYL1-SLOT" || 0x01
|| kind            // 0x01 master, 0x02 recovery
|| kdf_tag         // 0x01 argon2id, 0x02 hkdf_sha256
|| (argon2id: m_kib LE u32 || t LE u32 || p LE u32 || salt[16])
|| (hkdf:     salt[16])
```

The AAD binds a wrapped key to its slot type and KDF parameters, so a slot
cannot be moved to another kind or have its cost parameters edited without
failing authentication. Slots are independent: tampering with the recovery
slot is detected when the recovery key is used, and does not prevent a master
unlock (and vice versa).

## 6. Body

```text
body_aad = "KYL1" || format_version LE u16 || vault_id[16]
body_ciphertext = XChaCha20-Poly1305(
    key = vault_key,
    nonce = body_nonce,
    plaintext = vault payload (CBOR in phase 0.3+),
    aad = body_aad,
)
```

The body AAD deliberately excludes the keyslots. This is what makes
`change_master` cheap: only the master keyslot changes, while the body
ciphertext and tag stay byte-for-byte identical. The `vault_id` binds the body
to this header, so an attacker cannot swap headers between vaults or modify
the identifier. `format_version` prevents downgrade confusion.

Consequence: deleting or modifying the recovery keyslot is not detectable
during a master unlock. It is detectable during a recovery unlock, and it
cannot yield a different vault key because the wrapped key is authenticated.
This is the same tradeoff as other multi-keyslot vault formats.

## 7. KDF parameters

### Master slot: Argon2id

- Algorithm: Argon2id, version `0x13`.
- Output: 32 bytes.
- Defaults: `m = 65,536 KiB` (64 MiB), `t = 3`, `p = 1`.
- Accepted bounds from an untrusted header:
  - `m_kib`: 8 ..= 262,144 (256 MiB)
  - `t`: 1 ..= 16
  - `p`: 1 ..= 16
  - `m_kib >= 8 * p` (Argon2 requirement)
- A salt is 16 random bytes per slot.

The upper bounds prevent a tampered header from forcing an unbounded memory
or CPU allocation. Phase 0.6 will benchmark the real device and store tuned
parameters in a new vault's header. `kdf::calibrate(target, max_m_kib)`
doubles the memory cost until the measured derivation reaches the target; it
is intended to run once during setup, not on every unlock.

### Recovery slot: HKDF-SHA256

The recovery key is already 256 bits of uniform random data, so a
memory-hard KDF adds no security. Use:

```text
recovery_kek = HKDF-SHA256(
    ikm = recovery_key[32],
    salt = keyslot.salt[16],
    info = "keyel/recovery-kek/v1",
    length = 32,
)
```

## 8. Recovery key encoding

- 32 random bytes (256 bits).
- RFC 4648 base32, uppercase, no padding: 52 characters.
- Displayed in 13 groups of 4 separated by hyphens:
  `ABCD-EFGH-IJKL-MNOP-QRST-UVWX-YZ23-4567-ABCD-EFGH-IJKL-MNOP-QRST`.
- Parsing ignores case, whitespace, hyphens, `=` padding and other
  non-alphanumeric characters.
- For tolerance, `0` is read as `O` and `1` as `I`. All other characters
  must be in the base32 alphabet (`A-Z`, `2-7`).

There is no checksum in v1. A mistyped key fails AEAD authentication and is
reported as a wrong recovery key.

## 9. Flows

### Create

1. Generate `vault_key[32]`, `vault_id[16]`, master salt and recovery salt.
2. `master_kek = Argon2id(master, master_salt, params)`.
3. Wrap `vault_key` into the master slot (AAD = master slot metadata).
4. Generate a recovery key, `recovery_kek = HKDF(recovery_key, recovery_salt)`.
5. Wrap `vault_key` into the recovery slot.
6. Serialize the header, encrypt the body with `body_aad`, write the file.
7. Return the recovery key once. It is never stored in the header.

### Unlock with master

1. Parse the file and validate the canonical header.
2. Read the master slot's Argon2 parameters and salt.
3. Derive the master KEK and unwrap `vault_key`.
4. Decrypt the body with `body_aad`.
5. Keep `vault_key` and the decrypted payload in Rust.

### Unlock with recovery

Same, but parse the recovery string, use the recovery slot's HKDF salt, and
derive the recovery KEK.

### Change master password

1. Parse and validate the file.
2. Unwrap `vault_key` with the old master password.
3. Generate a new salt and derive a new master KEK with the new password.
4. Wrap `vault_key` into a replacement master slot. Leave other slots intact.
5. Re-serialize the header and concatenate it with the original body bytes.

The body ciphertext and tag are unchanged. Tests assert this byte-for-byte.

## 10. Errors

- `WrongPassword`: any AEAD authentication failure, including a wrong
  password, a tampered wrapped key, a tampered body, or a modified AAD.
- `Corrupted`: structural failure (magic, lengths, CBOR, canonical encoding,
  keyslot shape, missing master slot, ...).
- `UnsupportedVersion`: the file or header declares a version this build does
  not know.
- `InvalidKdfParams`: Argon2 parameters outside the accepted bounds.
- `InvalidRecoveryKey`: malformed recovery-key text.
- `Crypto`: an internal crypto operation failed unexpectedly.

Authentication failures are deliberately collapsed into `WrongPassword` so
callers do not learn which check failed.

## 11. Versioning and migration

`format_version` is 1. A reader must reject any other version rather than
guessing. Version 2 may add fields; migration will be implemented in
`format::migrate` when the first incompatible change lands. The body payload
has its own version in phase 0.3, so header and payload versions can evolve
independently.

## 12. Test coverage

In `crates/keyel_core`:

- AEAD round trip, wrong key, tampered ciphertext, tampered AAD, fresh nonces.
- Argon2 determinism, salt/password separation, invalid parameter bounds.
- Recovery-key round trip, normalization, invalid length/alphabet, HKDF salt
  separation.
- Create/unlock with master and recovery; wrong credentials.
- Every single-byte flip in a vault file is caught by at least one unlock
  path (master or recovery).
- Two encryptions of the same payload differ.
- `change_master` leaves the body bytes identical, invalidates the old
  password, and keeps recovery working.
- Empty, truncated, garbage and multi-megabyte payloads; no panics.
- Property tests: arbitrary plaintext round trips; arbitrary file bytes never
  panic.
- `fuzz/fuzz_targets/parse_vault.rs`: feeds arbitrary bytes to the parser and
  AEAD opener with a fixed vault key (so fuzzing does not run Argon2).

## 13. What this phase does not do

Atomic file writes, `.bak` fallback, vault model serialization, session
locking, and Dart/FRB exposure are phase 0.3/0.4 work. This phase only defines
and tests the bytes and the key hierarchy.
