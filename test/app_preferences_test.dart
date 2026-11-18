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
    ..unlockFailures = 0
    ..unlockLockedUntilMs = null
    ..themeMode = 'system'
    ..paletteId = 'indigo'
    ..amoledBlack = false
    ..animationsEnabled = true
    ..hapticsEnabled = true;
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
      ..autofillMatchMode = 'exact';

    await prefs.load(vaultPath);
    await prefs.save();

    // Clobber the in-memory values, then read them back from disk.
    prefs
      ..autofillAskToSave = true
      ..autofillMatchMode = 'domain';

    await prefs.load(vaultPath);

    expect(prefs.autofillAskToSave, isFalse);
    expect(prefs.autofillMatchMode, 'exact');
  });

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

  test('appearance preferences round-trip through settings.json', () async {
    final dir = await Directory.systemTemp.createTemp(
      'keyel_prefs_appearance',
    );
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

}
