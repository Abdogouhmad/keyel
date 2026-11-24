import 'package:flutter/widgets.dart';

/// Material window size classes (docs/design.md §7).
enum WindowSizeClass {
  /// Under 600 dp: phones.
  compact,

  /// 600-839 dp: foldables, small tablets.
  medium,

  /// 840-1199 dp: tablets.
  expanded,

  /// 1200 dp and up.
  large;

  /// Maps a width in dp to its class.
  static WindowSizeClass fromWidth(double width) {
    if (width < 600) return compact;
    if (width < 840) return medium;
    if (width < 1200) return expanded;
    return large;
  }

  /// The class of the physical window.
  ///
  /// Navigation chrome deliberately uses this: the shell must pick its own
  /// rail/drawer before a content scope exists. Layout decisions inside pages
  /// must use [ofEffective] instead, because a 1200 dp window with a 280 dp
  /// drawer only gives its content ~850 dp to work with.
  static WindowSizeClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  /// The class of the space actually available to page content.
  static WindowSizeClass ofEffective(BuildContext context) =>
      fromWidth(effectiveWidthOf(context));

  /// Whether this is the phone layout.
  bool get isCompact => this == compact;

  /// Whether two-pane list-detail layouts fit in this window.
  bool get supportsListDetail => this == expanded || this == large;
}

/// Horizontal space consumed by the shell's navigation chrome.
@immutable
class LayoutChrome {
  /// Creates a chrome description; zero by default (phone bottom nav).
  const new({this.width = 0});

  /// Width taken away from the content area by a rail or drawer.
  final double width;

  @override
  bool operator ==(Object other) =>
      other is LayoutChrome && other.width == width;

  @override
  int get hashCode => width.hashCode;
}

/// The space available to a page after chrome, margins and text scaling.
@immutable
class EffectiveLayoutData {
  /// Creates an effective layout description.
  const new({
    required this.windowWidth,
    required this.chromeWidth,
    required this.pageMargin,
    required this.textScale,
  });

  /// Full window width in dp.
  final double windowWidth;

  /// Width of the navigation rail or drawer beside the content.
  final double chromeWidth;

  /// One page margin (there are two, start and end).
  final double pageMargin;

  /// The user's accessibility text scale.
  final double textScale;

  /// Width left for the page after chrome and both page margins.
  double get contentWidth =>
      (windowWidth - chromeWidth - 2 * pageMargin).clamp(240.0, windowWidth);

  /// Layout capacity expressed in "1x dp".
  ///
  /// Dividing by the text scale makes layout decisions collapse to one column
  /// when text grows: a 200 % label needs roughly twice the room.
  double get capacity => contentWidth / textScale.clamp(1.0, 2.0);

  /// Effective width used by all page-level layout decisions.
  double get width => capacity;

  /// Whether two content columns can comfortably fit.
  bool get supportsTwoColumns => capacity >= 900;

  /// Whether a list/detail composition can comfortably fit.
  bool get supportsListDetail =>
      WindowSizeClass.fromWidth(capacity).supportsListDetail;

  @override
  bool operator ==(Object other) =>
      other is EffectiveLayoutData &&
      other.windowWidth == windowWidth &&
      other.chromeWidth == chromeWidth &&
      other.pageMargin == pageMargin &&
      other.textScale == textScale;

  @override
  int get hashCode =>
      Object.hash(windowWidth, chromeWidth, pageMargin, textScale);
}

/// Declares the navigation chrome that surrounds [child].
///
/// The shell wraps every page with this so text fields, list panes and grids
/// make decisions from the space they can actually see. Without a scope,
/// [effectiveWidthOf] falls back to the raw window width, which keeps plain
/// widget tests independent of the shell.
class EffectiveLayoutScope extends StatelessWidget {
  /// Creates a scope for the given chrome width.
  const new({required this.chrome, required this.child, super.key});

  /// Navigation chrome around the content.
  final LayoutChrome chrome;

  /// The page content.
  final Widget child;

  /// Page margin for a raw window width, shared with the spacing extension.
  static double pageMarginFor(double windowWidth) =>
      WindowSizeClass.fromWidth(windowWidth) == WindowSizeClass.compact
      ? 16
      : WindowSizeClass.fromWidth(windowWidth) == WindowSizeClass.large
      ? 32
      : 24;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return _EffectiveLayout(
      data: EffectiveLayoutData(
        windowWidth: width,
        chromeWidth: chrome.width,
        pageMargin: pageMarginFor(width),
        textScale: MediaQuery.textScalerOf(context).scale(1),
      ),
      child: child,
    );
  }
}

class _EffectiveLayout extends InheritedWidget {
  const new({required this.data, required super.child});

  final EffectiveLayoutData data;

  @override
  bool updateShouldNotify(_EffectiveLayout oldWidget) => data != oldWidget.data;
}

/// The effective layout for [context], or `null` outside a shell scope.
EffectiveLayoutData? maybeEffectiveLayoutOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_EffectiveLayout>()?.data;

/// Width available to page content, after chrome, margins and text scaling.
double effectiveWidthOf(BuildContext context) =>
    maybeEffectiveLayoutOf(context)?.width ?? MediaQuery.sizeOf(context).width;

/// Convenience access to the window size class and effective width.
extension WindowSizeContext on BuildContext {
  /// The physical [WindowSizeClass] for the current window.
  WindowSizeClass get windowSize => WindowSizeClass.of(this);

  /// The effective layout for this page, when inside a shell scope.
  EffectiveLayoutData? get maybeEffectiveLayout => maybeEffectiveLayoutOf(this);

  /// Width available to this page after chrome, margins and text scaling.
  double get effectiveWidth => effectiveWidthOf(this);

  /// Whether two content columns fit at the current text scale.
  bool get supportsTwoColumns =>
      maybeEffectiveLayout?.supportsTwoColumns ?? false;

  /// The [WindowSizeClass] for the space available to page content.
  WindowSizeClass get effectiveWindowSize => WindowSizeClass.ofEffective(this);
}
