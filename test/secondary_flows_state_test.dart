import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/folders_provider.dart';
import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/folders/folders_screen.dart';
import 'package:keyel/features/trash/trash_screen.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

class _EmptyVaultRepository extends VaultRepository {
  new();

  @override
  bool get isUnlocked => true;

  @override
  Future<List<EntrySummaryDto>> listEntries({
    String query = '',
    EntryKindDto? kind,
    bool? favorite,
    bool includeDeleted = false,
  }) async => const [];

  @override
  Future<List<FolderDto>> listFolders() async => const [];
}

Widget _app(Widget child, {bool disableAnimations = false}) => MaterialApp(
  theme: KeyelTheme.light(),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(disableAnimations: disableAnimations),
      child: child,
    ),
  ),
);

Future<void> _setScale(WidgetTester tester) async {
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  testWidgets('folders empty state fits at 200% and has a Back tooltip', (
    tester,
  ) async {
    await _setScale(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foldersProvider.overrideWithValue(const AsyncData(<FolderDto>[])),
        ],
        child: _app(const FoldersScreen(), disableAnimations: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('No folders yet'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets('folders load error offers retry', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foldersProvider.overrideWithValue(
            AsyncError<List<FolderDto>>(
              StateError('disk unavailable'),
              StackTrace.empty,
            ),
          ),
        ],
        child: _app(const FoldersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('disk unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('trash empty state fits at 200% and has a Back tooltip', (
    tester,
  ) async {
    await _setScale(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vaultRepositoryProvider.overrideWithValue(_EmptyVaultRepository()),
        ],
        child: _app(const TrashScreen(), disableAnimations: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Trash is empty'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
  });
}
