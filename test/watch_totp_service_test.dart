import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/core/wear/wear_totp_bridge.dart';
import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/features/wear/watch_totp_service.dart';
import 'package:keyel/src/rust/api/models.dart';

class _FakeRepository extends VaultRepository {
  EntryDetailDto? detail;
  String secret = 'JBSWY3DPEHPK3PXP';
  int reveals = 0;

  @override
  Future<EntryDetailDto> getEntry(String id) async => detail!;

  @override
  Future<String> revealField(String id, SecretFieldDto field) async {
    reveals++;
    return secret;
  }
}

class _FakeBridge extends WearTotpBridge {
  new() : super();

  Map<String, Object?>? pushed;
  String? removed;
  int clears = 0;

  @override
  Future<bool> get available async => true;

  @override
  Future<bool> push({
    required String id,
    required String label,
    required String secret,
    required String algorithm,
    required int digits,
    required int period,
  }) async {
    pushed = {
      'id': id,
      'label': label,
      'secret': secret,
      'algorithm': algorithm,
      'digits': digits,
      'period': period,
    };
    return true;
  }

  @override
  Future<bool> remove(String id) async {
    removed = id;
    return true;
  }

  @override
  Future<bool> clear() async {
    clears++;
    return true;
  }
}

EntryDetailDto _detail({LoginDetailDto? login}) => EntryDetailDto(
  id: 'entry-1',
  kind: EntryKindDto.login,
  title: 'Mail',
  tags: const [],
  favorite: false,
  createdAt: BigInt.zero,
  updatedAt: BigInt.zero,
  hasNotes: false,
  login: login,
  customFields: const [],
);

void main() {
  test('pushEntry sends an unlocked secret with its TOTP parameters', () async {
    final repository = _FakeRepository()
      ..detail = _detail(
        login: const LoginDetailDto(
          username: 'a@example.com',
          url: '',
          hasPassword: true,
          passwordHistoryCount: 0,
          totpAlgorithm: TotpAlgorithmDto.sha256,
          totpDigits: 8,
          totpPeriod: 60,
        ),
      );
    final bridge = _FakeBridge();
    final service = WatchTotpService(repository: repository, bridge: bridge);

    expect(await service.pushEntry('entry-1'), isTrue);
    expect(repository.reveals, 1);
    expect(bridge.pushed, {
      'id': 'entry-1',
      'label': 'Mail',
      'secret': 'JBSWY3DPEHPK3PXP',
      'algorithm': 'sha256',
      'digits': 8,
      'period': 60,
    });
  });

  test('pushEntry refuses an entry without a TOTP config', () async {
    final repository = _FakeRepository()
      ..detail = _detail(
        login: const LoginDetailDto(
          username: 'a@example.com',
          url: '',
          hasPassword: true,
          passwordHistoryCount: 0,
        ),
      );
    final bridge = _FakeBridge();
    final service = WatchTotpService(repository: repository, bridge: bridge);

    expect(await service.pushEntry('entry-1'), isFalse);
    expect(repository.reveals, 0);
    expect(bridge.pushed, isNull);
  });

  test(
    'revocation delegates to the bridge without reading the vault',
    () async {
      final repository = _FakeRepository();
      final bridge = _FakeBridge();
      final service = WatchTotpService(repository: repository, bridge: bridge);

      expect(await service.removeFromWatch('entry-1'), isTrue);
      expect(await service.clearWatch(), isTrue);
      expect(bridge.removed, 'entry-1');
      expect(bridge.clears, 1);
      expect(repository.reveals, 0);
    },
  );
}
