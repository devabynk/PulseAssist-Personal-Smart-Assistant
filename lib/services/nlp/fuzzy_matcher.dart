// Fuzzy Matcher for approximate string matching
// Uses Levenshtein distance for typo tolerance

import 'dart:math';

class FuzzyMatcher {
  /// Calculate Levenshtein distance between two strings
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    var v0 = List<int>.generate(s2.length + 1, (i) => i);
    var v1 = List<int>.filled(s2.length + 1, 0);

    for (var i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (var j = 0; j < s2.length; j++) {
        final cost = s1[i] == s2[j] ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce(min);
      }
      final temp = v0;
      v0 = v1;
      v1 = temp;
    }

    return v0[s2.length];
  }

  /// Calculate similarity ratio (0.0 - 1.0)
  static double similarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = levenshteinDistance(s1.toLowerCase(), s2.toLowerCase());
    final maxLength = max(s1.length, s2.length);
    return 1 - (distance / maxLength);
  }

  /// Check if strings are similar within threshold
  static bool isSimilar(String s1, String s2, {double threshold = 0.8}) {
    return similarity(s1, s2) >= threshold;
  }

  /// Find best match from a list of candidates
  static FuzzyMatch? findBestMatch(
    String query,
    List<String> candidates, {
    double minScore = 0.6,
  }) {
    if (candidates.isEmpty) return null;

    FuzzyMatch? bestMatch;
    double bestScore = 0;

    for (final candidate in candidates) {
      final score = similarity(query, candidate);
      if (score > bestScore && score >= minScore) {
        bestScore = score;
        bestMatch = FuzzyMatch(candidate: candidate, score: score);
      }
    }

    return bestMatch;
  }

  /// Find all matches above threshold
  static List<FuzzyMatch> findAllMatches(
    String query,
    List<String> candidates, {
    double minScore = 0.6,
  }) {
    final matches = <FuzzyMatch>[];

    for (final candidate in candidates) {
      final score = similarity(query, candidate);
      if (score >= minScore) {
        matches.add(FuzzyMatch(candidate: candidate, score: score));
      }
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches;
  }

  /// Find word in text with fuzzy matching
  static bool containsFuzzy(
    String text,
    String word, {
    double threshold = 0.8,
  }) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    final target = word.toLowerCase();

    for (final w in words) {
      if (similarity(w, target) >= threshold) {
        return true;
      }
    }
    return false;
  }

  /// Find any matching word from list in text
  static String? findFuzzyMatch(
    String text,
    List<String> words, {
    double threshold = 0.75,
  }) {
    final textWords = text.toLowerCase().split(RegExp(r'\s+'));

    for (final word in words) {
      final target = word.toLowerCase();
      for (final textWord in textWords) {
        if (similarity(textWord, target) >= threshold) {
          return word;
        }
      }
    }
    return null;
  }

  /// Calculate n-gram similarity for longer texts
  static double ngramSimilarity(String s1, String s2, {int n = 2}) {
    if (s1.length < n || s2.length < n) {
      return similarity(s1, s2);
    }

    final ngrams1 = _getNgrams(s1.toLowerCase(), n);
    final ngrams2 = _getNgrams(s2.toLowerCase(), n);

    if (ngrams1.isEmpty && ngrams2.isEmpty) return 1.0;
    if (ngrams1.isEmpty || ngrams2.isEmpty) return 0.0;

    final intersection = ngrams1.intersection(ngrams2).length;
    final union = ngrams1.union(ngrams2).length;

    return intersection / union;
  }

  static Set<String> _getNgrams(String text, int n) {
    final ngrams = <String>{};
    for (var i = 0; i <= text.length - n; i++) {
      ngrams.add(text.substring(i, i + n));
    }
    return ngrams;
  }
}

class FuzzyMatch {
  final String candidate;
  final double score;

  FuzzyMatch({required this.candidate, required this.score});

  @override
  String toString() => 'FuzzyMatch($candidate: ${score.toStringAsFixed(2)})';
}
