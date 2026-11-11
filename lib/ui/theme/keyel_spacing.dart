/// Canonical spacing tokens for the entire app.
///
/// Every `Padding`, `SizedBox`, and `EdgeInsets` value should use one of these
/// constants (or a simple multiple), never an arbitrary number chosen
/// per-screen. This is the single source of truth for spacing rhythm.
///
/// Canonical mapping (matches the ported Brewline `AppSpacing`):
///   xs = 4   (micro gaps, icon padding)
///   sm = 8   (inline spacing, tight groups)
///   md = 16  (content gaps, between cards)
///   lg = 24  (section padding, field gaps)
///   xl = 32  (screen-level horizontal padding)
///   x2l = 40 (loading states, hero spacing)
///   x3l = 48 (expansive empty states)
library;

/// App spacing for creating space between elements
class AppSpacing {
  /// new constructure
  const new();

  /// spacing xs
  static const double xs = 4;

  /// spacing sm
  static const double sm = 8;

  /// spacing md
  static const double md = 16;

  /// spacing lg
  static const double lg = 24;

  /// spacing xl
  static const double xl = 32;

  /// spacing x2l
  static const double x2l = 40;

  /// spacing x3l
  static const double x3l = 48;
}
