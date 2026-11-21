import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/passkeys/passkey_get_screen.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// Returns one match for the first RP and fails for any later one.
class _SwitchingRepository extends VaultRepository {
  int calls = 0;

  @override
  Future<List<EntrySummaryDto>> listPasskeysForRp(String rpId) async {
    calls++;
    if (rpId == 'example.com') {
      return [
        const EntrySummaryDto(
          id: 'old-match',
          kind: EntryKindDto.login,
          title: 'Old passkey',
          subtitle: 'ada@example.com',
          favorite: false,
          hasTotp: false,
        ),
      ];
    }
    throw StateError('lookup failed');
  }
}

Widget _host({
  required _SwitchingRepository repository,
  required String rpId,
}) => ProviderScope(
  overrides: [vaultRepositoryProvider.overrideWithValue(repository)],
  child: MaterialApp(
    theme: KeyelTheme.light(),
    home: PasskeyGetScreen(
      requestJson: '{}',
      origin: 'https://$rpId',
      rpId: rpId,
      onAsserted: (_) {},
      onCancel: () {},
    ),
  ),
);

void main() {
  testWidgets('a failed lookup clears stale matches and offers retry', (
    tester,
  ) async {
    final repository = _SwitchingRepository();
    await tester.pumpWidget(_host(repository: repository, rpId: 'example.com'));
    await tester.pumpAndSettle();

    expect(find.text('Old passkey'), findsOneWidget);
    expect(repository.calls, 1);

    // A new ceremony for another RP fails; the old row must not linger.
    await tester.pumpWidget(_host(repository: repository, rpId: 'other.com'));
    await tester.pumpAndSettle();

    expect(find.text('Old passkey'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('lookup failed'), findsOneWidget);
  });

  testWidgets('fits at 200% text scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      _host(repository: _SwitchingRepository(), rpId: 'example.com'),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Old passkey'), findsOneWidget);
  });
}
