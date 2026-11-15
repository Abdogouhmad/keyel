import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/core/platform/sensitive_clipboard.dart';
import 'package:keyel/data/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
    AppPreferences.instance.clipboardClearSeconds = 30;
    SensitiveClipboard.instance.cancel();
  });

  tearDown(() {
    SensitiveClipboard.instance.cancel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('clears the clipboard after the configured delay', (
    tester,
  ) async {
    await SensitiveClipboard.instance.copy('secret');

    expect(calls, hasLength(1));
    expect(calls.single.method, 'Clipboard.setData');
    expect((calls.single.arguments as Map<Object?, Object?>)['text'], 'secret');

    // Nothing happens before the deadline.
    await tester.pump(const Duration(seconds: 29));
    expect(calls, hasLength(1));

    // The timer fires and wipes the clipboard.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(calls, hasLength(2));
    expect((calls.last.arguments as Map<Object?, Object?>)['text'], '');
  });

  testWidgets('never clears the clipboard when the delay is zero', (
    tester,
  ) async {
    AppPreferences.instance.clipboardClearSeconds = 0;

    await SensitiveClipboard.instance.copy('secret');
    await tester.pump(const Duration(minutes: 5));

    expect(calls, hasLength(1));
  });

  testWidgets('a newer copy replaces the pending wipe', (tester) async {
    await SensitiveClipboard.instance.copy('first');
    await tester.pump(const Duration(seconds: 20));
    await SensitiveClipboard.instance.copy('second');
    await tester.pump(const Duration(seconds: 20));

    // Only the first copy's timer would have fired at t=30s; it was cancelled.
    expect(calls, hasLength(2));
    expect((calls.last.arguments as Map<Object?, Object?>)['text'], 'second');

    await tester.pump(const Duration(seconds: 10));
    await tester.pump();
    expect(calls, hasLength(3));
    expect((calls.last.arguments as Map<Object?, Object?>)['text'], '');
  });

  group('clearHint', () {
    test('reflects the configured delay instead of hardcoding 30s', () {
      AppPreferences.instance.clipboardClearSeconds = 15;
      expect(SensitiveClipboard.instance.clearHint, ' • Clears in 15s');

      AppPreferences.instance.clipboardClearSeconds = 30;
      expect(SensitiveClipboard.instance.clearHint, ' • Clears in 30s');

      AppPreferences.instance.clipboardClearSeconds = 60;
      expect(SensitiveClipboard.instance.clearHint, ' • Clears in 1 min');
    });

    test('is empty when the clipboard never clears', () {
      AppPreferences.instance.clipboardClearSeconds = 0;
      expect(SensitiveClipboard.instance.clearHint, isEmpty);
    });
  });
}
