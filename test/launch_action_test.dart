import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/core/platform/launch_action.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('keyel/platform');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('reads the initial one-tap lock action', () async {
    final methods = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      methods.add(call.method);
      return lockLaunchAction;
    });

    expect(await getInitialLaunchAction(), lockLaunchAction);
    expect(methods, <String>['getInitialAction']);
  });

  test('returns null when a normal launch has no action', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);

    expect(await getInitialLaunchAction(), isNull);
  });

  test('fails closed when the platform channel is unavailable', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => throw MissingPluginException('no implementation'),
    );

    expect(await getInitialLaunchAction(), isNull);
  });
}
