# 1.13.1 — Portable desktop builds, storage hardening and same-Wi-Fi sync

Patch release requested after the 1.13.0 desktop rollout. No vault schema
change, no account/server, no new broad permission, no change to the pairing
secret.

## Why

1. A user's Linux AppImage failed immediately with
   `keyel: CPU ISA level is lower than required`. The CI-built 1.12.0/1.13.0
   Linux ELFs declared `x86-64-baseline, x86-64-v2, x86-64-v3`, even though
   local builds declared only the baseline. Newer runner images/toolchains must
   not decide which users can launch Keyel.
2. A storage audit found first-run/data-loss edges: backup-only vaults looked
   absent and could be overwritten by a new vault, vault files inherited the
   process umask, settings writes could interleave, and stale copies survived
   factory reset.
3. Sync room creation should use LocalSend-style same-Wi-Fi/local-network
   discovery as a convenience before the existing one-time code is confirmed.

## Todo

- [x] Pin x86-64 baseline codegen for the Linux runner and all desktop Rust
      targets; add `tool/check_cpu_baseline.sh` to release/AppImage/CI builds.
- [x] Verify a deliberately hostile `-march=x86-64-v3` build emits only
      `x86-64-baseline`.
- [x] Treat `vault.keyel.bak` as an existing vault everywhere; delete all
      copies on factory reset.
- [x] Force 0600 on new vault/backup files and tighten old backup permissions.
- [x] Serialize atomic `settings.json` writes and create a missing parent.
- [x] Keep the one-time recovery key even if optional biometric setup fails.
- [x] Migrate the newest legacy vault via temp+rename and carry `settings.json`
      forward.
- [x] Port LocalSend's same-Wi-Fi discovery to sync room creation: show peers,
      require explicit confirmation, keep `KYSYNC1-…` as the trust root, and
      fall back to manual entry when no peer is found.
- [ ] Bump version/changelog and run the full gate with Flutter 3.47.9.
- [ ] Cut release from CI; verify released Linux artifacts are baseline-only.

## Known limitations

- Discovery is a best-effort LAN convenience. It needs no new permission on
  desktop, and on Android it relies on local socket traffic permitted by the
  existing `INTERNET` permission. Platforms that gate local-network access
  behind a separate `ACCESS_LOCAL_NETWORK` permission may report no peers;
  Keyel does not request that permission in 1.13.1, and the manual pairing code
  remains fully functional.

## Non-goals

- No vault format change and no migration of encrypted contents.
- No central sync server, relay, account or automatic background sync.
- No broadcast of `sync_id`, `sync_key`, vault data or other secrets.
- No claim that same-Wi-Fi proximity authenticates a peer; it only narrows the
  manual pairing UX.
