import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/l10n/generated/app_localizations.dart';
import 'package:keyel/ui/l10n/locale_provider.dart';

Widget _host(Locale locale, Widget child) => ProviderScope(
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

Future<Map<String, Object?>> _arb(String locale) async {
  final raw = await File('lib/l10n/app_$locale.arb').readAsString();
  return jsonDecode(raw) as Map<String, Object?>;
}

void main() {
  test('English and French ship the same messages', () async {
    final en = await _arb('en');
    final fr = await _arb('fr');
    final enKeys = en.keys.where((key) => !key.startsWith('@')).toSet();
    final frKeys = fr.keys.where((key) => !key.startsWith('@')).toSet();
    expect(frKeys.difference(enKeys), isEmpty);
    expect(enKeys.difference(frKeys), isEmpty);
  });

  test('plural messages use named placeholders, not ICU #', () async {
    for (final locale in ['en', 'fr']) {
      final arb = await _arb(locale);
      for (final entry in arb.entries) {
        final value = entry.value;
        if (entry.key.startsWith('@') || value is! String) continue;
        final message = value;
        if (!message.contains(', plural,')) continue;
        expect(
          message.contains('#'),
          isFalse,
          reason:
              '$locale/${entry.key}: Flutter gen-l10n uses pluralLogic, '
              'so the count must be interpolated with {count}.',
        );
      }
    }
  });

  test('localeFromId accepts only shipped languages', () {
    expect(localeFromId('en'), const Locale('en'));
    expect(localeFromId('fr'), const Locale('fr'));
    expect(localeFromId('system'), isNull);
    expect(localeFromId('ar'), isNull);
  });

  testWidgets('English is the template locale', (tester) async {
    await tester.pumpWidget(
      _host(
        const Locale('en'),
        Builder(
          builder: (context) =>
              Text(AppLocalizations.of(context)!.actionLockVault),
        ),
      ),
    );

    expect(find.text('Lock vault'), findsOneWidget);
  });

  testWidgets('French messages resolve without a restart', (tester) async {
    await tester.pumpWidget(
      _host(
        const Locale('fr'),
        Builder(
          builder: (context) =>
              Text(AppLocalizations.of(context)!.actionLockVault),
        ),
      ),
    );

    expect(find.text('Verrouiller le coffre'), findsOneWidget);
  });

  testWidgets('French copy flows through a real screen at 200% in RTL', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      _host(
        const Locale('fr'),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Builder(
              builder: (context) =>
                  Text(AppLocalizations.of(context)!.settingsLanguageTitle),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Langue'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
  });

  testWidgets('locale notifier persists a supported choice', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(localeProvider.notifier).setLocaleId('fr');
    expect(container.read(localeProvider), const Locale('fr'));

    container.read(localeProvider.notifier).setLocaleId('system');
    expect(container.read(localeProvider), isNull);

    container.read(localeProvider.notifier).setLocaleId('ar');
    expect(container.read(localeProvider), isNull);
  });
}
