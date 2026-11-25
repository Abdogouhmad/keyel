/// Fuzzy ranking for the quick-actions palette.
///
/// This file is pure Dart on purpose: it never imports Flutter, Riverpod or the
/// vault bridge. It only sees secret-free display metadata supplied by the
/// caller, so it can be unit tested without a vault session.
library;

/// A secret-free item that can appear in the quick-actions palette.
class QuickActionCandidate<T> {
  /// Creates a candidate.
  const new({
    required this.value,
    required this.title,
    this.subtitle = '',
    this.isFavorite = false,
    this.recencyRank,
  });

  /// The action or entry to run when the candidate is chosen.
  final T value;

  /// Primary display text; weighted more heavily than [subtitle].
  final String title;

  /// Secondary display text, such as a username.
  final String subtitle;

  /// Whether the entry is pinned to favourites.
  final bool isFavorite;

  /// Zero-based position in the recently-used list, or `null` when absent.
  final int? recencyRank;
}

/// A candidate together with the score that placed it in the result list.
class RankedQuickAction<T> {
  /// Creates a ranked candidate.
  const new(this.candidate, this.score);

  /// The matched candidate.
  final QuickActionCandidate<T> candidate;

  /// Higher is a better match. Zero for unranked input with an empty query.
  final int score;
}

class _Scored<T> {
  const new(this.index, this.candidate, this.score);

  final int index;
  final QuickActionCandidate<T> candidate;
  final int score;
}

/// Maximum number of recent ids remembered in `AppPreferences`.
const int quickActionRecencyLimit = 8;

/// Sorts [candidates] by how well they match [query], best first.
///
/// Matching is case- and accent-insensitive and token-based. Every token must
/// match somewhere in the title or subtitle. Exact prefixes outrank word-start
/// hits, which outrank mid-word hits, which outrank loose subsequences. An
/// empty query keeps the input order except that favourites and recently used
/// entries come first.
List<RankedQuickAction<T>> rankQuickActions<T>(
  Iterable<QuickActionCandidate<T>> candidates,
  String query,
) {
  final indexed = candidates.toList(growable: false);
  final tokens = _fold(query)
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toList(growable: false);

  if (tokens.isEmpty) {
    final order =
        [
          for (var index = 0; index < indexed.length; index++)
            _Scored(index, indexed[index], 0),
        ]..sort((a, b) {
          final favorites =
              (b.candidate.isFavorite ? 1 : 0) -
              (a.candidate.isFavorite ? 1 : 0);
          if (favorites != 0) return favorites;
          final leftRank = a.candidate.recencyRank ?? indexed.length;
          final rightRank = b.candidate.recencyRank ?? indexed.length;
          final recent = leftRank.compareTo(rightRank);
          return recent != 0 ? recent : a.index.compareTo(b.index);
        });
    return [for (final item in order) RankedQuickAction(item.candidate, 0)];
  }

  final scored = <_Scored<T>>[];
  for (var index = 0; index < indexed.length; index++) {
    final candidate = indexed[index];
    final title = _fold(candidate.title);
    final subtitle = _fold(candidate.subtitle);
    var score = 0;
    var matchesAllTokens = true;
    for (final token in tokens) {
      final titleScore = _fieldScore(token, title);
      final subtitleScore = _fieldScore(token, subtitle);
      if (titleScore == 0 && subtitleScore == 0) {
        matchesAllTokens = false;
        break;
      }
      score += titleScore + (subtitleScore * 0.6).round();
    }
    if (!matchesAllTokens) continue;

    if (candidate.isFavorite) score += 12;
    final rank = candidate.recencyRank;
    if (rank != null && rank < quickActionRecencyLimit) {
      score += quickActionRecencyLimit - rank;
    }
    scored.add(_Scored(index, candidate, score));
  }

  scored.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    return byScore != 0 ? byScore : a.index.compareTo(b.index);
  });
  return [
    for (final item in scored) RankedQuickAction(item.candidate, item.score),
  ];
}

int _fieldScore(String token, String field) {
  if (field.isEmpty) return 0;
  final index = field.indexOf(token);
  if (index >= 0) {
    if (index == 0) return 130;
    return field.codeUnitAt(index - 1) == 0x20 ? 115 : 100;
  }
  return _subsequenceScore(token, field) ?? 0;
}

int? _subsequenceScore(String token, String field) {
  var tokenIndex = 0;
  var gaps = 0;
  var lastMatch = -1;
  for (var index = 0; index < field.length; index++) {
    if (field.codeUnitAt(index) != token.codeUnitAt(tokenIndex)) continue;
    if (lastMatch >= 0) gaps += index - lastMatch - 1;
    lastMatch = index;
    tokenIndex++;
    if (tokenIndex == token.length) {
      final penalty = gaps > 20 ? 20 : gaps;
      return 55 - penalty + (lastMatch == token.length - 1 ? 5 : 0);
    }
  }
  return null;
}

/// Folds common Latin accents so `reseau` matches `Réseau`.
String _fold(String value) {
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    switch (rune) {
      case 0xE6:
        buffer.write('ae');
      case 0x153:
        buffer.write('oe');
      case 0xDF:
        buffer.write('ss');
      case 0xE7:
        buffer.writeCharCode(0x63);
      case 0xF1:
        buffer.writeCharCode(0x6E);
      case 0xF8:
        buffer.writeCharCode(0x6F);
      case >= 0xE0 && <= 0xE5:
        buffer.writeCharCode(0x61);
      case >= 0xE8 && <= 0xEB:
        buffer.writeCharCode(0x65);
      case >= 0xEC && <= 0xEF:
        buffer.writeCharCode(0x69);
      case >= 0xF2 && <= 0xF6:
        buffer.writeCharCode(0x6F);
      case >= 0xF9 && <= 0xFC:
        buffer.writeCharCode(0x75);
      case 0xFD || 0xFF:
        buffer.writeCharCode(0x79);
      default:
        buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}
