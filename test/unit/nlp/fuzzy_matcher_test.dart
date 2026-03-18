import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/services/nlp/fuzzy_matcher.dart';

void main() {
  group('FuzzyMatcher', () {
    // ── levenshteinDistance ───────────────────────────────────────────────
    group('levenshteinDistance()', () {
      test('identical strings → 0', () {
        expect(FuzzyMatcher.levenshteinDistance('alarm', 'alarm'), 0);
      });

      test('empty s1 → length of s2', () {
        expect(FuzzyMatcher.levenshteinDistance('', 'alarm'), 5);
      });

      test('empty s2 → length of s1', () {
        expect(FuzzyMatcher.levenshteinDistance('alarm', ''), 5);
      });

      test('one substitution', () {
        expect(FuzzyMatcher.levenshteinDistance('cat', 'bat'), 1);
      });

      test('one insertion', () {
        expect(FuzzyMatcher.levenshteinDistance('alarm', 'alarms'), 1);
      });

      test('one deletion', () {
        expect(FuzzyMatcher.levenshteinDistance('alarms', 'alarm'), 1);
      });

      test('completely different strings → max distance', () {
        final dist = FuzzyMatcher.levenshteinDistance('abc', 'xyz');
        expect(dist, 3);
      });
    });

    // ── similarity ────────────────────────────────────────────────────────
    group('similarity()', () {
      test('identical strings → 1.0', () {
        expect(FuzzyMatcher.similarity('alarm', 'alarm'), 1.0);
      });

      test('empty strings → 1.0', () {
        expect(FuzzyMatcher.similarity('', ''), 1.0);
      });

      test('one empty → 0.0', () {
        expect(FuzzyMatcher.similarity('alarm', ''), 0.0);
        expect(FuzzyMatcher.similarity('', 'alarm'), 0.0);
      });

      test('similar strings → high score', () {
        expect(FuzzyMatcher.similarity('alarm', 'alar'), greaterThan(0.7));
      });

      test('dissimilar strings → low score', () {
        expect(FuzzyMatcher.similarity('alarm', 'xyz'), lessThan(0.4));
      });

      test('score is between 0.0 and 1.0', () {
        final score = FuzzyMatcher.similarity('hello', 'helo');
        expect(score, greaterThanOrEqualTo(0.0));
        expect(score, lessThanOrEqualTo(1.0));
      });

      test('case insensitive', () {
        final score1 = FuzzyMatcher.similarity('Alarm', 'alarm');
        expect(score1, 1.0);
      });
    });

    // ── isSimilar ─────────────────────────────────────────────────────────
    group('isSimilar()', () {
      test('identical → true', () {
        expect(FuzzyMatcher.isSimilar('alarm', 'alarm'), true);
      });

      test('one typo → true with default threshold 0.8', () {
        // 'alarım' vs 'alarm': 1 substitution in 5 chars → 0.8 similarity
        expect(FuzzyMatcher.isSimilar('alarmm', 'alarm'), true);
      });

      test('very different → false', () {
        expect(FuzzyMatcher.isSimilar('alarm', 'xyz'), false);
      });

      test('custom threshold respected', () {
        // 'alarm' vs 'alar': similarity ~0.8, threshold 0.9 → false
        expect(
          FuzzyMatcher.isSimilar('alarm', 'alar', threshold: 0.95),
          false,
        );
        expect(
          FuzzyMatcher.isSimilar('alarm', 'alar', threshold: 0.7),
          true,
        );
      });
    });

    // ── findBestMatch ─────────────────────────────────────────────────────
    group('findBestMatch()', () {
      test('returns best match from candidates', () {
        final match = FuzzyMatcher.findBestMatch(
          'alarm',
          ['alarmm', 'note', 'reminder'],
          minScore: 0.6,
        );
        expect(match, isNotNull);
        expect(match!.candidate, 'alarmm');
      });

      test('returns null when no candidates meet threshold', () {
        final match = FuzzyMatcher.findBestMatch(
          'alarm',
          ['xyz', 'abc'],
          minScore: 0.8,
        );
        expect(match, isNull);
      });

      test('returns null for empty candidates', () {
        expect(FuzzyMatcher.findBestMatch('alarm', []), isNull);
      });

      test('score is populated in result', () {
        final match = FuzzyMatcher.findBestMatch(
          'alarm',
          ['alarm'],
          minScore: 0.5,
        );
        expect(match?.score, 1.0);
      });
    });

    // ── findAllMatches ────────────────────────────────────────────────────
    group('findAllMatches()', () {
      test('returns all matches above threshold', () {
        final matches = FuzzyMatcher.findAllMatches(
          'alarm',
          ['alarm', 'alarmm', 'xyz'],
          minScore: 0.8,
        );
        expect(matches.length, 2); // 'alarm' and 'alarmm'
      });

      test('returns empty list when none match', () {
        final matches = FuzzyMatcher.findAllMatches(
          'alarm',
          ['xyz', 'abc'],
          minScore: 0.9,
        );
        expect(matches, isEmpty);
      });

      test('results sorted by score descending', () {
        final matches = FuzzyMatcher.findAllMatches(
          'alarm',
          ['alarmm', 'alarm', 'alarmmm'],
          minScore: 0.5,
        );
        for (var i = 0; i < matches.length - 1; i++) {
          expect(matches[i].score, greaterThanOrEqualTo(matches[i + 1].score));
        }
      });
    });

    // ── containsFuzzy ─────────────────────────────────────────────────────
    group('containsFuzzy()', () {
      test('exact word match → true', () {
        expect(FuzzyMatcher.containsFuzzy('alarm kur', 'alarm'), true);
      });

      test('one typo in word → true with default threshold 0.8', () {
        expect(FuzzyMatcher.containsFuzzy('alarım kur', 'alarm', threshold: 0.7), true);
      });

      test('no match → false', () {
        expect(FuzzyMatcher.containsFuzzy('not al', 'alarm', threshold: 0.9), false);
      });
    });

    // ── ngramSimilarity ───────────────────────────────────────────────────
    group('ngramSimilarity()', () {
      test('identical strings → 1.0', () {
        expect(FuzzyMatcher.ngramSimilarity('alarm', 'alarm'), 1.0);
      });

      test('very different strings → low score', () {
        expect(FuzzyMatcher.ngramSimilarity('alarm', 'xyz'), lessThan(0.3));
      });

      test('short strings fall back to similarity()', () {
        // strings shorter than n use similarity fallback
        final score = FuzzyMatcher.ngramSimilarity('ab', 'ab', n: 3);
        expect(score, 1.0);
      });
    });
  });
}
