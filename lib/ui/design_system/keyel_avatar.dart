import 'package:flutter/material.dart';

/// Organic shape families used by vault avatars.
enum KeyelAvatarShape {
  /// Asymmetric "cookie" with two tight corners.
  cookie,

  /// Rounded squircle used by favicons and detail headers.
  squircle,

  /// Perfect circle.
  circle,
}

/// Tonal colour families used by vault avatars.
enum KeyelAvatarTone {
  /// Indigo on pale indigo.
  indigo,

  /// Plum on pale plum.
  plum,

  /// Indigo on secondary container.
  slate,

  /// Neutral surface on surface.
  neutral,
}

/// A playful tonal avatar that cradles a service glyph.
class KeyelAvatar extends StatelessWidget {
  /// Creates an avatar.
  const new({
    required this.icon,
    this.tone = KeyelAvatarTone.neutral,
    this.shape = KeyelAvatarShape.squircle,
    this.size = 48,
    super.key,
  });

  /// Glyph shown inside the avatar.
  final IconData icon;

  /// Colour family.
  final KeyelAvatarTone tone;

  /// Shape family.
  final KeyelAvatarShape shape;

  /// Outer square size in dp.
  final double size;

  BorderRadius get _radius => switch (shape) {
    KeyelAvatarShape.cookie => BorderRadius.only(
      topLeft: Radius.circular(size * 0.375),
      topRight: Radius.circular(size * 0.17),
      bottomRight: Radius.circular(size * 0.375),
      bottomLeft: Radius.circular(size * 0.17),
    ),
    KeyelAvatarShape.squircle => BorderRadius.circular(size * 0.33),
    KeyelAvatarShape.circle => BorderRadius.circular(size / 2),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (background, foreground) = switch (tone) {
      KeyelAvatarTone.indigo => (scheme.primaryFixed, scheme.onPrimaryFixed),
      KeyelAvatarTone.plum => (
        scheme.tertiaryFixed,
        scheme.onTertiaryFixedVariant,
      ),
      KeyelAvatarTone.slate => (scheme.secondaryContainer, scheme.primary),
      KeyelAvatarTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: _radius),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.5, color: foreground),
    );
  }
}
