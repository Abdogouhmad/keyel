import 'package:flutter/material.dart';

import 'package:keyel/ui/theme/keyel_theme.dart';

/// Wraps a surface in the Keyel "rubber" pressed state.
///
/// Material 3 Expressive presses scale the container down slightly instead of
/// darkening it (docs/design.md §Elevation, Micro-tactility).
class PressableScale extends StatefulWidget {
  /// Creates a pressable surface.
  const new({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.scale = KeyelMotion.pressedScale,
    this.semanticLabel,
    super.key,
  });

  /// Content that receives the tactile press.
  final Widget child;

  /// Tap handler; when null the surface is inert.
  final VoidCallback? onTap;

  /// Optional long-press handler.
  final VoidCallback? onLongPress;

  /// Clips the touch surface when supplied.
  final BorderRadius? borderRadius;

  /// Pressed scale, defaults to [KeyelMotion.pressedScale].
  final double scale;

  /// Optional accessibility label.
  final String? semanticLabel;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    // When the platform asks for reduced motion the press snaps instead of
    // scaling: the duration collapses to zero and the scale is skipped
    // entirely, so nothing moves (roadmap 0.11, accessibility).
    final duration = KeyelMotion.resolve(context, KeyelMotion.fast);
    final animate = duration > Duration.zero;

    return Semantics(
      button: _enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onLongPressEnd: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed && animate ? widget.scale : 1,
          duration: duration,
          curve: KeyelMotion.spring,
          child: ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
