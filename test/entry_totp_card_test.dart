import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/features/entry/widgets/detail/totp_card.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

Widget _host(Widget child) => MaterialApp(
  theme: KeyelTheme.light(),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

TotpCodeDto _code(String value) =>
    TotpCodeDto(code: value, secondsLeft: 20, period: 30);

void main() {
  testWidgets('backgrounding masks the code and discards a late refresh', (
    tester,
  ) async {
    final first = Completer<TotpCodeDto>();
    final second = Completer<TotpCodeDto>();
    final futures = <Future<TotpCodeDto>>[first.future, second.future];
    var calls = 0;

    await tester.pumpWidget(
      _host(
        EntryTotpCard(
          entryId: 'entry',
          onCopy: (_, _) {},
          loadCode: (_) => futures[calls++],
        ),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    first.complete(_code('123456'));
    await tester.pump();

    expect(find.text('123'), findsNothing);
    expect(find.text('456'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    second.complete(_code('654321'));
    await tester.pump();

    expect(find.text('654'), findsOneWidget);
    expect(find.text('321'), findsOneWidget);
  });

  testWidgets('an expired code is cleared at rollover while refreshing', (
    tester,
  ) async {
    final first = Completer<TotpCodeDto>()..complete(_code('123456'));
    final second = Completer<TotpCodeDto>();
    final futures = <Future<TotpCodeDto>>[first.future, second.future];
    var calls = 0;
    var clock = DateTime(2026, 1, 1, 12);

    await tester.pumpWidget(
      _host(
        EntryTotpCard(
          entryId: 'entry',
          onCopy: (_, _) {},
          loadCode: (_) => futures[calls++],
          now: () => clock,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('123'), findsOneWidget);

    // Cross a period boundary. The refresh is held open, so the old code must
    // not remain visible or copyable while the new one is in flight.
    clock = clock.add(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('123'), findsNothing);
    expect(find.text('456'), findsNothing);
  });
}
