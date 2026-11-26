import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyel/data/app_preferences.dart';

void _reset(AppPreferences prefs) {
  prefs
    ..generatorMode = 'password'
    ..generatorLength = 20
    ..generatorWordCount = 8
    ..generatorUppercase = true
    ..generatorLowercase = true
    ..generatorNumbers = true
    ..generatorSymbols = true
    ..generatorExcludeAmbiguous = true
    ..generatorCapitalize = true
    ..generatorIncludeNumber = false
    ..generatorSeparator = '-'
    ..clipboardClearSeconds = 30
    ..screenshotProtection = true
    ..unlockFailures = 0
    ..unlockLockedUntilMs = null
    ..localeId = 'system'
    ..themeMode = 'system'
    ..paletteId = 'indigo'
    ..amoledBlack = false
    ..animationsEnabled = true
    ..hapticsEnabled = true
    ..recentQuickActionIds = const [];
}

void main() {
  final prefs = AppPreferences.instance;

  setUp(() => _reset(prefs));

  test('generator options round-trip through settings.json', () async {
    final dir = await Directory.systemTemp.createTemp('keyel_prefs');
    addTearDown(() => dir.delete(recursive: true));
    final vaultPath = '${dir.path}/vault.keyel';

    prefs
      ..generatorMode = 'passphrase'
      ..generatorWordCount = 11
      ..generatorSeparator = '.'
      ..generatorIncludeNumber = true
      ..generatorSymbols = false;

    await prefs.load(vaultPath);
    await prefs.save();

    // Clobber the in-memory values, then read them back from disk.
    _reset(prefs);

    await prefs.load(vaultPath);

    expect(prefs.generatorMode, 'passphrase');
    expect(prefs.generatorWordCount, 11);
    expect(prefs.generatorSeparator, '.');
    expect(prefs.generatorIncludeNumber, isTrue);
    expect(prefs.generatorSymbols, isFalse);
  });

  test('missing settings file keeps the generator defaults', () async {
    final dir = await Directory.systemTemp.createTemp('keyel_prefs_missing');
    addTearDown(() => dir.delete(recursive: true));

    await prefs.load('${dir.path}/vault.keyel');

    expect(prefs.generatorMode, 'password');
    expect(prefs.generatorWordCount, 8);
    expect(prefs.generatorSeparator, '-');
  });

  test('autofill options round-trip through settings.json', () async {
    final dir = await Directory.systemTemp.createTemp('keyel_prefs_autofill');
    addTearDown(() => dir.delete(recursive: true));
    final vaultPath = '${dir.path}/vault.keyel';

    prefs
      ..autofillAskToSave = false
      ..autofillMatchMode = 'exact'
      ..autofillVerifiedOnly = true;

    await prefs.load(vaultPath);
    await prefs.save();

    // Clobber the in-memory values, then read them back from disk.
    prefs
      ..autofillAskToSave = true
      ..autofillMatchMode = 'domain'
      ..autofillVerifiedOnly = false;

    await prefs.load(vaultPath);

    expect(prefs.autofillAskToSave, isFalse);
    expect(prefs.autofillMatchMode, 'exact');
    expect(prefs.autofillVerifiedOnly, isTrue);
  });

  test('autofill verified-only fails closed for older settings files', () async {
    final dir = await Directory.systemTemp.createTemp('keyel_prefs_legacy');
    addTearDown(() => dir.delete(recursive: true));
    final vaultPath = '${dir.path}/vault.keyel';
    await File('${dir.path}/settings.json').writeAsString('{}');

    // Simulate a hot-reload/clobbered singleton before reading legacy settings.
    prefs.autofillVerifiedOnly = false;
    await prefs.load(vaultPath);

    expect(prefs.autofillVerifiedOnly, isTrue);

    // An explicit opt-out is still honoured.
    prefs.autofillVerifiedOnly = false;
    await prefs.save();
    await prefs.load(vaultPath);
    expect(prefs.autofillVerifiedOnly, isFalse);

    // Restore the fail-closed default for later tests.
    prefs.autofillVerifiedOnly = true;
  });

  test('legacy explicit autofill opt-out is migrated to fail closed', () async {
    final dir = await Directory.systemTemp.createTemp('keyel_prefs_upgrade');
    addTearDown(() => dir.delete(recursive: true));
    final vaultPath = '${dir.path}/vault.keyel';
    await File('${dir.path}/settings.json')
        .writeAsString('{"autofillVerifiedOnly": false}');

    prefs.autofillVerifiedOnly = false;
    await prefs.load(vaultPath);
    expect(
      prefs.autofillVerifiedOnly,
      isTrue,
      reason: '1.10.2 wrote false by default; upgrades must fail closed',
    );

    // Once stamped, a deliberate opt-out is persisted across restarts.
    prefs.autofillVerifiedOnly = false;
    await prefs.save();
    await prefs.load(vaultPath);
    expect(prefs.autofillVerifiedOnly, isFalse);
    prefs.autofillVerifiedOnly = true;
  });

  test('deleting settings restores fail-closed security defaults', () async {
    final dir = await Directory.systemTemp.createTemp('keyel_prefs_missing');
    addTearDown(() => dir.delete(recursive: true));
    final vaultPath = '${dir.path}/vault.keyel';
    final settings = File('${dir.path}/settings.json');
    await settings.writeAsString('{}');
    await prefs.load(vaultPath);

    prefs
      ..autofillVerifiedOnly = false
      ..screenshotProtection = false;
    await settings.delete();
    await prefs.load(vaultPath);

    expect(prefs.autofillVerifiedOnly, isTrue);
    expect(prefs.screenshotProtection, isTrue);
  });

  test(
    'autofill deny list round-trips and rejects malformed entries',
    () async {
      final dir = await Directory.systemTemp.createTemp('keyel_prefs_deny');
      addTearDown(() => dir.delete(recursive: true));
      final vaultPath = '${dir.path}/vault.keyel';

      prefs.autofillNeverForSites = const [
        'host:example.com',
        'package:com.example.app',
      ];
      await prefs.load(vaultPath);
      await prefs.save();

      prefs.autofillNeverForSites = <String>[];
      await prefs.load(vaultPath);
      expect(prefs.autofillNeverForSites, [
        'host:example.com',
        'package:com.example.app',
      ]);

      await File('${dir.path}/settings.json').writeAsString(
        '{"autofillNeverForSites":["host:ok.example","host:bad host", '
        '"https://evil.example","not-a-key","host:ok.example"]}',
      );
      prefs.autofillNeverForSites = <String>[];
      await prefs.load(vaultPath);
      expect(prefs.autofillNeverForSites, ['host:ok.example']);
    },
  );

  test('unlock throttle state round-trips through settings.json', () async {
    final dir = await Directory.systemTemp.createTemp('keyel_prefs_unlock');
    addTearDown(() => dir.delete(recursive: true));
    final vaultPath = '${dir.path}/vault.keyel';

    prefs
      ..unlockFailures = 4
      ..unlockLockedUntilMs = 1700000000000;

    await prefs.load(vaultPath);
    await prefs.save();

    // Clobber the in-memory values, then read them back from disk.
    prefs
      ..unlockFailures = 0
      ..unlockLockedUntilMs = null;

    await prefs.load(vaultPath);

    expect(prefs.unlockFailures, 4);
    expect(prefs.unlockLockedUntilMs, 1700000000000);
  });

  test('clipboard timeout round-trips through settings.json', () async {
    final dir = await Directory.systemTemp.createTemp('keyel_prefs_clipboard');
    addTearDown(() => dir.delete(recursive: true));
    final vaultPath = '${dir.path}/vault.keyel';

    prefs.clipboardClearSeconds = 60;
    await prefs.load(vaultPath);
    await prefs.save();

    // Clobber the in-memory value, then read it back from disk.
    prefs.clipboardClearSeconds = 30;
    await prefs.load(vaultPath);
    expect(prefs.clipboardClearSeconds, 60);
    expect(prefs.clipboardClearDelay, const Duration(minutes: 1));

    // Zero means never, and must survive the round trip too.
    prefs.clipboardClearSeconds = 0;
    await prefs.save();
    prefs.clipboardClearSeconds = 30;
    await prefs.load(vaultPath);
    expect(prefs.clipboardClearSeconds, 0);
    expect(prefs.clipboardClearDelay, isNull);
  });

  test('screenshot protection round-trips and fails safe', () async {
    final dir = await Directory.systemTemp.createTemp('keyel_prefs_screenshot');
    addTearDown(() => dir.delete(recursive: true));
    final vaultPath = '${dir.path}/vault.keyel';

    // Persist an explicit opt-out on disk: a missing settings file correctly
    // resets to the fail-closed default, so it cannot simulate a saved choice.
    await File('${dir.path}/settings.json')
        .writeAsString('{"screenshotProtection": false}');
    await prefs.load(vaultPath);

    prefs.screenshotProtection = true;
    await prefs.load(vaultPath);
    expect(prefs.screenshotProtection, isFalse, reason: 'explicit opt-out');

    // A settings file with no screenshot key keeps protection on.
    final freshDir = await Directory.systemTemp.createTemp(
      'keyel_prefs_screenshot_default',
    );
    addTearDown(() => freshDir.delete(recursive: true));
    await File('${freshDir.path}/settings.json').writeAsString('{}');
    prefs.screenshotProtection = false;
    await prefs.load('${freshDir.path}/vault.keyel');
    expect(prefs.screenshotProtection, isTrue);
  });

  test('appearance preferences round-trip through settings.json', () async {
    final dir = await Directory.systemTemp.createTemp('keyel_prefs_appearance');
    addTearDown(() => dir.delete(recursive: true));
    final vaultPath = '${dir.path}/vault.keyel';

    prefs
      ..themeMode = 'dark'
      ..paletteId = 'ocean'
      ..amoledBlack = true
      ..animationsEnabled = false
      ..hapticsEnabled = false;

    await prefs.load(vaultPath);
    await prefs.save();

    _reset(prefs);
    await prefs.load(vaultPath);

    expect(prefs.themeMode, 'dark');
    expect(prefs.paletteId, 'ocean');
    expect(prefs.amoledBlack, isTrue);
    expect(prefs.animationsEnabled, isFalse);
    expect(prefs.hapticsEnabled, isFalse);
  });

  test('quick-action recency round-trips and rejects corrupt ids', () async {
    final dir = await Directory.systemTemp.createTemp('keyel_prefs_recency');
    addTearDown(() => dir.delete(recursive: true));
    final vaultPath = '${dir.path}/vault.keyel';

    await prefs.load(vaultPath);
    prefs
      ..rememberQuickActionEntry('a')
      ..rememberQuickActionEntry('b')
      ..rememberQuickActionEntry('a');
    await prefs.save();

    _reset(prefs);
    await prefs.load(vaultPath);
    expect(prefs.recentQuickActionIds, ['a', 'b']);

    await File('${dir.path}/settings.json')
        .writeAsString('{"recentQuickActionIds":["x",3,"",null,"y"]}');
    prefs.recentQuickActionIds = const ['stale'];
    await prefs.load(vaultPath);
    expect(prefs.recentQuickActionIds, ['x', 'y']);
  });

  test('language choice round-trips and rejects unknown ids', () async {
    final dir = await Directory.systemTemp.createTemp('keyel_prefs_locale');
    addTearDown(() => dir.delete(recursive: true));
    final vaultPath = '${dir.path}/vault.keyel';

    prefs.localeId = 'fr';
    await prefs.load(vaultPath);
    await prefs.save();

    _reset(prefs);
    await prefs.load(vaultPath);
    expect(prefs.localeId, 'fr');

    await File('${dir.path}/settings.json').writeAsString('{"localeId":"zz"}');
    prefs.localeId = 'system';
    await prefs.load(vaultPath);
    expect(prefs.localeId, 'system');
  });

  test('missing appearance settings keep defaults', () async {
    final dir = await Directory.systemTemp.createTemp(
      'keyel_prefs_appearance_missing',
    );
    addTearDown(() => dir.delete(recursive: true));
    await prefs.load('${dir.path}/vault.keyel');

    expect(prefs.themeMode, 'system');
    expect(prefs.paletteId, 'indigo');
    expect(prefs.amoledBlack, isFalse);
    expect(prefs.animationsEnabled, isTrue);
    expect(prefs.hapticsEnabled, isTrue);
  });

  test('save is atomic, serialized and creates a missing parent', () async {
    final dir = await Directory.systemTemp.createTemp('keyel_prefs_atomic');
    addTearDown(() => dir.delete(recursive: true));
    // The vault directory may not exist yet if the bridge failed to initialize.
    final vaultPath = '${dir.path}/nested/vault.keyel';

    await prefs.load(vaultPath);
    prefs.localeId = 'fr';
    // Production callers fire and forget; both saves must land in call order
    // without ever leaving a truncated settings.json behind.
    final first = prefs.save();
    prefs.localeId = 'en';
    final second = prefs.save();
    await Future.wait([first, second]);

    final file = File('${dir.path}/nested/settings.json');
    expect(file.existsSync(), isTrue);
    expect(File('${file.path}.tmp').existsSync(), isFalse);

    _reset(prefs);
    await prefs.load(vaultPath);
    expect(prefs.localeId, 'en');
  });
}
