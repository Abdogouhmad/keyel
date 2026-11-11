import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyel/features/entry/widgets/edit/totp_section.dart';
import 'package:keyel/features/generator/widgets/passphrase_rules.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

Widget _host(Widget child) => MaterialApp(
  theme: KeyelTheme.light(),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('TotpSection shows the configured state and replace action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(TotpSection(onScan: () {}, onManual: () {}, configured: true)),
    );

    expect(find.text('Configured'), findsOneWidget);
    expect(find.text('Replace Key'), findsOneWidget);
    expect(find.text('Enter Manually'), findsNothing);
  });

  testWidgets('TotpSection offers manual entry when unconfigured', (
    tester,
  ) async {
    await tester.pumpWidget(_host(TotpSection(onScan: () {}, onManual: () {})));

    expect(find.text('TOTP'), findsOneWidget);
    expect(find.text('Enter Manually'), findsOneWidget);
  });

  testWidgets('PassphraseRules reports the chosen separator', (tester) async {
    var selected = '-';
    await tester.pumpWidget(
      _host(
        PassphraseRules(
          capitalizeFirst: true,
          includeNumber: false,
          separator: '-',
          onCapitalizeFirstChanged: (_) {},
          onIncludeNumberChanged: (_) {},
          onSeparatorChanged: (value) => selected = value,
        ),
      ),
    );

    expect(find.text('WORD SEPARATOR'), findsOneWidget);
    await tester.tap(find.text('Space'));
    await tester.pump();
    expect(selected, ' ');
  });
}
