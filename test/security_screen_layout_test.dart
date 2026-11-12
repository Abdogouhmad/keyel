import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyel/data/health_provider.dart';
import 'package:keyel/features/security_dashboard/security_screen.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

HealthReportDto _report({required bool clean}) => HealthReportDto(
  score: clean ? 100 : 62,
  totalLogins: 4,
  weak: clean
      ? const []
      : const [HealthIssueDto(id: 'a', title: 'Mail', subtitle: 'ada')],
  reused: clean
      ? const []
      : const [
          ReuseGroupDto(
            entries: [
              HealthIssueDto(id: 'b', title: 'Bank', subtitle: 'ada'),
              HealthIssueDto(id: 'c', title: 'Shop', subtitle: 'ada'),
            ],
          ),
        ],
  old: const [],
  noTwoFactor: const [],
  insecureUrl: clean
      ? const []
      : const [HealthIssueDto(id: 'd', title: 'Forum', subtitle: 'ada')],
);

Widget _host(HealthReportDto report) => ProviderScope(
  overrides: [healthProvider.overrideWith((ref) => report)],
  child: MaterialApp(theme: KeyelTheme.light(), home: const SecurityScreen()),
);

void main() {
  testWidgets('security dashboard lays out on a compact phone', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(_report(clean: false)));
    await tester.pumpAndSettle();

    expect(find.text('Vulnerability summary'), findsOneWidget);
    expect(find.text('Weak passwords'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('Vulnerability audit'), findsOneWidget);
    expect(find.text('Insecure websites (HTTP)'), findsOneWidget);
    expect(find.text('Offline breach check'), findsOneWidget);
  });

  testWidgets('security dashboard shows the all-clear state', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(_report(clean: true)));
    await tester.pumpAndSettle();

    expect(find.text('Everything looks healthy'), findsOneWidget);
    expect(find.text('All clear'), findsOneWidget);
  });
}
