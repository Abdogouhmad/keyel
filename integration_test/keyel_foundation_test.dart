import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:keyel/main.dart';
import 'package:keyel/src/rust/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    unawaited(RustLib.init());
  });

  testWidgets('0.1.0 foundation: generator shows a Rust-generated password', (
    tester,
  ) async {
    await tester.pumpWidget(const KeyelApp());
    await tester.pumpAndSettle();

    // Open the Generator tab from the bottom navigation.
    await tester.tap(find.text('Generator'));
    await tester.pumpAndSettle();

    final passwordFinder = find.byKey(const ValueKey('generatorPassword'));
    expect(passwordFinder, findsOneWidget);

    String readPassword() {
      final text = tester.widget<Text>(passwordFinder);
      return text.textSpan?.toPlainText() ?? text.data ?? '';
    }

    final password = readPassword();

    // 20 chars, drawn from the ambiguity-free alphabet.
    expect(password.length, 20);
    expect(password, isNot(contains('l')));
    expect(password, isNot(contains('I')));
    expect(password, isNot(contains('0')));
    expect(password, isNot(contains('O')));

    // Regenerate produces a different password.
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pumpAndSettle();
    expect(readPassword(), isNot(password));
    expect(readPassword().length, 20);
  });
}
