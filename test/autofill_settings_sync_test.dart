import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/autofill_settings_provider.dart';

/// Exposes the provider state as text so the test can observe rebuilds.
class _AutofillProbe extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(autofillSettingsProvider);
    return Text(
      '${settings.askToSave}/${settings.matchMode}/${settings.verifiedOnly}/'
      '${settings.neverForSites.length}',
    );
  }
}

void main() {
  setUp(() {
    AppPreferences.instance
      ..autofillAskToSave = true
      ..autofillMatchMode = 'domain'
      ..autofillVerifiedOnly = true
      ..autofillNeverForSites = ['blocked.example'];
  });

  testWidgets('setters publish new state and write through to the singleton', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: _AutofillProbe())),
    );
    await tester.pumpAndSettle();

    expect(find.text('true/domain/true/1'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(_AutofillProbe)),
    );
    final notifier = container.read(autofillSettingsProvider.notifier);

    // Each write is followed by a pump and assertions, so a cascade cannot
    // span them; ignore the lint rather than hide the rebuild checks.
    // ignore: cascade_invocations
    notifier.setAskToSave(value: false);
    await tester.pump();
    expect(find.text('false/domain/true/1'), findsOneWidget);
    expect(AppPreferences.instance.autofillAskToSave, isFalse);

    notifier.toggleMatchMode();
    await tester.pump();
    expect(find.text('false/exact/true/1'), findsOneWidget);
    expect(AppPreferences.instance.autofillMatchMode, 'exact');

    notifier.setVerifiedOnly(value: false);
    await tester.pump();
    expect(find.text('false/exact/false/1'), findsOneWidget);
    expect(AppPreferences.instance.autofillVerifiedOnly, isFalse);

    notifier.removeNeverSite('blocked.example');
    await tester.pump();
    expect(find.text('false/exact/false/0'), findsOneWidget);
    expect(AppPreferences.instance.autofillNeverForSites, isEmpty);
  });

  test('snapshot keeps the fail-closed verified-only default', () {
    // Missing/older settings leave the singleton at the fail-closed default.
    AppPreferences.instance.autofillVerifiedOnly = true;
    final provider = autofillSettingsProvider;
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(provider).verifiedOnly, isTrue);
  });
}
