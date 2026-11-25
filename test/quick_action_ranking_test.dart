import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/features/quick_actions/quick_action_ranking.dart';

QuickActionCandidate<String> _candidate(
  String value, {
  String? title,
  String subtitle = '',
  bool favorite = false,
  int? recencyRank,
}) {
  return QuickActionCandidate(
    value: value,
    title: title ?? value,
    subtitle: subtitle,
    isFavorite: favorite,
    recencyRank: recencyRank,
  );
}

List<String> _values(List<String> candidates, String query) => rankQuickActions(
  candidates.map(_candidate),
  query,
).map((result) => result.candidate.value).toList();

void main() {
  test('exact prefixes outrank word starts and mid-word hits', () {
    expect(_values(['MyGitHub notes', 'Use GitHub today', 'GitHub'], 'git'), [
      'GitHub',
      'Use GitHub today',
      'MyGitHub notes',
    ]);
  });

  test('loose subsequences still match', () {
    expect(_values(['Account Manager', 'Notes'], 'atm'), ['Account Manager']);
  });

  test('matching is case- and accent-insensitive', () {
    expect(_values(['Réseau Social'], 'RESEAU'), ['Réseau Social']);
    expect(_values(['Café'], 'cafe'), ['Café']);
  });

  test('every token must match somewhere in title or subtitle', () {
    final ranked = rankQuickActions([
      _candidate('match', title: 'GitHub', subtitle: 'backup'),
    ], 'git backup');
    expect(ranked, hasLength(1));

    expect(_values(['GitHub'], 'git missing'), isEmpty);
  });

  test('favourites and recency break equal-score ties', () {
    expect(
      rankQuickActions([
        _candidate('plain', title: 'Alpha Bank'),
        _candidate('pinned', title: 'Alpha Bank', favorite: true),
      ], 'alpha').map((result) => result.candidate.value),
      ['pinned', 'plain'],
    );

    expect(
      rankQuickActions([
        _candidate('older', title: 'Alpha Bank', recencyRank: 2),
        _candidate('newer', title: 'Alpha Bank', recencyRank: 0),
      ], 'alpha').map((result) => result.candidate.value),
      ['newer', 'older'],
    );
  });

  test('empty query keeps input order except favourites and recency', () {
    expect(
      rankQuickActions([
        _candidate('a'),
        _candidate('b', favorite: true),
        _candidate('c'),
      ], '').map((result) => result.candidate.value),
      ['b', 'a', 'c'],
    );
    expect(
      rankQuickActions([
        _candidate('a', recencyRank: 1),
        _candidate('b', recencyRank: 0),
        _candidate('c'),
      ], '').map((result) => result.candidate.value),
      ['b', 'a', 'c'],
    );
  });

  test('ranking never receives more than display metadata', () {
    final ranked = rankQuickActions([
      _candidate('id-1', title: 'Alpha', subtitle: 'ada@example.test'),
    ], 'ada');
    expect(ranked.single.candidate.value, 'id-1');
    expect(ranked.single.candidate.subtitle, 'ada@example.test');
  });
}
