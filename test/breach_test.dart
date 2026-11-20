import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keyel/core/breach/breach_service.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/breach_provider.dart';
import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/security_dashboard/widgets/breach_check_row.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

class _FakeRepository extends VaultRepository {
  int beginCalls = 0;
  bool cancelled = false;
  List<BreachRangeResponseDto>? lastResponses;

  @override
  Future<BreachCheckRequestDto> beginBreachCheck() async {
    beginCalls++;
    return const BreachCheckRequestDto(
      token: 'TOKEN',
      prefixes: ['5BAA6'],
      checkedCount: 1,
    );
  }

  @override
  Future<BreachReportDto> finishBreachCheck({
    required String token,
    required List<BreachRangeResponseDto> responses,
  }) async {
    lastResponses = responses;
    return const BreachReportDto(
      matches: [BreachMatchDto(entryId: 'id', entryTitle: 'Mail', count: 7)],
      checkedCount: 1,
      queriedPrefixes: 1,
    );
  }

  @override
  void cancelBreachCheck() {
    cancelled = true;
  }
}

class _UnlockedSession extends VaultSessionNotifier {
  @override
  VaultSessionState build() =>
      const VaultSessionState(status: VaultStatus.unlocked);
}

class _LockedSession extends VaultSessionNotifier {
  @override
  VaultSessionState build() =>
      const VaultSessionState(status: VaultStatus.locked);
}

/// A session that can be locked mid-check, to model auto-lock while the
/// security screen is closed (so no widget listener can reset the UI).
class _MutableSession extends VaultSessionNotifier {
  @override
  VaultSessionState build() =>
      const VaultSessionState(status: VaultStatus.unlocked);

  void lockNow() => state = const VaultSessionState(status: VaultStatus.locked);
}

Widget _host({
  required BreachService service,
  required VaultRepository repository,
  bool locked = false,
}) {
  return ProviderScope(
    overrides: [
      breachServiceProvider.overrideWithValue(service),
      vaultRepositoryProvider.overrideWithValue(repository),
      vaultSessionProvider.overrideWith(
        locked ? _LockedSession.new : _UnlockedSession.new,
      ),
    ],
    child: MaterialApp(
      theme: KeyelTheme.light(),
      home: const Scaffold(
        body: SingleChildScrollView(child: BreachCheckRow()),
      ),
    ),
  );
}

BreachService _service({
  required Future<http.Response> Function(http.Request) handler,
}) {
  return BreachService(client: MockClient(handler));
}

void main() {
  setUp(() {
    AppPreferences.instance.breachCheckEnabled = false;
  });

  tearDown(() {
    AppPreferences.instance.breachCheckEnabled = false;
  });

  group('BreachService', () {
    test('fetches only the hard-coded HTTPS range endpoint', () async {
      final service = _service(
        handler: (request) async {
          expect(
            request.url.toString(),
            'https://api.pwnedpasswords.com/range/5BAA6',
          );
          expect(request.headers['User-Agent'], 'Keyel-BreachCheck/1.7.0');
          expect(request.headers['Accept'], 'text/plain');
          return http.Response('SOMEHASH:3730471\r\n', 200);
        },
      );

      expect(await service.fetchRange('5BAA6'), contains('3730471'));
    });

    test('rejects an invalid prefix without making a request', () async {
      var called = false;
      final service = _service(
        handler: (request) async {
          called = true;
          return http.Response('', 200);
        },
      );

      await expectLater(service.fetchRange('../admin'), throwsArgumentError);
      expect(called, isFalse);
    });

    test('surfaces a non-200 response as an error', () async {
      final service = _service(
        handler: (request) async => http.Response('nope', 503),
      );
      await expectLater(
        service.fetchRange('5BAA6'),
        throwsA(isA<HttpException>()),
      );
    });
  });

  test('opt-in round trips through settings.json', () async {
    final dir = await Directory.systemTemp.createTemp('keyel-breach');
    addTearDown(() => dir.delete(recursive: true));
    final vaultPath = '${dir.path}/vault.keyel';

    await AppPreferences.instance.load(vaultPath);
    expect(AppPreferences.instance.breachCheckEnabled, isFalse);

    AppPreferences.instance.breachCheckEnabled = true;
    await AppPreferences.instance.save();
    AppPreferences.instance.breachCheckEnabled = false;
    await AppPreferences.instance.load(vaultPath);
    expect(AppPreferences.instance.breachCheckEnabled, isTrue);
  });

  testWidgets('enabling requires explicit disclosure', (tester) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(
      _host(
        service: _service(handler: (request) async => http.Response('', 200)),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Breach check'), findsOneWidget);
    expect(find.text('Enable breach check'), findsOneWidget);
    expect(find.text('Check now'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Send hash prefixes to HIBP?'), findsOneWidget);
    expect(find.textContaining('first 5 characters'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Turn on'));
    await tester.pumpAndSettle();
    expect(AppPreferences.instance.breachCheckEnabled, isTrue);
    expect(find.text('Check now'), findsOneWidget);
  });

  testWidgets('a successful check shows only titles and counts', (
    tester,
  ) async {
    AppPreferences.instance.breachCheckEnabled = true;
    final repository = _FakeRepository();
    final service = _service(
      handler: (request) async {
        return http.Response(
          '1E4C9B93F3F0682250B6CF8331B7EE68FD8:3730471',
          200,
        );
      },
    );

    await tester.pumpWidget(_host(service: service, repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Check now'));
    await tester.pumpAndSettle();

    expect(repository.beginCalls, 1);
    expect(repository.lastResponses, hasLength(1));
    expect(repository.lastResponses!.single.prefix, '5BAA6');
    expect(find.text('Mail · 7 exposures'), findsOneWidget);
    expect(find.text('Checked 1 password across 1 prefix.'), findsOneWidget);
  });

  testWidgets('the result row has no overflow at 200% text scale', (
    tester,
  ) async {
    AppPreferences.instance.breachCheckEnabled = true;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repository = _FakeRepository();
    final service = _service(
      handler: (request) async => http.Response('SUFFIX:1', 200),
    );

    await tester.pumpWidget(_host(service: service, repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Check now'));
    await tester.pumpAndSettle();

    expect(find.text('Mail · 7 exposures'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed request discards pending state and offers retry', (
    tester,
  ) async {
    AppPreferences.instance.breachCheckEnabled = true;
    final repository = _FakeRepository();
    final service = _service(
      handler: (request) async => http.Response('unavailable', 503),
    );

    await tester.pumpWidget(_host(service: service, repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Check now'));
    await tester.pumpAndSettle();

    expect(find.text('Could not reach the breach service.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(repository.cancelled, isTrue);
  });

  testWidgets('shows a running state while a range request is pending', (
    tester,
  ) async {
    AppPreferences.instance.breachCheckEnabled = true;
    final repository = _FakeRepository();
    final gate = Completer<http.Response>();
    final service = _service(handler: (request) => gate.future);

    await tester.pumpWidget(_host(service: service, repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Check now'));
    await tester.pump();

    expect(find.text('Checking…'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Checking…'),
    );
    expect(button.onPressed, isNull);

    gate.complete(http.Response('SUFFIX:1', 200));
    await tester.pumpAndSettle();
    expect(find.text('Mail · 7 exposures'), findsOneWidget);
  });

  testWidgets('turning opt-in off mid-check cancels a late result', (
    tester,
  ) async {
    AppPreferences.instance.breachCheckEnabled = true;
    final repository = _FakeRepository();
    final gate = Completer<http.Response>();
    final service = _service(handler: (request) => gate.future);

    await tester.pumpWidget(_host(service: service, repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Check now'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Turn off'));
    await tester.pumpAndSettle();

    expect(repository.cancelled, isTrue);
    expect(find.text('Enable breach check'), findsOneWidget);

    gate.complete(http.Response('SUFFIX:1', 200));
    await tester.pumpAndSettle();
    expect(find.text('Mail · 7 exposures'), findsNothing);
  });

  test('auto-lock mid-check returns to idle with no late result', () async {
    AppPreferences.instance.breachCheckEnabled = true;
    final repository = _FakeRepository();
    final gate = Completer<http.Response>();
    final service = _service(handler: (request) => gate.future);
    final container = ProviderContainer(
      overrides: [
        breachServiceProvider.overrideWithValue(service),
        vaultRepositoryProvider.overrideWithValue(repository),
        vaultSessionProvider.overrideWith(_MutableSession.new),
      ],
    );
    addTearDown(container.dispose);

    final run = container.read(breachCheckProvider.notifier).run();
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(breachCheckProvider).status,
      BreachCheckStatus.running,
    );

    (container.read(vaultSessionProvider.notifier) as _MutableSession)
        .lockNow();
    gate.complete(http.Response('SUFFIX:1', 200));
    await run;

    expect(container.read(breachCheckProvider).status, BreachCheckStatus.idle);
    expect(container.read(breachCheckProvider).report, isNull);
    expect(repository.cancelled, isTrue);
  });

  testWidgets('a locked vault refuses to start a check', (tester) async {
    AppPreferences.instance.breachCheckEnabled = true;
    final repository = _FakeRepository();
    final service = _service(
      handler: (request) async {
        return http.Response('', 200);
      },
    );

    await tester.pumpWidget(
      _host(service: service, repository: repository, locked: true),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Check now'));
    await tester.pumpAndSettle();

    expect(repository.beginCalls, 0);
    expect(find.text('Mail · 7 exposures'), findsNothing);
  });
}
