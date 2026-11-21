import 'package:keyel/ui/l10n/l10n.dart';

/// Filter families available in the vault.
enum VaultFilter {
  /// Shows every saved entry.
  all,

  /// Shows login entries only.
  logins,

  /// Shows payment card entries only.
  cards,

  /// Shows secure note entries only.
  notes,

  /// Shows entries pinned to favorites.
  favorites,

  /// Shows entries that carry a two-factor secret.
  twoFactor;

  /// Label displayed on the filter chip.
  String get label => switch (this) {
    VaultFilter.all => currentL10n.vaultFilterAll,
    VaultFilter.logins => currentL10n.vaultFilterLogins,
    VaultFilter.cards => currentL10n.vaultFilterCards,
    VaultFilter.notes => currentL10n.vaultFilterNotes,
    VaultFilter.favorites => currentL10n.vaultFilterFavorites,
    VaultFilter.twoFactor => currentL10n.vaultFilterTwoFactor,
  };
}
