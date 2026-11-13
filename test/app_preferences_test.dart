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
    ..generatorSeparator = '-';
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
}
