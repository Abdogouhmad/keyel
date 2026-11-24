/// Route paths and helpers shared by the router and every screen.
abstract final class KeyelRoutes {
  /// Home: the password list.
  static const vault = '/vault';

  /// Password and passphrase generator.
  static const generator = '/generator';

  /// Vault health dashboard.
  static const security = '/security';

  /// App settings.
  static const settings = '/settings';

  /// Appearance and personalization settings.
  static const appearance = '/settings/appearance';

  /// Opt-in cross-device sync settings.
  static const sync = '/settings/sync';

  /// Opt-in Wear OS TOTP seed transfer.
  static const watchCodes = '/settings/watch';

  /// Over-the-air software update screen.
  static const softwareUpdate = '/settings/update';

  /// Folder management.
  static const folders = '/folders';

  /// Soft-deleted entries.
  static const trash = '/trash';

  /// Encrypted backup, restore and CSV import/export.
  static const importExport = '/import-export';

  /// Autofill credential picker, launched by the Android autofill service.
  static const autofillPicker = '/autofill-picker';

  /// First-run vault creation.
  static const onboarding = '/onboarding';

  /// Vault unlock.
  static const unlock = '/unlock';

  /// Temporary 0.4.0 bridge/session debug screen.
  static const debug = '/debug';

  /// Entry detail and editor root (legacy pushed routes).
  static const entryRoot = '/entry';

  /// Create a brand-new entry.
  static const newEntry = '$entryRoot/new';

  /// Detail screen for an entry id.
  static String entryDetail(String id) => '$entryRoot/$id';

  /// Editor for an existing entry id.
  static String entryEdit(String id) => '$entryRoot/$id/edit';

  /// Canonical, shareable entry route inside the vault branch.
  static const vaultEntryRoot = '$vault/entry';

  /// Canonical route for one selected entry.
  ///
  /// On a wide window this renders the master/detail pair; on a phone it
  /// renders the full-screen detail. The URL, not local state, is the source
  /// of truth for which entry is selected.
  static String vaultEntryDetail(String id) => '$vaultEntryRoot/$id';

  /// Unlock route carrying the location the user originally requested.
  ///
  /// A locked deep link must survive the unlock guard and land on the entry,
  /// not on an empty vault.
  static String unlockFor(String location) =>
      '$unlock?from=${Uri.encodeQueryComponent(location)}';
}
