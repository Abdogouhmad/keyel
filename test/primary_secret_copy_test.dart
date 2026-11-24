import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/core/platform/sensitive_clipboard.dart';
import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/features/entry/models/entry_icon.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/vault/primary_secret_copy.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Repository with scripted reveal results, so precedence can be asserted
/// without a live Rust bridge.
class _ScriptedRepository extends VaultRepository {
  new(this._reveals);

  final Map<SecretFieldDto, String> _reveals;
  final revealed = <SecretFieldDto>[];

  @override
  Future<String> revealField(String id, SecretFieldDto field) async {
    revealed.add(field);
    return _reveals[field] ?? '';
  }
}

VaultEntry _login({String username = '', String password = ''}) => VaultEntry(
  id: 'entry-1',
  title: 'Example',
  kind: VaultEntryKind.login,
  icon: resolveEntryIcon(''),
  username: username,
  password: password,
);

VaultEntry _card() => VaultEntry(
  id: 'entry-2',
  title: 'Card',
  kind: VaultEntryKind.card,
  icon: resolveEntryIcon('', VaultEntryKind.card),
);

void main() {
  final l10n = localizationsFor('en');

  test('login copies the revealed password before a stored username', () async {
    final repo = _ScriptedRepository({SecretFieldDto.loginPassword: 's3cret'});

    final result = await PrimarySecretCopy.resolve(
      _login(username: 'alice@example.com'),
      repository: repo,
      l10n: l10n,
    );

    expect(result.kind, PrimarySecretKind.password);
    expect(result.value, 's3cret');
    expect(result.message, contains(l10n.vaultCopiedPassword));
    expect(repo.revealed, [SecretFieldDto.loginPassword]);
  });

  test(
    'login falls back to the username when no password is revealed',
    () async {
      final repo = _ScriptedRepository(const {});

      final result = await PrimarySecretCopy.resolve(
        _login(username: 'alice@example.com'),
        repository: repo,
        l10n: l10n,
      );

      expect(result.kind, PrimarySecretKind.username);
      expect(result.value, 'alice@example.com');
      expect(result.message, l10n.vaultCopiedUsername);
    },
  );

  test('login with neither password nor username copies nothing', () async {
    final repo = _ScriptedRepository(const {});

    final result = await PrimarySecretCopy.resolve(
      _login(),
      repository: repo,
      l10n: l10n,
    );

    expect(result.kind, PrimarySecretKind.none);
    expect(result.hasValue, isFalse);
    expect(result.value, isNull);
    expect(result.message, l10n.vaultNothingToCopy);
  });

  test('card copies the revealed number and never the username', () async {
    final repo = _ScriptedRepository({
      SecretFieldDto.cardNumber: '4111111111111111',
    });

    final result = await PrimarySecretCopy.resolve(
      _card(),
      repository: repo,
      l10n: l10n,
    );

    expect(result.kind, PrimarySecretKind.cardNumber);
    expect(result.value, '4111111111111111');
    expect(
      result.message,
      '${l10n.vaultCopiedCardNumber}${SensitiveClipboard.instance.clearHint}',
    );
    expect(repo.revealed, [SecretFieldDto.cardNumber]);
  });

  test('note and passkey entries never reach the repository', () async {
    final repo = _ScriptedRepository(const {});
    for (final kind in [VaultEntryKind.note, VaultEntryKind.passkey]) {
      final result = await PrimarySecretCopy.resolve(
        VaultEntry(
          id: 'x',
          title: 'x',
          kind: kind,
          icon: resolveEntryIcon('', kind),
        ),
        repository: repo,
        l10n: l10n,
      );
      expect(result.kind, PrimarySecretKind.none);
      expect(result.hasValue, isFalse);
    }
    expect(repo.revealed, isEmpty);
  });
}
