# 2.0.0 — Sync merge reliability and dependable same-Wi-Fi discovery

Major release requested after reports that paired devices did not merge logins
and that same-Wi-Fi peers were not being found. **No vault schema change**, no
Keyel account/server, no bundled secrets, no new broad permission, no manual
tags, and no change to the `KYSYNC1-…` trust root.

## Why

1. A successful folder sync changes Rust state behind the UI's back. Without an
   explicit view refresh, freshly merged logins stayed invisible until the vault
   was reloaded by locking/unlocking or restarting.
2. A disabled-but-present sync config looked off in the UI but still blocked
   Create group/Join group.
3. Discovery originally required two devices to run a short scan in the same
   window. There was no persistent, secret-free announcement, so peers were
   often invisible even on the same Wi-Fi.

## Todo

- [x] Refresh folders, health and vault-list revision after every successful
      `Sync now`; add a widget regression test.
- [x] Add a Rust regression test proving two paired vaults merge distinct login
      entries and both passwords through a shared folder.
- [x] Allow a disabled leftover sync config to be replaced, zeroizing its old
      key; keep active groups protected.
- [x] Send a bounded, outbound-only UDP beacon while the vault is unlocked and
      the app is foregrounded. Stop it on lock, background and disposal.
- [x] Repeat probes during a Find nearby pass, accept normal private LAN ranges,
      and keep strict non-secret payload validation.
- [x] Clarify EN/FR copy that pairing does not transfer data; both devices must
      use the same synced folder and tap `Sync now` on each one.
- [x] Bump version/changelog and run the full gate with Flutter 3.47.9.
- [ ] Cut release from CI; do not push tags by hand.

## Trust model

- Same-Wi-Fi/LAN reachability is a convenience, not authentication.
- Discovery sends only a short-lived opaque id and a sanitized display name.
- No `sync_id`, `sync_key`, `KYSYNC1-…`, pairing code, vault payload or secret is
  broadcast, logged or accepted by discovery.
- Selecting a nearby peer never supplies or replaces the pairing code. Manual
  entry always works, including when local-network access is unavailable.
- Sync blobs still move only through the user-chosen folder/sync tool; Keyel
  opens no sync server, account or LAN transport.

## Known limitations

- Discovery remains best-effort UDP. Platforms that gate local-network access
  behind a separate permission may show no peers; the manual code path is
  unchanged and authoritative.
- Foreground-only sync and presence still require an unlocked vault.
