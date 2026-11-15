import 'package:flutter_test/flutter_test.dart';
import 'package:keyel/core/platform/debug_bundle.dart';
import 'package:keyel/data/app_preferences.dart';

void main() {
  group('buildDebugBundle', () {
    test('includes the version, platform and sorted settings', () {
      final text = buildDebugBundle(
        appVersion: '1.2.3+4',
        platform: 'android Android 13 (API 33)',
        settings: {'b': 2, 'a': true},
        generatedAt: DateTime.utc(2026, 11, 15, 12),
      );

      expect(text, contains('App version: 1.2.3+4'));
      expect(text, contains('Platform: android Android 13 (API 33)'));
      expect(text, contains('2026-11-15T12:00:00.000Z'));
      // Sorted: "a" before "b".
      expect(text.indexOf('  a: true'), lessThan(text.indexOf('  b: 2')));
    });
  });

  group('collectDebugBundle', () {
    setUp(() => AppPreferences.instance.recentSearches = <String>[]);

    test('reports the version and never leaks recent searches', () {
      // A recent search is user data (site names) and must stay out of the
      // bundle even though AppPreferences holds it.
      AppPreferences.instance.recentSearches = <String>['secret-bank.example'];

      final text = collectDebugBundle();

      expect(text, contains('App version:'));
      expect(text, contains('autoLockSeconds:'));
      expect(text, isNot(contains('secret-bank.example')));
      expect(text, contains('No vault data'));
    });
  });
}
