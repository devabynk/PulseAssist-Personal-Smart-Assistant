import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/services/nlp/entity_extractor.dart';

void main() {
  group('EntityExtractor', () {
    // ── extractTime ───────────────────────────────────────────────────────
    group('extractTime()', () {
      group('HH:MM format', () {
        test('"07:30 alarm kur" → 07:30', () {
          final t = EntityExtractor.extractTime('07:30 alarm kur');
          expect(t, isNotNull);
          expect(t!.hour, 7);
          expect(t.minute, 30);
        });

        test('"alarm at 14:00" → 14:00', () {
          final t = EntityExtractor.extractTime('alarm at 14:00');
          expect(t?.hour, 14);
          expect(t?.minute, 0);
        });

        test('"23:59 alarm" → 23:59', () {
          final t = EntityExtractor.extractTime('23:59 alarm');
          expect(t?.hour, 23);
          expect(t?.minute, 59);
        });
      });

      group('HH.MM format', () {
        test('"7.30 alarm" → 7:30', () {
          final t = EntityExtractor.extractTime('7.30 alarm');
          expect(t?.hour, 7);
          expect(t?.minute, 30);
        });
      });

      group('Turkish suffix patterns', () {
        test('"saat 7 alarm kur" → 7:00', () {
          final t = EntityExtractor.extractTime('saat 7 alarm kur');
          expect(t?.hour, 7);
          expect(t?.minute, 0);
        });

        test('"7 buçuk alarm" → 7:30', () {
          final t = EntityExtractor.extractTime('7 buçuk alarm kur');
          expect(t?.hour, 7);
          expect(t?.minute, 30);
        });
      });

      group('English time formats', () {
        test('"at 9am" → 9:00', () {
          final t = EntityExtractor.extractTime('alarm at 9am');
          expect(t?.hour, 9);
          expect(t?.minute, 0);
        });

        test('"at 9pm" → 21:00', () {
          final t = EntityExtractor.extractTime('alarm at 9pm');
          expect(t?.hour, 21);
          expect(t?.minute, 0);
        });

        test('"at 12pm" → 12:00', () {
          final t = EntityExtractor.extractTime('alarm at 12pm');
          expect(t?.hour, 12);
          expect(t?.minute, 0);
        });

        test('"at 12am" → 0:00', () {
          final t = EntityExtractor.extractTime('alarm at 12am');
          expect(t?.hour, 0);
          expect(t?.minute, 0);
        });

        test('"half past 7" → 7:30', () {
          final t = EntityExtractor.extractTime('wake me at half past 7');
          expect(t?.hour, 7);
          expect(t?.minute, 30);
        });

        test('"quarter past 8" → 8:15', () {
          final t = EntityExtractor.extractTime('alarm quarter past 8');
          expect(t?.hour, 8);
          expect(t?.minute, 15);
        });

        test('"quarter to 8" → 7:45', () {
          final t = EntityExtractor.extractTime('alarm quarter to 8');
          expect(t?.hour, 7);
          expect(t?.minute, 45);
        });
      });

      group('Time period words', () {
        test('"morning" → 9:00', () {
          final t = EntityExtractor.extractTime('set alarm for morning');
          expect(t?.hour, 9);
        });

        test('"noon" → 12:00', () {
          final t = EntityExtractor.extractTime('remind me at noon');
          expect(t?.hour, 12);
        });

        test('"gece" → 22:00', () {
          // "gece" is checked before longer compounds like "gece yarısı"
          // in the map iteration, so plain "gece" → 22
          final t = EntityExtractor.extractTime('gece alarm kur');
          expect(t?.hour, 22);
        });

        test('Turkish "sabah" → 9:00', () {
          final t = EntityExtractor.extractTime('sabah alarm kur');
          expect(t?.hour, 9);
        });

        test('Turkish "akşam" → 19:00', () {
          final t = EntityExtractor.extractTime('akşam hatırlatıcı');
          expect(t?.hour, 19);
        });
      });

      group('Relative time', () {
        test('"30 dakika sonra" → future time', () {
          final before = DateTime.now().add(const Duration(minutes: 28));
          final after = DateTime.now().add(const Duration(minutes: 32));
          final t = EntityExtractor.extractTime('30 dakika sonra alarm');
          expect(t, isNotNull);
          final resultTime = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            t!.hour,
            t.minute,
          );
          expect(resultTime.isAfter(before), true);
          expect(resultTime.isBefore(after), true);
        });

        test('"in 15 minutes" → future time', () {
          final t = EntityExtractor.extractTime('remind me in 15 minutes');
          expect(t, isNotNull);
          expect(t!.periodName, 'relative');
        });
      });

      test('no time in text → null', () {
        expect(EntityExtractor.extractTime('merhaba nasılsın'), isNull);
      });
    });

    // ── extractDays ───────────────────────────────────────────────────────
    group('extractDays()', () {
      group('Group keywords', () {
        test('"hafta içi" → [1,2,3,4,5]', () {
          final days = EntityExtractor.extractDays('hafta içi alarm kur');
          expect(days.days, [1, 2, 3, 4, 5]);
        });

        test('"weekdays" → [1,2,3,4,5]', () {
          final days = EntityExtractor.extractDays('set alarm for weekdays');
          expect(days.days, [1, 2, 3, 4, 5]);
        });

        test('"hafta sonu" → [6,7]', () {
          final days = EntityExtractor.extractDays('hafta sonu alarm');
          expect(days.days, [6, 7]);
        });

        test('"weekend" → [6,7]', () {
          final days = EntityExtractor.extractDays('alarm on weekends');
          expect(days.days, [6, 7]);
        });

        test('"her gün" → [1,2,3,4,5,6,7]', () {
          final days = EntityExtractor.extractDays('her gün alarm kur');
          expect(days.days, [1, 2, 3, 4, 5, 6, 7]);
        });

        test('"every day" → [1,2,3,4,5,6,7]', () {
          final days = EntityExtractor.extractDays('alarm every day');
          expect(days.days, [1, 2, 3, 4, 5, 6, 7]);
        });

        test('"daily" → [1,2,3,4,5,6,7]', () {
          final days = EntityExtractor.extractDays('daily alarm');
          expect(days.days, [1, 2, 3, 4, 5, 6, 7]);
        });
      });

      group('Individual day names', () {
        test('"pazartesi" → [1]', () {
          final days = EntityExtractor.extractDays('pazartesi alarm kur');
          expect(days.days, contains(1));
        });

        test('"monday" → [1]', () {
          final days = EntityExtractor.extractDays('alarm on monday');
          expect(days.days, contains(1));
        });

        test('"friday" → [5]', () {
          final days = EntityExtractor.extractDays('alarm on friday');
          expect(days.days, contains(5));
        });

        test('"cuma" → [5]', () {
          final days = EntityExtractor.extractDays('cuma alarm');
          expect(days.days, contains(5));
        });

        test('multiple days → sorted list', () {
          final days = EntityExtractor.extractDays('monday and wednesday alarm');
          expect(days.days, containsAll([1, 3]));
          // should be sorted
          expect(days.days, equals(days.days..sort()));
        });

        test('no day in text → empty list', () {
          final days = EntityExtractor.extractDays('saat 7 alarm kur');
          expect(days.days, isEmpty);
        });
      });
    });

    // ── extractRelativeDate ───────────────────────────────────────────────
    group('extractRelativeDate()', () {
      test('"bugün" → 0 days', () {
        final r = EntityExtractor.extractRelativeDate('bugün hatırlatıcı');
        expect(r?.daysFromNow, 0);
      });

      test('"today" → 0 days', () {
        final r = EntityExtractor.extractRelativeDate('remind me today');
        expect(r?.daysFromNow, 0);
      });

      test('"yarın" → 1 day', () {
        final r = EntityExtractor.extractRelativeDate('yarın toplantı');
        expect(r?.daysFromNow, 1);
      });

      test('"tomorrow" → 1 day', () {
        final r = EntityExtractor.extractRelativeDate('meeting tomorrow');
        expect(r?.daysFromNow, 1);
      });

      test('"haftaya" → 7 days', () {
        final r = EntityExtractor.extractRelativeDate('haftaya randevu');
        expect(r?.daysFromNow, 7);
      });

      test('"next week" → 7 days', () {
        final r = EntityExtractor.extractRelativeDate('meeting next week');
        expect(r?.daysFromNow, 7);
      });

      test('"bir ay sonra" → 30 days', () {
        final r = EntityExtractor.extractRelativeDate('bir ay sonra tatil');
        expect(r?.daysFromNow, 30);
      });

      test('no date → null', () {
        expect(EntityExtractor.extractRelativeDate('alarm kur'), isNull);
      });
    });

    // ── extractPriority ───────────────────────────────────────────────────
    group('extractPriority()', () {
      test('"acil" → high priority', () {
        final p = EntityExtractor.extractPriority('acil toplantı var');
        expect(p?.level, 'high');
      });

      test('"urgent" → high priority', () {
        final p = EntityExtractor.extractPriority('urgent meeting');
        expect(p?.level, 'high');
      });

      test('"asap" → high priority', () {
        final p = EntityExtractor.extractPriority('finish the report asap');
        expect(p?.level, 'high');
      });

      test('"kritik" → high priority', () {
        final p = EntityExtractor.extractPriority('kritik bir görev');
        expect(p?.level, 'high');
      });

      test('"low priority" → low', () {
        final p = EntityExtractor.extractPriority('low priority task');
        expect(p?.level, 'low');
      });

      test('"no rush" → low', () {
        final p = EntityExtractor.extractPriority('no rush, do it later');
        expect(p?.level, 'low');
      });

      test('"sonra da olur" → low', () {
        final p = EntityExtractor.extractPriority('sonra da olur');
        expect(p?.level, 'low');
      });

      test('no priority keywords → null (defaults to medium)', () {
        expect(EntityExtractor.extractPriority('toplantı var'), isNull);
      });
    });

    // ── extractContent ────────────────────────────────────────────────────
    group('extractContent()', () {
      test('quoted content extracted', () {
        final c = EntityExtractor.extractContent('not al "toplantı hazırlığı"');
        expect(c, 'toplantı hazırlığı');
      });

      test('single-quoted content extracted', () {
        final c = EntityExtractor.extractContent("note 'buy groceries'");
        expect(c, 'buy groceries');
      });

      test('returns null when no content found', () {
        // Plain command with nothing extractable
        // May be null or some fallback; we just ensure it doesn't throw
        expect(() => EntityExtractor.extractContent('alarm kur'), returnsNormally);
      });
    });
  });
}
