import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/entry/widgets/detail/credentials_card.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

final _detail = EntryDetailDto(
  id: 'entry-1',
  kind: EntryKindDto.login,
  title: 'Example',
  tags: const [],
  favorite: false,
  createdAt: BigInt.zero,
  updatedAt: BigInt.zero,
  hasNotes: false,
  customFields: const [],
  login: const LoginDetailDto(
    username: 'ada@example.com',
    url: 'https://example.com',
    hasPassword: true,
    passwordHistoryCount: 0,
  ),
);

const _entry = VaultEntry(
  id: 'entry-1',
  title: 'Example',
  kind: VaultEntryKind.login,
  icon: Icons.language_rounded,
  username: 'ada@example.com',
  website: 'https://example.com',
);

class _Harness extends StatefulWidget {
  const new({required this.copied, required this.opened, this.rtl = false});

  final void Function(String value) copied;
  final void Function(String url) opened;
  final bool rtl;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  String? _revealed;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: KeyelTheme.light(),
    home: Scaffold(
      body: Directionality(
        textDirection: widget.rtl ? TextDirection.rtl : TextDirection.ltr,
        child: SingleChildScrollView(
          child: CredentialsCard(
            entry: _entry,
            detail: _detail,
            revealedPassword: _revealed,
            onToggleReveal: () => setState(() {
              _revealed = _revealed == null ? 's3cret-pass' : null;
            }),
            onCopy: (value, _) => widget.copied(value),
            onCopyPassword: () => setState(() => _revealed = 's3cret-pass'),
            onOpenUrl: widget.opened,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('login fields carry leading glyphs and reveal on demand', (
    tester,
  ) async {
    final copied = <String>[];
    final opened = <String>[];
    await tester.pumpWidget(_Harness(copied: copied.add, opened: opened.add));
    await tester.pumpAndSettle();

    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.text('https://example.com'), findsOneWidget);
    expect(find.text('••••••••••••'), findsOneWidget);
    // Section glyph plus the password field's leading glyph.
    expect(find.byIcon(Icons.key_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.language_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pump();
    expect(find.text('s3cret-pass'), findsOneWidget);
    expect(find.text('••••••••••••'), findsNothing);
    expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);
  });

  testWidgets('credential copy and open actions keep their callbacks', (
    tester,
  ) async {
    final copied = <String>[];
    final opened = <String>[];
    await tester.pumpWidget(_Harness(copied: copied.add, opened: opened.add));
    await tester.pumpAndSettle();

    // Username and website each have a copy action; website also opens.
    expect(find.byIcon(Icons.content_copy_rounded), findsNWidgets(3));
    await tester.tap(find.byIcon(Icons.content_copy_rounded).last);
    await tester.pump();
    expect(copied, contains('https://example.com'));

    await tester.tap(find.byIcon(Icons.open_in_new_rounded));
    await tester.pump();
    expect(opened, contains('https://example.com'));
  });

  testWidgets('credential fields render without overflow in RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(copied: (_) {}, opened: (_) {}, rtl: true),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
  });
}
