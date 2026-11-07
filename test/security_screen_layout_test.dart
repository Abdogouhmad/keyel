import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyel/features/security_dashboard/security_screen.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

void main() {
  testWidgets('security dashboard lays out on a compact phone', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: KeyelTheme.light(), home: const SecurityScreen()),
    );

    await tester.pumpAndSettle();

    expect(find.text('Vulnerability summary'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('Vulnerability audit'), findsOneWidget);
    expect(find.text('Insecure websites (HTTP)'), findsOneWidget);
    expect(find.text('Offline breach check'), findsOneWidget);
  });
}
