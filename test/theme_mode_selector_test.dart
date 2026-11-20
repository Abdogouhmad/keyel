import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/features/settings/widgets/appearance_widgets.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

Widget _host({
  required ThemeMode selected,
  required ValueChanged<ThemeMode> onChanged,
  bool disableAnimations = false,
}) => MaterialApp(
  theme: KeyelTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(
      body: SingleChildScrollView(
        child: ThemeModeSelector(selected: selected, onChanged: onChanged),
      ),
    ),
  ),
);

void main() {
  testWidgets('shows all three modes with their own explanation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(selected: ThemeMode.system, onChanged: (_) {}),
    );

    for (final mode in ThemeMode.values) {
      expect(
        find.text(switch (mode) {
          ThemeMode.system => 'System',
          ThemeMode.light => 'Light',
          ThemeMode.dark => 'Dark',
        }),
        findsOneWidget,
      );
    }
    expect(
      find.text('Follows your device appearance and changes along with it.'),
      findsOneWidget,
    );
    expect(
      find.text('Stays light even when your device uses dark mode.'),
      findsOneWidget,
    );
    expect(
      find.text('Stays dark even when your device uses light mode.'),
      findsOneWidget,
    );
    expect(find.text('Device is currently light'), findsOneWidget);
  });

  testWidgets('reports and changes the selected mode', (tester) async {
    final changes = <ThemeMode>[];
    await tester.pumpWidget(
      _host(selected: ThemeMode.light, onChanged: changes.add),
    );

    final dark = find.bySemanticsLabel(RegExp('Dark theme'));
    expect(dark, findsOneWidget);
    expect(tester.widget<Semantics>(dark).properties.selected, isFalse);

    await tester.ensureVisible(dark);
    await tester.tap(dark);
    await tester.pump();
    expect(changes, [ThemeMode.dark]);
  });

  testWidgets('collapses the selection transition under reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        selected: ThemeMode.system,
        onChanged: (_) {},
        disableAnimations: true,
      ),
    );

    for (final container in tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    )) {
      expect(container.duration, Duration.zero);
    }
  });
}
