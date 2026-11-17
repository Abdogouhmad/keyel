import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyel/features/entry/models/entry_icon.dart';
import 'package:keyel/features/entry/vault_entry.dart';

void main() {
  group('EntryIcon Catalog', () {
    test('catalog contains valid unique icons', () {
      expect(kEntryIconCatalog.isNotEmpty, isTrue);
      final keys = <String>{};
      for (final item in kEntryIconCatalog) {
        expect(
          keys.add(item.key),
          isTrue,
          reason: 'Duplicate key: ${item.key}',
        );
        expect(item.label.isNotEmpty, isTrue);
        expect(item.key.isNotEmpty, isTrue);
      }
    });

    test('catalog is broad and covers every category', () {
      expect(kEntryIconCatalog.length, greaterThanOrEqualTo(150));
      for (final category in EntryIconCategory.values) {
        if (category == EntryIconCategory.all) continue;
        expect(
          kEntryIconCatalog.any((icon) => icon.category == category),
          isTrue,
          reason: 'No icons in category ${category.label}',
        );
      }
    });

    test('resolveEntryIcon returns custom icon when key exists', () {
      final icon = resolveEntryIcon('brand_github');
      expect(icon, equals(Icons.code_rounded));
    });

    test('resolveEntryIcon resolves icons in the crypto category', () {
      expect(
        resolveEntryIcon('crypto_bitcoin'),
        equals(Icons.currency_bitcoin_rounded),
      );
      expect(resolveEntryIcon('crypto_ethereum'), equals(Icons.token_rounded));
    });

    test('resolveEntryIcon falls back to default kind icons', () {
      expect(resolveEntryIcon(null), equals(Icons.key_rounded));
      expect(resolveEntryIcon('non_existent_key'), equals(Icons.key_rounded));
      expect(
        resolveEntryIcon(null, VaultEntryKind.card),
        equals(Icons.credit_card_rounded),
      );
      expect(
        resolveEntryIcon(null, VaultEntryKind.note),
        equals(Icons.sticky_note_2_rounded),
      );
    });

    test('suggestEntryIcon finds matching icons from title or domain', () {
      expect(suggestEntryIcon('Google Account', null), equals('brand_google'));
      expect(
        suggestEntryIcon(null, 'https://github.com/login'),
        equals('brand_github'),
      );
      expect(
        suggestEntryIcon('My Netflix subscription', null),
        equals('brand_netflix'),
      );
      expect(suggestEntryIcon('Random Title Without Match', null), isNull);
    });

    test('EntryIcon matching handles search queries', () {
      final github = kEntryIconMap['brand_github']!;
      expect(github.matches('git'), isTrue);
      expect(github.matches('GITHUB'), isTrue);
      expect(github.matches('developer'), isTrue);
      expect(github.matches('xyz123'), isFalse);
    });
  });
}
