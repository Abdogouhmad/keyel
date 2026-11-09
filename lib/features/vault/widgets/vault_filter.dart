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
    VaultFilter.all => 'All',
    VaultFilter.logins => 'Logins',
    VaultFilter.cards => 'Cards',
    VaultFilter.notes => 'Notes',
    VaultFilter.favorites => 'Favorites',
    VaultFilter.twoFactor => '2FA',
  };
}
