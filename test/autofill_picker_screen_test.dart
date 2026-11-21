import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/autofill/autofill_picker_screen.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

EntrySummaryDto _summary(String id, String title) => EntrySummaryDto(
  id: id,
  kind: EntryKindDto.login,
  title: title,
  subtitle: 'ada@example.com',
  favorite: false,
  hasTotp: false,
);

AutofillMatchDto _match(String id, String title, AutofillQualityDto quality) =>
    AutofillMatchDto(summary: _summary(id, title), quality: quality);

/// A repository whose autofill calls are recorded instead of hitting Rust.
class _FakeRepository extends VaultRepository {
  new({this.matches = const [], this.unlocked = true});

  final List<AutofillMatchDto> matches;
  final bool unlocked;

  String? lastPackage;
  String? lastWebDomain;
  String? lastQuery;
  String? revealedId;
  String? revealedField;

  @override
  bool get vaultExists => true;

  @override
  bool get isUnlocked => unlocked;

  @override
  Stream<String> lockEvents() => const Stream<String>.empty();

  @override
  Future<List<AutofillMatchDto>> findAutofillMatches({
    String? package,
    String? webDomain,
    String query = '',
    bool requireVerified = false,
  }) async {
    lastPackage = package;
    lastWebDomain = webDomain;
    lastQuery = query;
    return matches;
  }

  @override
  Future<EntryDetailDto> getEntry(String id) async => EntryDetailDto(
    id: id,
    kind: EntryKindDto.login,
    title: 'Title',
    tags: const [],
    favorite: false,
    createdAt: BigInt.zero,
    updatedAt: BigInt.zero,
    hasNotes: false,
    login: const LoginDetailDto(
      username: 'ada@example.com',
      url: 'https://example.com',
      hasPassword: true,
      passwordHistoryCount: 0,
    ),
    customFields: const [],
  );

  @override
  Future<String> revealField(String id, SecretFieldDto field) async {
    revealedId = id;
    revealedField = field.name;
    return 'correct horse battery staple';
  }
}

Widget _host(
  _FakeRepository repository, {
  String? package = 'com.example.app',
  String? webDomain,
  ValueChanged<AutofillSelection>? onPicked,
  VoidCallback? onNeverForSite,
}) => ProviderScope(
  overrides: [vaultRepositoryProvider.overrideWithValue(repository)],
  child: MaterialApp(
    theme: KeyelTheme.light(),
    home: AutofillPickerScreen(
      package: package,
      webDomain: webDomain,
      onPicked: onPicked,
      onNeverForSite: onNeverForSite,
    ),
  ),
);

void main() {
  setUp(() {
    AppPreferences.instance
      ..autofillMatchMode = 'domain'
      ..autofillAskToSave = true
      ..autofillVerifiedOnly = false
      ..autofillNeverForSites = <String>[];
  });

  testWidgets('renders exact, same-site and search matches', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = _FakeRepository(
      matches: [
        _match('a', 'Exact login', AutofillQualityDto.exact),
        _match('b', 'Sub login', AutofillQualityDto.sameSite),
        _match('c', 'Text login', AutofillQualityDto.search),
      ],
    );
    await tester.pumpWidget(_host(repository));
    await tester.pumpAndSettle();

    expect(repository.lastPackage, 'com.example.app');
    expect(find.text('Exact login'), findsOneWidget);
    expect(find.text('Sub login'), findsOneWidget);
    expect(find.text('Text login'), findsOneWidget);

    // A search-only hit on a known target warns the user.
    expect(find.textContaining('text matches only'), findsOneWidget);
  });

  testWidgets('no warning banner when every match is exact', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = _FakeRepository(
      matches: [_match('a', 'Exact login', AutofillQualityDto.exact)],
    );
    await tester.pumpWidget(_host(repository));
    await tester.pumpAndSettle();

    expect(find.text('Exact login'), findsOneWidget);
    expect(find.textContaining('text matches only'), findsNothing);
  });

  testWidgets('strict match mode hides same-site results', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    AppPreferences.instance.autofillMatchMode = 'exact';
    final repository = _FakeRepository(
      matches: [
        _match('a', 'Exact login', AutofillQualityDto.exact),
        _match('b', 'Sub login', AutofillQualityDto.sameSite),
      ],
    );
    await tester.pumpWidget(_host(repository));
    await tester.pumpAndSettle();

    expect(find.text('Exact login'), findsOneWidget);
    expect(find.text('Sub login'), findsNothing);
  });

  testWidgets('locked vault shows the unlock prompt and no matches', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = _FakeRepository(
      unlocked: false,
      matches: [_match('a', 'Exact login', AutofillQualityDto.exact)],
    );
    await tester.pumpWidget(_host(repository));
    await tester.pumpAndSettle();

    expect(find.text('Vault locked'), findsOneWidget);
    expect(find.text('Exact login'), findsNothing);
  });

  testWidgets('empty result set shows the no-matches note', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(_FakeRepository()));
    await tester.pumpAndSettle();

    expect(find.text('No matching logins'), findsOneWidget);
  });

  testWidgets('tapping a match reveals the password and reports a selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = _FakeRepository(
      matches: [_match('a', 'Exact login', AutofillQualityDto.exact)],
    );
    AutofillSelection? picked;
    await tester.pumpWidget(_host(repository, onPicked: (s) => picked = s));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Exact login'));
    await tester.pumpAndSettle();

    expect(repository.revealedId, 'a');
    expect(repository.revealedField, SecretFieldDto.loginPassword.name);
    expect(picked, isNotNull);
    expect(picked!.id, 'a');
    expect(picked!.username, 'ada@example.com');
    expect(picked!.password, 'correct horse battery staple');
  });

  testWidgets('search box queries the vault for the typed text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = _FakeRepository();
    await tester.pumpWidget(_host(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'bank');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(repository.lastQuery, 'bank');
  });

  testWidgets('picker has no overflow at 200% text scale', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final repository = _FakeRepository(
      matches: [
        _match('a', 'Exact login', AutofillQualityDto.exact),
        _match('b', 'Sub login', AutofillQualityDto.sameSite),
        _match('c', 'Text login', AutofillQualityDto.search),
      ],
    );
    await tester.pumpWidget(_host(repository));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('verified mode hides same-site and text matches', (tester) async {
    AppPreferences.instance.autofillVerifiedOnly = true;
    final repository = _FakeRepository(
      matches: [
        _match('a', 'Exact login', AutofillQualityDto.exact),
        _match('b', 'Sub login', AutofillQualityDto.sameSite),
        _match('c', 'Text login', AutofillQualityDto.search),
      ],
    );
    await tester.pumpWidget(_host(repository));
    await tester.pumpAndSettle();

    expect(repository.lastPackage, 'com.example.app');
    expect(find.text('Exact login'), findsOneWidget);
    expect(find.text('Sub login'), findsNothing);
    expect(find.text('Text login'), findsNothing);
  });

  testWidgets('never-for-site action is reported to the host', (tester) async {
    final repository = _FakeRepository(
      matches: [_match('a', 'Exact login', AutofillQualityDto.exact)],
    );
    var neverCalled = false;
    await tester.pumpWidget(
      _host(repository, onNeverForSite: () => neverCalled = true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Never for this site'));
    await tester.pumpAndSettle();

    expect(neverCalled, isTrue);
  });

  testWidgets('a denied target shows no credentials', (tester) async {
    AppPreferences.instance.autofillNeverForSites = const [
      'package:com.example.app',
    ];
    final repository = _FakeRepository(
      matches: [_match('a', 'Exact login', AutofillQualityDto.exact)],
    );
    await tester.pumpWidget(_host(repository));
    await tester.pumpAndSettle();

    expect(find.text('Autofill is off for this site'), findsOneWidget);
    expect(find.text('Exact login'), findsNothing);
    expect(find.text('Never for this site'), findsNothing);
  });
}
