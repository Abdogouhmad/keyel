import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/autofill/autofill_save_screen.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// A repository whose upsert is recorded instead of hitting Rust.
class _FakeRepository extends VaultRepository {
  new();

  EntryDraft? lastDraft;

  @override
  bool get vaultExists => true;

  @override
  bool get isUnlocked => true;

  @override
  Stream<String> lockEvents() => const Stream<String>.empty();

  @override
  Future<String> upsertEntry(EntryDraft draft) async {
    lastDraft = draft;
    return 'new-id';
  }
}

Widget _host(
  _FakeRepository repository, {
  String? package = 'com.example.app',
  String? webDomain,
  String username = 'ada@example.com',
  String password = 'correct horse battery staple',
  VoidCallback? onSaved,
  VoidCallback? onDecline,
}) => ProviderScope(
  overrides: [vaultRepositoryProvider.overrideWithValue(repository)],
  child: MaterialApp(
    theme: KeyelTheme.light(),
    home: AutofillSaveScreen(
      package: package,
      webDomain: webDomain,
      username: username,
      password: password,
      onSaved: onSaved,
      onDecline: onDecline,
    ),
  ),
);

void main() {
  testWidgets('prefills the name, username and password', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(_FakeRepository(), webDomain: 'www.example.com'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Save login?'), findsOneWidget);
    expect(find.textContaining('www.example.com'), findsOneWidget);

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].controller!.text, 'example.com'); // default name
    expect(fields[1].controller!.text, 'ada@example.com');

    final password = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(password.controller!.text, 'correct horse battery staple');
  });

  testWidgets('saving stores a login keyed to the web domain', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = _FakeRepository();
    var saved = false;
    await tester.pumpWidget(
      _host(repository, webDomain: 'example.com', onSaved: () => saved = true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save login'));
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    final draft = repository.lastDraft;
    expect(draft, isNotNull);
    expect(draft!.kind, EntryKindDto.login);
    expect(draft.title, 'example.com');
    expect(draft.username, 'ada@example.com');
    expect(draft.password, 'correct horse battery staple');
    expect(draft.url, 'https://example.com');
  });

  testWidgets('saving for an app stores an androidapp URL', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = _FakeRepository();
    await tester.pumpWidget(_host(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save login'));
    await tester.pumpAndSettle();

    expect(repository.lastDraft!.url, 'androidapp://com.example.app');
    expect(repository.lastDraft!.title, 'com.example.app');
  });

  testWidgets('declining does not write anything', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = _FakeRepository();
    var declined = false;
    await tester.pumpWidget(
      _host(repository, onDecline: () => declined = true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(declined, isTrue);
    expect(repository.lastDraft, isNull);
  });

  testWidgets('an empty name blocks the save', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = _FakeRepository();
    await tester.pumpWidget(_host(repository, webDomain: 'example.com'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save login'));
    await tester.pumpAndSettle();

    expect(repository.lastDraft, isNull);
    expect(find.text('Give this login a name first.'), findsOneWidget);
  });

  testWidgets('save screen has no overflow at 200% text scale', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      _host(_FakeRepository(), webDomain: 'www.example.com'),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
