import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/ui/design_system/keyel_password_field.dart';

void main() {
  testWidgets('reveals on tap and re-masks automatically', (tester) async {
    final controller = TextEditingController(text: 'hunter2');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeyelPasswordField(controller: controller, label: 'Password'),
        ),
      ),
    );

    TextField field() => tester.widget<TextField>(find.byType(TextField));
    expect(field().obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(field().obscureText, isFalse);

    await tester.pump(const Duration(seconds: 14));
    expect(field().obscureText, isFalse);

    await tester.pump(const Duration(seconds: 2));
    expect(field().obscureText, isTrue);
  });

  testWidgets('toggling off cancels the pending re-mask', (tester) async {
    final controller = TextEditingController(text: 'hunter2');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeyelPasswordField(controller: controller, label: 'Password'),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );
  });
}
