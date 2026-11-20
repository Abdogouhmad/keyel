import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/features/entry/entry_edit_screen.dart';
import 'package:keyel/ui/keyel.dart';

/// Exercises the PopScope unsaved-changes guard on a brand-new entry. No
/// repository calls happen on this route, so the real provider is safe here.
void main() {
  late GoRouter router;

  Future<void> pumpEditor(WidgetTester tester) async {
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('home-marker'))),
        ),
        GoRoute(
          path: '/edit',
          builder: (context, state) => const EntryEditScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: KeyelTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.push('/edit'));
    await tester.pumpAndSettle();
  }

  testWidgets('a pristine editor pops without a dialog', (tester) async {
    await pumpEditor(tester);
    expect(find.text('New Login'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('home-marker'), findsOneWidget);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('an edited editor confirms before discarding', (tester) async {
    await pumpEditor(tester);

    await tester.enterText(find.byType(EditableText).first, 'Example');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.text('home-marker'), findsNothing);

    // Cancelling keeps the editor and its edit.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('New Login'), findsOneWidget);
    expect(find.text('Example'), findsOneWidget);

    // Confirming discards and returns home.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('home-marker'), findsOneWidget);
  });
}
