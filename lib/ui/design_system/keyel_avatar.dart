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

/// Deterministic shape-and-tone pair derived from an entry id.
///
/// The same id always yields the same avatar look, so list reordering
/// never makes avatars "jump".
final class KeyelAvatarProfile {
  /// Creates a profile directly.
  const new({required this.shape, required this.tone});

  /// Derives a stable profile from an id hash.
  ///
  /// Uses a signed-object-free mix (`id.hashCode` plus golden-ratio
  /// stepping) so consecutive UUID v7 ids give varied combinations.
  factory fromId(String id) {
    final hash = Object.hash(id, 0x9E3779B9);
    final shape =
        KeyelAvatarShape.values[hash % KeyelAvatarShape.values.length];
    final tone =
        KeyelAvatarTone.values[(hash ~/ 31) % KeyelAvatarTone.values.length];
    return KeyelAvatarProfile(shape: shape, tone: tone);
  }

  /// Shape family for the avatar.
  final KeyelAvatarShape shape;

  /// Tone family for the avatar.
  final KeyelAvatarTone tone;
}

/// A [KeyelAvatar] whose look is stable for a given id.
///
/// ```dart
/// KeyelAvatar.forId(id: entry.id, icon: Icons.laptop_mac_rounded)
/// ```
class KeyelStableAvatar extends StatelessWidget {
  /// Creates an avatar with the look derived from [id].
  const new({required this.id, required this.icon, this.size = 48, super.key});

  /// Entry id (or any stable string) seeding the profile.
  final String id;

  /// Glyph shown inside the avatar.
  final IconData icon;

  /// Outer square size in dp.
  final double size;

  @override
  Widget build(BuildContext context) {
    final profile = KeyelAvatarProfile.fromId(id);
    return KeyelAvatar(
      icon: icon,
      tone: profile.tone,
      shape: profile.shape,
      size: size,
    );
  }
}
