import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/vault/widgets/vault_entry_list.dart';
import 'package:keyel/features/vault/widgets/vault_row.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

VaultEntry _entry(int index) => VaultEntry(
  id: 'id-$index',
  title: 'Entry ${index.toString().padLeft(5, '0')}',
  kind: VaultEntryKind.login,
  icon: Icons.key_rounded,
  username: 'user$index@example.com',
);

VaultSectionConfig _config() => VaultSectionConfig(
  isWide: false,
  selectedEntryId: null,
  onOpenEntry: (entry, {required isWide}) {},
  onRefresh: () async {},
);

void main() {
  // Roadmap item 12: a 5,000-entry vault must scroll without building the
  // whole list. `SliverList.list` built every row up front; the list must stay
  // lazy so first paint and scroll frames do not scale with vault size.
  testWidgets('a 5,000-entry list builds only a window of rows', (
    tester,
  ) async {
    final entries = List<VaultEntry>.generate(5_000, _entry);
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: KeyelTheme.light(),
          home: Scaffold(
            body: CustomScrollView(
              controller: controller,
              slivers: [VaultEntryList(entries: entries, config: _config())],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Entry 00000'), findsOneWidget);
    // A viewport plus cache extent holds a few dozen rows at most.
    expect(find.byType(VaultRow).evaluate().length, lessThan(200));

    // Scrolling down builds the next window, still not the whole list.
    controller.jumpTo(3_000);
    await tester.pump();

    expect(find.text('Entry 00000'), findsNothing);
    expect(find.byType(VaultRow).evaluate().length, lessThan(200));
  });
}
