/// Build metadata compiled into the app.
///
/// The version is injected at build time (`--dart-define=KEYEL_VERSION=...`)
/// so it always matches `pubspec.yaml` without a plugin. Debug runs fall back
/// to `dev`.
abstract final class AppInfo {
  /// Human-readable app version, for example `1.0.0`.
  static const String version = String.fromEnvironment(
    'KEYEL_VERSION',
    defaultValue: 'dev',
  );

  /// Version reported to bug reports; `dev` builds are flagged as such.
  static bool get isReleaseBuild => version != 'dev';
}
