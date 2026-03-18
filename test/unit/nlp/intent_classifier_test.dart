import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/services/nlp/intent_classifier.dart';

void main() {
  group('IntentClassifier', () {
    // ── Alarm intent ──────────────────────────────────────────────────────
    group('Alarm intent', () {
      test('Turkish: "alarm kur" → alarm', () {
        expect(IntentClassifier.classify('alarm kur').type, IntentType.alarm);
      });

      test('Turkish: "beni 7de uyandır" → alarm', () {
        expect(
          IntentClassifier.classify('beni 7de uyandır').type,
          IntentType.alarm,
        );
      });

      test('English: "set alarm" → alarm', () {
        expect(
          IntentClassifier.classify('set alarm for 7am').type,
          IntentType.alarm,
        );
      });

      test('English: "wake me up" → alarm', () {
        expect(
          IntentClassifier.classify('wake me up at 6').type,
          IntentType.alarm,
        );
      });
    });

    // ── Reminder intent ───────────────────────────────────────────────────
    group('Reminder intent', () {
      test('Turkish: "hatırlatıcı oluştur" → reminder', () {
        expect(
          IntentClassifier.classify('hatırlatıcı oluştur').type,
          IntentType.reminder,
        );
      });

      test('Turkish: "hatırlat" → reminder', () {
        expect(
          IntentClassifier.classify('bana toplantıyı hatırlat').type,
          IntentType.reminder,
        );
      });

      test('English: "remind me" → reminder', () {
        expect(
          IntentClassifier.classify('remind me to call the doctor').type,
          IntentType.reminder,
        );
      });

      test('English: "don\'t forget" → reminder', () {
        expect(
          IntentClassifier.classify("don't forget the meeting").type,
          IntentType.reminder,
        );
      });
    });

    // ── Note intent ───────────────────────────────────────────────────────
    group('Note intent', () {
      test('Turkish: "not al" → note', () {
        expect(
          IntentClassifier.classify('not al bana').type,
          IntentType.note,
        );
      });

      test('Turkish: "not et" → note', () {
        expect(
          IntentClassifier.classify('bunu not et').type,
          IntentType.note,
        );
      });

      test('Turkish: "alışveriş listesi" → note', () {
        expect(
          IntentClassifier.classify('alışveriş listesi oluştur').type,
          IntentType.note,
        );
      });

      test('English: "take note" → note', () {
        expect(
          IntentClassifier.classify('take note of this').type,
          IntentType.note,
        );
      });

      test('English: "shopping list" → note', () {
        expect(
          IntentClassifier.classify('create a shopping list').type,
          IntentType.note,
        );
      });
    });

    // ── Greeting intent ───────────────────────────────────────────────────
    group('Greeting intent', () {
      test('Turkish: "merhaba" → greeting', () {
        expect(
          IntentClassifier.classify('merhaba').type,
          IntentType.greeting,
        );
      });

      test('Turkish: "selam" → greeting', () {
        expect(IntentClassifier.classify('selam').type, IntentType.greeting);
      });

      test('Turkish: "günaydın" → greeting', () {
        expect(
          IntentClassifier.classify('günaydın').type,
          IntentType.greeting,
        );
      });

      test('English: "hello" → greeting', () {
        expect(IntentClassifier.classify('hello').type, IntentType.greeting);
      });

      test('English: "good morning" → greeting', () {
        expect(
          IntentClassifier.classify('good morning').type,
          IntentType.greeting,
        );
      });
    });

    // ── Farewell intent ───────────────────────────────────────────────────
    group('Farewell intent', () {
      test('Turkish: "görüşürüz" → farewell', () {
        expect(
          IntentClassifier.classify('görüşürüz').type,
          IntentType.farewell,
        );
      });

      test('English: "goodbye" → farewell', () {
        expect(
          IntentClassifier.classify('goodbye').type,
          IntentType.farewell,
        );
      });

      test('English: "bye" → farewell', () {
        expect(IntentClassifier.classify('bye').type, IntentType.farewell);
      });
    });

    // ── Thanks intent ─────────────────────────────────────────────────────
    group('Thanks intent', () {
      test('Turkish: "teşekkürler" → thanks', () {
        expect(
          IntentClassifier.classify('teşekkürler').type,
          IntentType.thanks,
        );
      });

      test('Turkish: "sağol" → thanks', () {
        expect(IntentClassifier.classify('sağol').type, IntentType.thanks);
      });

      test('English: "thank you" → thanks', () {
        expect(
          IntentClassifier.classify('thank you').type,
          IntentType.thanks,
        );
      });
    });

    // ── Help intent ───────────────────────────────────────────────────────
    group('Help intent', () {
      test('Turkish: "yardım et" → help', () {
        expect(
          IntentClassifier.classify('yardım et').type,
          IntentType.help,
        );
      });

      test('English: "help me" → help', () {
        expect(IntentClassifier.classify('help me').type, IntentType.help);
      });

      test('English: "what can you do" → help', () {
        expect(
          IntentClassifier.classify('what can you do').type,
          IntentType.help,
        );
      });
    });

    // ── Time intent ───────────────────────────────────────────────────────
    group('Time intent', () {
      test('Turkish: "saat kaç" → time', () {
        expect(IntentClassifier.classify('saat kaç').type, IntentType.time);
      });

      test('English: "what time is it" → time', () {
        expect(
          IntentClassifier.classify('what time is it').type,
          IntentType.time,
        );
      });
    });

    // ── Date intent ───────────────────────────────────────────────────────
    group('Date intent', () {
      test('Turkish: "bugün hangi gün" → date', () {
        expect(
          IntentClassifier.classify('bugün hangi gün').type,
          IntentType.date,
        );
      });

      test('English: "what is the date" → date', () {
        expect(
          IntentClassifier.classify('what is the date').type,
          IntentType.date,
        );
      });
    });

    // ── Affirmative / Negative ────────────────────────────────────────────
    group('Affirmative intent', () {
      test('"evet" → affirmative', () {
        expect(
          IntentClassifier.classify('evet').type,
          IntentType.affirmative,
        );
      });

      test('"tamam" → affirmative', () {
        expect(
          IntentClassifier.classify('tamam').type,
          IntentType.affirmative,
        );
      });

      test('"yes" → affirmative', () {
        expect(IntentClassifier.classify('yes').type, IntentType.affirmative);
      });
    });

    group('Negative intent', () {
      test('"hayır" → negative', () {
        expect(IntentClassifier.classify('hayır').type, IntentType.negative);
      });

      test('"iptal" → negative', () {
        expect(IntentClassifier.classify('iptal').type, IntentType.negative);
      });

      test('"cancel" → negative', () {
        expect(IntentClassifier.classify('cancel').type, IntentType.negative);
      });
    });

    // ── Math intent ───────────────────────────────────────────────────────
    group('Math intent (regex shortcut)', () {
      test('"2+2" → math', () {
        expect(IntentClassifier.classify('2+2').type, IntentType.math);
      });

      test('"10 * 5" → math', () {
        expect(IntentClassifier.classify('10 * 5').type, IntentType.math);
      });

      test('"100/4" → math', () {
        expect(IntentClassifier.classify('100/4').type, IntentType.math);
      });

      test('"hesapla" → math', () {
        expect(IntentClassifier.classify('hesapla').type, IntentType.math);
      });
    });

    // ── Pomodoro intents ──────────────────────────────────────────────────
    group('Pomodoro intents', () {
      test('"pomodoro başlat" → startPomodoro', () {
        expect(
          IntentClassifier.classify('pomodoro başlat').type,
          IntentType.startPomodoro,
        );
      });

      test('"start pomodoro" → startPomodoro', () {
        expect(
          IntentClassifier.classify('start pomodoro').type,
          IntentType.startPomodoro,
        );
      });

      test('"pomodoro durumu" → pomodoroStatus', () {
        expect(
          IntentClassifier.classify('pomodoro durumu').type,
          IntentType.pomodoroStatus,
        );
      });
    });

    // ── List intents ──────────────────────────────────────────────────────
    group('List intents', () {
      test('"alarmlarım" → listAlarms', () {
        expect(
          IntentClassifier.classify('alarmlarım').type,
          IntentType.listAlarms,
        );
      });

      test('"my notes" → listNotes', () {
        expect(
          IntentClassifier.classify('my notes').type,
          IntentType.listNotes,
        );
      });

      test('"hatırlatıcılarım" → listReminders', () {
        expect(
          IntentClassifier.classify('hatırlatıcılarım').type,
          IntentType.listReminders,
        );
      });
    });

    // ── Delete intents ────────────────────────────────────────────────────
    group('Delete intents', () {
      test('"alarmı sil" → deleteAlarm', () {
        expect(
          IntentClassifier.classify('alarmı sil').type,
          IntentType.deleteAlarm,
        );
      });

      test('"delete alarm" → deleteAlarm', () {
        expect(
          IntentClassifier.classify('delete alarm').type,
          IntentType.deleteAlarm,
        );
      });

      test('"notu sil" → deleteNote', () {
        expect(
          IntentClassifier.classify('notu sil').type,
          IntentType.deleteNote,
        );
      });

      test('"hatırlatıcıyı sil" → deleteReminder', () {
        expect(
          IntentClassifier.classify('hatırlatıcıyı sil').type,
          IntentType.deleteReminder,
        );
      });
    });

    // ── Unclear intent ────────────────────────────────────────────────────
    group('Unclear intent', () {
      test('text with no matching keywords → unclear', () {
        // Use text that shares no substrings with any keyword dictionary
        expect(
          IntentClassifier.classify('fwmvpz krdhjq').type,
          IntentType.unclear,
        );
      });
    });

    // ── Confidence levels ─────────────────────────────────────────────────
    group('Confidence levels', () {
      test('high-confidence keywords produce isHighConfidence = true', () {
        final intent = IntentClassifier.classify('alarm kur');
        // confidence is clamped to [0,1] so 'alarm kur' (score 1.8) → 1.0
        expect(intent.isHighConfidence, true);
      });

      test('unclear intent has confidence 0.0', () {
        final intent = IntentClassifier.classify('fwmvpz krdhjq');
        expect(intent.type, IntentType.unclear);
        expect(intent.confidence, 0.0);
      });

      test('confidence is between 0.0 and 1.0', () {
        for (final text in ['alarm kur', 'merhaba', 'teşekkürler', 'qwerty']) {
          final intent = IntentClassifier.classify(text);
          expect(intent.confidence, greaterThanOrEqualTo(0.0));
          expect(intent.confidence, lessThanOrEqualTo(1.0));
        }
      });
    });

    // ── isQuestion / isCommand ────────────────────────────────────────────
    group('isQuestion()', () {
      test('text ending with ? → true', () {
        expect(IntentClassifier.isQuestion('saat kaç?'), true);
      });

      test('"what time" → true', () {
        expect(IntentClassifier.isQuestion('what time'), true);
      });

      test('plain command → false', () {
        expect(IntentClassifier.isQuestion('alarm kur'), false);
      });
    });

    group('isCommand()', () {
      test('"alarm kur" contains command verb → true', () {
        expect(IntentClassifier.isCommand('alarm kur'), true);
      });

      test('"set alarm" → true', () {
        expect(IntentClassifier.isCommand('set alarm'), true);
      });

      test('"merhaba" → false', () {
        expect(IntentClassifier.isCommand('merhaba'), false);
      });
    });

    // ── classifyMultiple ──────────────────────────────────────────────────
    group('classifyMultiple()', () {
      test('returns multiple intents', () {
        final intents = IntentClassifier.classifyMultiple('alarm kur not al');
        expect(intents, isNotEmpty);
        expect(intents.length, lessThanOrEqualTo(3));
      });

      test('all confidences are between 0.0 and 1.0', () {
        final intents = IntentClassifier.classifyMultiple('alarm kur not al');
        for (final intent in intents) {
          expect(intent.confidence, greaterThanOrEqualTo(0.0));
          expect(intent.confidence, lessThanOrEqualTo(1.0));
        }
      });
    });
  });
}
