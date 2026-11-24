import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/features/entry/widgets/detail/notes_card.dart';
import 'package:keyel/ui/keyel.dart';

Widget _host({required String? revealed}) => MaterialApp(
  theme: KeyelTheme.light(),
  home: Scaffold(
    body: NotesCard(
      title: 'Notes',
      icon: Icons.notes_rounded,
      revealedContent: revealed,
      onToggleReveal: () {},
      onCopy: (_, _) {},
    ),
  ),
);

void main() {
  testWidgets('attached note plaintext is not rendered before reveal', (
    tester,
  ) async {
    await tester.pumpWidget(_host(revealed: null));

    expect(find.text('recovery seed'), findsNothing);
    expect(find.text('Encrypted content'), findsOneWidget);
  });

  testWidgets('revealed note renders its plaintext', (tester) async {
    await tester.pumpWidget(_host(revealed: 'recovery seed'));

    expect(find.text('recovery seed'), findsOneWidget);
  });
}
