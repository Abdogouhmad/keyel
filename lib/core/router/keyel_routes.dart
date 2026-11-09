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

  /// Folder management.
  static const folders = '/folders';

  /// Soft-deleted entries.
  static const trash = '/trash';

  /// First-run vault creation.
  static const onboarding = '/onboarding';

  /// Vault unlock.
  static const unlock = '/unlock';

  /// Temporary 0.4.0 bridge/session debug screen.
  static const debug = '/debug';

  /// Entry detail and editor root.
  static const entryRoot = '/entry';

  /// Create a brand-new entry.
  static const newEntry = '$entryRoot/new';

  /// Detail screen for an entry id.
  static String entryDetail(String id) => '$entryRoot/$id';

  /// Editor for an existing entry id.
  static String entryEdit(String id) => '$entryRoot/$id/edit';
}
