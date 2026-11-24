import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keyel/core/ota/ota_models.dart';
import 'package:keyel/core/ota/ota_provider.dart';
import 'package:keyel/core/ota/ota_service.dart';
import 'package:keyel/core/platform/update_notifications.dart';
import 'package:keyel/data/app_preferences.dart';

/// Simulates a download that bypassed the service's checksum gate, so the
/// provider-level refusal can be asserted independently.
class _UnverifiedOtaService extends OtaService {
  new() : super(client: MockClient((_) async => http.Response('[]', 200)));

  int installCalls = 0;

  @override
  Future<OtaRelease?> checkForUpdate({
    required String currentVersion,
    OtaChannel channel = OtaChannel.stable,
  }) async {
    return OtaRelease(
      version: '9.9.9',
      tagName: 'v9.9.9',
      title: 'Unverified update',
      releaseNotes: '',
      publishedAt: DateTime(2026),
      downloadUrl: 'https://example.com/app.apk',
      fileName: 'app.apk',
      fileSize: 1,
    );
  }

  @override
  Future<File> downloadRelease(
    OtaRelease release, {
    OtaDownloadProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final file = File('${Directory.systemTemp.path}/keyel-unverified-test.apk');
    await file.writeAsBytes(const [1, 2, 3]);
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });
    return file;
  }

  @override
  Future<bool> canInstallPackages() async => true;

  @override
  Future<bool> installApk(String filePath) async {
    installCalls++;
    return true;
  }
}

/// A service whose download starts valid but can be tampered with before the
/// provider's last-moment re-verification.
class _TamperableOtaService extends OtaService {
  new(this._bytes)
    : super(client: MockClient((_) async => http.Response('[]', 200)));

  final List<int> _bytes;
  String? path;
  int installCalls = 0;

  /// Runs during the permission check, before the last-moment re-hash.
  Future<void> Function()? permissionHook;

  @override
  Future<OtaRelease?> checkForUpdate({
    required String currentVersion,
    OtaChannel channel = OtaChannel.stable,
  }) async {
    return OtaRelease(
      version: '9.9.9',
      tagName: 'v9.9.9',
      title: 'Verified update',
      releaseNotes: '',
      publishedAt: DateTime(2026),
      downloadUrl: 'https://example.com/app.apk',
      fileName: 'app.apk',
      fileSize: _bytes.length,
      sha256: sha256.convert(_bytes).toString(),
    );
  }

  @override
  Future<File> downloadRelease(
    OtaRelease release, {
    OtaDownloadProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final file = File('${Directory.systemTemp.path}/keyel-reverify-test.apk');
    await file.writeAsBytes(_bytes);
    path = file.path;
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });
    return file;
  }

  @override
  Future<bool> canInstallPackages() async {
    final hook = permissionHook;
    if (hook != null) await hook();
    return true;
  }

  @override
  Future<bool> installApk(String filePath) async {
    installCalls++;
    return true;
  }
}

/// Client that reports a different final URL than the one requested, simulating
/// an HTTPS manifest URL redirected to plain HTTP. `MockClient` can only return
/// a `Response`, which has no `request` field, so `send()` is overridden here.
class _FinalUrlClient extends http.BaseClient {
  new(this.finalUrl);

  final Uri finalUrl;
  int requests = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests++;
    return http.StreamedResponse(
      Stream<List<int>>.value(const [1, 2, 3]),
      200,
      request: http.Request('GET', finalUrl),
    );
  }
}

/// Notification adapter that records posts without touching the platform.
class _FakeUpdateNotifications extends UpdateNotificationPlatform {
  bool enabled = false;
  int permissionRequests = 0;
  final List<String> postedVersions = <String>[];

  @override
  Future<bool> areNotificationsEnabled() async => enabled;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    enabled = true;
    return true;
  }

  @override
  Future<bool> showUpdateAvailable({
    required String version,
    required String channel,
  }) async {
    postedVersions.add(version);
    return true;
  }
}

void main() {
  setUp(() {
    AppPreferences.instance
      ..otaChannel = 'stable'
      ..otaAutoCheck = true
      ..otaLastCheckedMs = null
      ..otaLastNotifiedVersion = null
      ..otaDismissedVersion = null
      ..otaNotificationPromptShown = false;
  });

  group('OTA Semver Comparison', () {
    test('compareVersions accurately orders semver strings', () {
      expect(compareVersions('1.1.0', '1.0.0'), greaterThan(0));
      expect(compareVersions('1.0.0', '1.1.0'), lessThan(0));
      expect(compareVersions('1.0.0', '1.0.0'), equals(0));
      expect(compareVersions('v1.2.0', '1.1.9'), greaterThan(0));
      expect(compareVersions('1.1.0+2', '1.1.0+1'), equals(0));
      expect(compareVersions('2.0.0', '1.99.99'), greaterThan(0));
      expect(compareVersions('1.0.1', '1.0.0'), greaterThan(0));
    });

    test(
      'pre-releases sort below their final version but above older ones',
      () {
        expect(compareVersions('1.9.0', '1.9.0-beta.1'), greaterThan(0));
        expect(compareVersions('1.9.0-beta.1', '1.9.0'), lessThan(0));
        expect(compareVersions('1.9.0-beta.2', '1.9.0-beta.1'), greaterThan(0));
        expect(
          compareVersions('1.9.0-beta.10', '1.9.0-beta.2'),
          greaterThan(0),
        );
        expect(
          compareVersions('1.9.0-beta.1', '1.9.0-alpha.9'),
          greaterThan(0),
        );
        expect(compareVersions('1.9.0-beta.1', '1.8.9'), greaterThan(0));
        expect(compareVersions('v1.9.0-beta.1+42', '1.9.0-beta.1'), equals(0));
      },
    );
  });

  group('OTA Models', () {
    test('OtaRelease formats file sizes correctly', () {
      final r1 = OtaRelease(
        version: '1.1.0',
        tagName: 'v1.1.0',
        title: 'Keyel 1.1.0',
        releaseNotes: 'OTA release',
        publishedAt: DateTime(2026, 11, 16),
        downloadUrl: 'https://example.com/app.apk',
        fileName: 'keyel.apk',
        fileSize: 500,
      );
      expect(r1.formattedSize, equals('500 B'));

      final r2 = OtaRelease(
        version: '1.1.0',
        tagName: 'v1.1.0',
        title: 'Keyel 1.1.0',
        releaseNotes: 'OTA release',
        publishedAt: DateTime(2026, 11, 16),
        downloadUrl: 'https://example.com/app.apk',
        fileName: 'keyel.apk',
        fileSize: 2048 * 1024,
      );
      expect(r2.formattedSize, equals('2.0 MB'));
    });

    test('OtaState getters identify lifecycle steps', () {
      const stateIdle = OtaState(currentVersion: '1.0.0');
      expect(stateIdle.isChecking, isFalse);
      expect(stateIdle.isDownloading, isFalse);
      expect(stateIdle.hasUpdate, isFalse);

      final stateChecking = stateIdle.copyWith(step: OtaStep.checking);
      expect(stateChecking.isChecking, isTrue);

      final release = OtaRelease(
        version: '1.1.0',
        tagName: 'v1.1.0',
        title: '1.1.0',
        releaseNotes: 'notes',
        publishedAt: DateTime(2026),
        downloadUrl: 'https://example.com/app.apk',
        fileName: 'app.apk',
        fileSize: 1000,
      );

      final stateAvailable = stateIdle.copyWith(
        step: OtaStep.available,
        availableRelease: () => release,
      );
      expect(stateAvailable.hasUpdate, isTrue);
      expect(stateAvailable.isReadyToInstall, isFalse);

      final stateDownloaded = stateAvailable.copyWith(
        step: OtaStep.downloaded,
        downloadedFilePath: () => '/tmp/app.apk',
        isChecksumVerified: true,
      );
      expect(stateDownloaded.isReadyToInstall, isTrue);
      expect(
        stateDownloaded.copyWith(isChecksumVerified: false).isReadyToInstall,
        isFalse,
      );
    });
  });

  group('OtaService', () {
    final mockGithubResponse = [
      {
        'tag_name': 'v1.2.0',
        'name': 'Keyel 1.2.0 Beta',
        'body': 'SHA256: 1111111111111111111111111111111111111111111111111111111111111111\nRelease notes',
        'prerelease': true,
        'published_at': '2026-11-16T12:00:00Z',
        'assets': [
          {
            'name': 'keyel-v1.2.0-universal.apk',
            'browser_download_url': 'https://example.com/v1.2.0.apk',
            'size': 18000000,
          },
        ],
      },
      {
        'tag_name': 'v1.1.0',
        'name': 'Keyel 1.1.0 Stable',
        'body': 'SHA256: 2222222222222222222222222222222222222222222222222222222222222222\nStable update',
        'prerelease': false,
        'published_at': '2026-11-15T12:00:00Z',
        'assets': [
          {
            'name': 'keyel-v1.1.0-universal.apk',
            'browser_download_url': 'https://example.com/v1.1.0.apk',
            'size': 17500000,
          },
        ],
      },
    ];

    test('checkForUpdate filters pre-releases in stable channel', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(mockGithubResponse), 200);
      });

      final service = OtaService(client: mockClient);

      // On stable channel: should skip v1.2.0 (prerelease) and select v1.1.0
      final stableUpdate = await service.checkForUpdate(
        currentVersion: '1.0.0',
      );
      expect(stableUpdate, isNotNull);
      expect(stableUpdate!.version, equals('1.1.0'));
      expect(stableUpdate.isPrerelease, isFalse);
      expect(
        stableUpdate.sha256,
        equals(
          '2222222222222222222222222222222222222222222222222222222222222222',
        ),
      );

      // On beta channel: should pick the newest release v1.2.0
      final betaUpdate = await service.checkForUpdate(
        currentVersion: '1.0.0',
        channel: OtaChannel.beta,
      );
      expect(betaUpdate, isNotNull);
      expect(betaUpdate!.version, equals('1.2.0'));
      expect(betaUpdate.isPrerelease, isTrue);

      // Already on newest version: should return null
      final upToDate = await service.checkForUpdate(
        currentVersion: '1.2.0',
        channel: OtaChannel.beta,
      );
      expect(upToDate, isNull);
    });

    test('reads the committed OTA manifest (sha256, size and notes)', () async {
      final manifestSha = List.filled(64, 'a').join();

      final mockClient = MockClient((request) async {
        // Stable channel reads the committed manifest on raw.githubusercontent.
        expect(request.url.path, endsWith('/update_manifest.json'));
        return http.Response(
          jsonEncode({
            'latestVersionName': '1.2.0',
            'latestVersionCode': 10200,
            'minSupportedVersionCode': 10000,
            'mandatory': false,
            'apkUrl':
                'https://github.com/Abdogouhmad/keyel/releases/download/'
                'v1.2.0/keyel-v1.2.0-universal.apk',
            'size': 12345678,
            'sha256': manifestSha,
            'releaseNotes': '## [1.2.0]\n\nNotes',
            'publishedAt': '2026-11-18T00:00:00Z',
          }),
          200,
        );
      });

      final service = OtaService(client: mockClient);
      final update = await service.checkForUpdate(currentVersion: '1.1.0');

      expect(update, isNotNull);
      expect(update!.version, equals('1.2.0'));
      expect(update.tagName, equals('v1.2.0'));
      expect(update.downloadUrl, endsWith('keyel-v1.2.0-universal.apk'));
      expect(update.fileName, equals('keyel-v1.2.0-universal.apk'));
      expect(update.fileSize, equals(12345678));
      expect(update.sha256, equals(manifestSha));
      expect(update.releaseNotes, contains('[1.2.0]'));
      expect(update.isPrerelease, isFalse);

      // Already on the manifest's version: nothing to do.
      expect(await service.checkForUpdate(currentVersion: '1.2.0'), isNull);
    });

    test('beta channel reads its own manifest and marks prereleases', () async {
      final betaSha = List.filled(64, 'b').join();
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/update_manifest_beta.json'));
        expect(request.url.queryParameters['ts'], isNotEmpty);
        return http.Response(
          jsonEncode({
            'channel': 'beta',
            'isPrerelease': true,
            'latestVersionName': '1.9.0-beta.1',
            'latestVersionCode': 10900,
            'apkUrl': 'https://example.com/keyel-v1.9.0-beta.1-universal.apk',
            'size': 1234,
            'sha256': betaSha,
            'releaseNotes': 'Beta preview',
            'publishedAt': '2026-11-20T00:00:00Z',
          }),
          200,
        );
      });

      final service = OtaService(client: mockClient);
      final update = await service.checkForUpdate(
        currentVersion: '1.8.2',
        channel: OtaChannel.beta,
      );

      expect(update, isNotNull);
      expect(update!.version, equals('1.9.0-beta.1'));
      expect(update.isPrerelease, isTrue);
      expect(update.versionCode, equals(10900));
      expect(update.sha256, equals(betaSha));
    });

    test('an empty beta manifest yields no update', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'channel': 'beta',
            'isPrerelease': true,
            'latestVersionName': '',
            'apkUrl': '',
            'sha256': '',
          }),
          200,
        );
      });
      final service = OtaService(client: mockClient);
      expect(
        await service.checkForUpdate(
          currentVersion: '1.8.2',
          channel: OtaChannel.beta,
        ),
        isNull,
      );
    });
  });

  group('OtaNotifier', () {
    test('state transitions through check lifecycle', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'tag_name': 'v1.2.0',
              'name': 'Keyel 1.2.0',
              'body': 'SHA256: ${List.filled(64, '3').join()}\nNotes',
              'prerelease': false,
              'published_at': '2026-11-16T00:00:00Z',
              'assets': [
                {
                  'name': 'keyel.apk',
                  'browser_download_url': 'https://example.com/keyel.apk',
                  'size': 1000,
                },
              ],
            },
          ]),
          200,
        );
      });

      final service = OtaService(client: mockClient);
      final container = ProviderContainer(
        overrides: [otaServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(otaProvider.notifier);
      expect(container.read(otaProvider).step, equals(OtaStep.idle));

      await notifier.checkForUpdates();

      expect(container.read(otaProvider).step, equals(OtaStep.available));
      expect(
        container.read(otaProvider).availableRelease?.version,
        equals('1.2.0'),
      );
      expect(container.read(otaProvider).lastChecked, isNotNull);

      await notifier.setChannel(OtaChannel.beta);
      expect(container.read(otaProvider).channel, equals(OtaChannel.beta));

      await notifier.setAutoCheck(enabled: false);
      expect(container.read(otaProvider).autoCheck, isFalse);
    });

    test(
      'silent checks notify once per version and persist preferences',
      () async {
        final sha = List.filled(64, 'c').join();
        final service = OtaService(
          client: MockClient((request) async {
            return http.Response(
              jsonEncode({
                'latestVersionName': '2.0.0',
                'apkUrl': 'https://example.com/keyel-v2.0.0-universal.apk',
                'size': 1234,
                'sha256': sha,
                'releaseNotes': 'Next',
                'publishedAt': '2026-11-20T00:00:00Z',
              }),
              200,
            );
          }),
        );
        final notifications = _FakeUpdateNotifications();
        final container = ProviderContainer(
          overrides: [
            otaServiceProvider.overrideWithValue(service),
            updateNotificationProvider.overrideWithValue(notifications),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(otaProvider.notifier);
        await notifier.checkForUpdates(userInitiated: false);

        expect(container.read(otaProvider).step, equals(OtaStep.available));
        expect(notifications.postedVersions, equals(['2.0.0']));
        expect(AppPreferences.instance.otaLastNotifiedVersion, equals('2.0.0'));
        expect(AppPreferences.instance.otaLastCheckedMs, isNotNull);

        await notifier.checkForUpdates(userInitiated: false);
        expect(
          notifications.postedVersions,
          equals(['2.0.0']),
          reason: 'the same version must not notify twice',
        );
      },
    );

    test('a failed silent check stays quiet', () async {
      final service = OtaService(
        client: MockClient((request) async => throw StateError('offline')),
      );
      final container = ProviderContainer(
        overrides: [otaServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);

      await container
          .read(otaProvider.notifier)
          .checkForUpdates(userInitiated: false);

      expect(container.read(otaProvider).step, equals(OtaStep.idle));
      expect(container.read(otaProvider).errorMessage, isNull);
      expect(container.read(otaProvider).lastChecked, isNotNull);
    });

    test(
      'channel, auto-check and banner dismissal survive a rebuild',
      () async {
        final service = OtaService(
          client: MockClient((request) async {
            return http.Response(
              jsonEncode({
                'latestVersionName': '3.0.0',
                'apkUrl': 'https://example.com/keyel-v3.0.0-universal.apk',
                'size': 1234,
                'sha256': List.filled(64, 'd').join(),
                'releaseNotes': 'Next',
                'publishedAt': '2026-11-20T00:00:00Z',
              }),
              200,
            );
          }),
        );
        final notifications = _FakeUpdateNotifications();
        final container = ProviderContainer(
          overrides: [
            otaServiceProvider.overrideWithValue(service),
            updateNotificationProvider.overrideWithValue(notifications),
          ],
        );

        final notifier = container.read(otaProvider.notifier);
        await notifier.setChannel(OtaChannel.beta);
        await notifier.setAutoCheck(enabled: true);
        await notifier.checkForUpdates();
        await notifier.dismissUpdateBanner();

        expect(AppPreferences.instance.otaChannel, equals('beta'));
        expect(AppPreferences.instance.otaAutoCheck, isTrue);
        expect(notifications.permissionRequests, equals(1));
        expect(AppPreferences.instance.otaDismissedVersion, equals('3.0.0'));

        container.dispose();
        final restored = ProviderContainer(
          overrides: [
            otaServiceProvider.overrideWithValue(service),
            updateNotificationProvider.overrideWithValue(notifications),
          ],
        );
        addTearDown(restored.dispose);

        final state = restored.read(otaProvider);
        expect(state.channel, equals(OtaChannel.beta));
        expect(state.autoCheck, isTrue);
        expect(state.dismissedVersion, equals('3.0.0'));
      },
    );
  });

  group('OtaService checksum verification', () {
    test('accepts a matching SHA-256 and rejects a mismatch', () async {
      final dir = Directory.systemTemp.createTempSync('keyel_ota_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/app.apk');
      await file.writeAsBytes(const [1, 2, 3, 4, 5]);

      final service = OtaService();
      const expected =
          '74f81fe167d99b4cb41d6d0ccda82278caee9f3e2f25d5e5a3936ff3dcec60d0';

      expect(await service.verifyFileChecksum(file, expected), isTrue);
      expect(
        await service.verifyFileChecksum(file, expected.toUpperCase()),
        isTrue,
      );
      expect(
        await service.verifyFileChecksum(
          file,
          '0000000000000000000000000000000000000000000000000000000000000000',
        ),
        isFalse,
      );
    });

    test(
      'manifest and beta releases without a checksum are not offered',
      () async {
        final manifestClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'latestVersionName': '9.9.9',
              'apkUrl': 'https://example.com/app.apk',
              'size': 100,
            }),
            200,
          );
        });
        final manifestService = OtaService(client: manifestClient);
        expect(
          await manifestService.checkForUpdate(currentVersion: '1.0.0'),
          isNull,
        );

        final betaClient = MockClient((request) async {
          return http.Response(
            jsonEncode([
              {
                'tag_name': 'v9.9.9',
                'name': 'No checksum',
                'body': 'Release notes without a hash',
                'prerelease': true,
                'published_at': '2026-11-16T12:00:00Z',
                'assets': [
                  {
                    'name': 'app.apk',
                    'browser_download_url': 'https://example.com/app.apk',
                    'size': 100,
                  },
                ],
              },
            ]),
            200,
          );
        });
        final betaService = OtaService(client: betaClient);
        expect(
          await betaService.checkForUpdate(
            currentVersion: '1.0.0',
            channel: OtaChannel.beta,
          ),
          isNull,
        );
      },
    );

    test('downloadRelease refuses a release with no checksum', () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return http.Response('apk', 200);
      });
      final service = OtaService(client: client);
      final release = OtaRelease(
        version: '9.9.9',
        tagName: 'v9.9.9',
        title: 'Unverified',
        releaseNotes: '',
        publishedAt: DateTime(2026),
        downloadUrl: 'https://example.com/app.apk',
        fileName: 'app.apk',
        fileSize: 3,
      );

      await expectLater(service.downloadRelease(release), throwsStateError);
      expect(requests, 0);
    });

    test('downloadRelease refuses a non-HTTPS URL', () async {
      var requests = 0;
      final service = OtaService(
        client: MockClient((request) async {
          requests++;
          return http.Response('apk', 200);
        }),
      );
      final release = OtaRelease(
        version: '9.9.9',
        tagName: 'v9.9.9',
        title: 'Insecure',
        releaseNotes: '',
        publishedAt: DateTime(2026),
        downloadUrl: 'http://example.com/app.apk',
        fileName: 'app.apk',
        fileSize: 3,
        sha256: sha256.convert(const [1, 2, 3]).toString(),
      );

      await expectLater(service.downloadRelease(release), throwsStateError);
      expect(requests, 0);
    });

    test('downloadRelease refuses an HTTPS URL redirected to HTTP', () async {
      final client = _FinalUrlClient(Uri.parse('http://example.com/app.apk'));
      final service = OtaService(client: client);
      final release = OtaRelease(
        version: '9.9.9',
        tagName: 'v9.9.9',
        title: 'Redirected',
        releaseNotes: '',
        publishedAt: DateTime(2026),
        downloadUrl: 'https://example.com/app.apk',
        fileName: 'app.apk',
        fileSize: 3,
        sha256: sha256.convert(const [1, 2, 3]).toString(),
      );

      await expectLater(service.downloadRelease(release), throwsStateError);
      expect(client.requests, 1);
    });

    test(
      'provider re-verifies the file immediately before installing',
      () async {
        final service = _TamperableOtaService(const [1, 2, 3]);
        final container = ProviderContainer(
          overrides: [otaServiceProvider.overrideWithValue(service)],
        );
        addTearDown(container.dispose);
        final notifier = container.read(otaProvider.notifier);

        await notifier.checkForUpdates();
        await notifier.startDownload();
        expect(container.read(otaProvider).isChecksumVerified, isTrue);

        // A local file can be swapped between download and install.
        await File(service.path!).writeAsBytes(const [9, 9, 9]);
        expect(await notifier.installUpdate(), isFalse);

        expect(service.installCalls, 0);
        expect(File(service.path!).existsSync(), isFalse);
        final state = container.read(otaProvider);
        expect(state.step, OtaStep.error);
        expect(state.isChecksumVerified, isFalse);
        expect(state.downloadedFilePath, isNull);
      },
    );

    test(
      'a file swapped while asking for install permission is rejected',
      () async {
        final service = _TamperableOtaService(const [1, 2, 3]);
        final container = ProviderContainer(
          overrides: [otaServiceProvider.overrideWithValue(service)],
        );
        addTearDown(container.dispose);
        final notifier = container.read(otaProvider.notifier);

        await notifier.checkForUpdates();
        await notifier.startDownload();
        service.permissionHook = () async {
          await File(service.path!).writeAsBytes(const [9, 9, 9]);
        };

        expect(await notifier.installUpdate(), isFalse);
        expect(service.installCalls, 0);
        expect(File(service.path!).existsSync(), isFalse);
      },
    );

    test('provider refuses to install an unverified download', () async {
      final service = _UnverifiedOtaService();
      final container = ProviderContainer(
        overrides: [otaServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(otaProvider.notifier);

      await notifier.checkForUpdates();
      await notifier.startDownload();

      expect(container.read(otaProvider).isChecksumVerified, isFalse);
      expect(await notifier.installUpdate(), isFalse);
      expect(service.installCalls, 0);
      expect(container.read(otaProvider).errorMessage, contains('checksum'));
    });
  });
}
