import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/services/nlp/preprocessor.dart';

void main() {
  group('Preprocessor', () {
    // ── normalize ─────────────────────────────────────────────────────────
    group('normalize()', () {
      test('lowercases text', () {
        expect(Preprocessor.normalize('ALARM KUR'), 'alarm kur');
      });

      test('trims whitespace', () {
        expect(Preprocessor.normalize('  merhaba  '), 'merhaba');
      });

      test('collapses multiple spaces', () {
        expect(Preprocessor.normalize('alarm  kur'), 'alarm kur');
      });

      test('normalizes Turkish ı → i', () {
        expect(Preprocessor.normalize('kaldır'), contains('i'));
      });

      test('normalizes Turkish ğ → g', () {
        expect(Preprocessor.normalize('ağ'), 'ag');
      });

      test('normalizes Turkish ü → u', () {
        expect(Preprocessor.normalize('üzgün'), 'uzgun');
      });

      test('normalizes Turkish ş → s', () {
        expect(Preprocessor.normalize('şimdi'), 'simdi');
      });

      test('normalizes Turkish ö → o', () {
        expect(Preprocessor.normalize('önemli'), 'onemli');
      });

      test('normalizes Turkish ç → c', () {
        expect(Preprocessor.normalize('çok'), 'cok');
      });

      test('normalizes uppercase Turkish İ → i', () {
        expect(Preprocessor.normalize('İstanbul'), 'istanbul');
      });

      test('empty string returns empty string', () {
        expect(Preprocessor.normalize(''), '');
      });
    });

    // ── tokenize ──────────────────────────────────────────────────────────
    group('tokenize()', () {
      test('splits on spaces', () {
        final tokens = Preprocessor.tokenize('alarm kur bana');
        expect(tokens, containsAll(['alarm', 'kur', 'bana']));
      });

      test('splits on punctuation', () {
        final tokens = Preprocessor.tokenize('alarm, kur!');
        expect(tokens, contains('alarm'));
        expect(tokens, contains('kur'));
      });

      test('filters single-character tokens', () {
        final tokens = Preprocessor.tokenize('a b alarm');
        expect(tokens, isNot(contains('a')));
        expect(tokens, isNot(contains('b')));
        expect(tokens, contains('alarm'));
      });

      test('returns empty list for empty string', () {
        expect(Preprocessor.tokenize(''), isEmpty);
      });

      test('normalizes before tokenizing (Turkish chars)', () {
        final tokens = Preprocessor.tokenize('Şimdi Kur');
        expect(tokens, contains('simdi'));
        expect(tokens, contains('kur'));
      });
    });

    // ── removeStopWords ───────────────────────────────────────────────────
    group('removeStopWords()', () {
      test('removes common English stop words', () {
        final tokens = ['set', 'an', 'alarm', 'the', 'morning'];
        final result = Preprocessor.removeStopWords(tokens);
        expect(result, isNot(contains('an')));
        expect(result, isNot(contains('the')));
        expect(result, contains('alarm'));
        expect(result, contains('morning'));
      });

      test('removes common Turkish stop words', () {
        final tokens = ['bir', 'alarm', 'kur', 'bana', 've'];
        final result = Preprocessor.removeStopWords(tokens);
        expect(result, isNot(contains('bir')));
        expect(result, isNot(contains('ve')));
        expect(result, contains('alarm'));
      });

      test('returns same list if no stop words', () {
        final tokens = ['alarm', 'kur'];
        final result = Preprocessor.removeStopWords(tokens);
        expect(result, tokens);
      });

      test('returns empty list if all stop words', () {
        final tokens = ['a', 'an', 'the', 'bir'];
        final result = Preprocessor.removeStopWords(tokens);
        expect(result, isEmpty);
      });
    });

    // ── extractKeywords ───────────────────────────────────────────────────
    group('extractKeywords()', () {
      test('returns meaningful keywords', () {
        final keywords = Preprocessor.extractKeywords('alarm kur bana sabah');
        expect(keywords, contains('alarm'));
        expect(keywords, contains('kur'));
        expect(keywords, contains('sabah'));
      });

      test('returns empty list for empty string', () {
        expect(Preprocessor.extractKeywords(''), isEmpty);
      });
    });

    // ── clean ─────────────────────────────────────────────────────────────
    group('clean()', () {
      test('removes punctuation', () {
        expect(Preprocessor.clean('alarm!'), 'alarm');
        expect(Preprocessor.clean('hey, there!'), 'hey there');
      });

      test('normalizes Turkish and removes punctuation', () {
        final result = Preprocessor.clean('Şimdi!');
        expect(result, 'simdi');
      });
    });

    // ── extractNumbers ────────────────────────────────────────────────────
    group('extractNumbers()', () {
      test('extracts single number', () {
        expect(Preprocessor.extractNumbers('alarm at 7'), [7]);
      });

      test('extracts multiple numbers', () {
        expect(Preprocessor.extractNumbers('07:30 alarm'), [7, 30]);
      });

      test('returns empty list when no numbers', () {
        expect(Preprocessor.extractNumbers('merhaba'), isEmpty);
      });
    });

    // ── containsAny ───────────────────────────────────────────────────────
    group('containsAny()', () {
      test('returns true when any word matches', () {
        expect(
          Preprocessor.containsAny('alarm kur', ['alarm', 'hatirlatici']),
          true,
        );
      });

      test('returns false when no word matches', () {
        expect(
          Preprocessor.containsAny('merhaba', ['alarm', 'not']),
          false,
        );
      });

      test('handles Turkish normalization in matching', () {
        // 'şimdi' normalizes to 'simdi'
        expect(
          Preprocessor.containsAny('şimdi kur', ['simdi']),
          true,
        );
      });
    });

    // ── containsAll ───────────────────────────────────────────────────────
    group('containsAll()', () {
      test('returns true when all words match', () {
        expect(
          Preprocessor.containsAll('alarm kur sabah', ['alarm', 'sabah']),
          true,
        );
      });

      test('returns false when any word is missing', () {
        expect(
          Preprocessor.containsAll('alarm kur', ['alarm', 'sabah']),
          false,
        );
      });
    });

    // ── wordMatchScore ────────────────────────────────────────────────────
    group('wordMatchScore()', () {
      test('returns 1.0 when all keywords match', () {
        expect(
          Preprocessor.wordMatchScore('alarm kur sabah', ['alarm', 'sabah']),
          1.0,
        );
      });

      test('returns 0.5 when half keywords match', () {
        expect(
          Preprocessor.wordMatchScore('alarm kur', ['alarm', 'sabah']),
          0.5,
        );
      });

      test('returns 0.0 when no keywords match', () {
        expect(
          Preprocessor.wordMatchScore('merhaba', ['alarm', 'sabah']),
          0.0,
        );
      });

      test('returns 0.0 for empty keyword list', () {
        expect(Preprocessor.wordMatchScore('alarm kur', []), 0.0);
      });
    });
  });
}
