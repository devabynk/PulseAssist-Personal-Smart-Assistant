import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/models/alarm.dart';

void main() {
  final baseTime = DateTime(2026, 3, 18, 7, 30);

  Alarm makeAlarm({
    String id = 'test-uuid-1234',
    String title = 'Test Alarm',
    bool isActive = true,
    List<int> repeatDays = const [],
    List<DateTime> skippedDates = const [],
    String? soundPath,
    String? soundName,
  }) {
    return Alarm(
      id: id,
      title: title,
      time: baseTime,
      isActive: isActive,
      repeatDays: repeatDays,
      skippedDates: skippedDates,
      soundPath: soundPath,
      soundName: soundName,
    );
  }

  group('Alarm model', () {
    // ── Construction defaults ─────────────────────────────────────────────
    group('Constructor defaults', () {
      test('isActive defaults to true', () {
        final a = Alarm(id: '1', title: 'A', time: baseTime);
        expect(a.isActive, true);
      });

      test('repeatDays defaults to empty list', () {
        final a = Alarm(id: '1', title: 'A', time: baseTime);
        expect(a.repeatDays, isEmpty);
      });

      test('skippedDates defaults to empty list', () {
        final a = Alarm(id: '1', title: 'A', time: baseTime);
        expect(a.skippedDates, isEmpty);
      });

      test('soundPath defaults to null', () {
        final a = Alarm(id: '1', title: 'A', time: baseTime);
        expect(a.soundPath, isNull);
      });
    });

    // ── toMap / fromMap ───────────────────────────────────────────────────
    group('toMap() / fromMap()', () {
      test('round-trips basic alarm', () {
        final original = makeAlarm();
        final map = original.toMap();
        final restored = Alarm.fromMap(map);

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.time, original.time);
        expect(restored.isActive, original.isActive);
        expect(restored.repeatDays, original.repeatDays);
        expect(restored.skippedDates, original.skippedDates);
      });

      test('round-trips alarm with repeatDays', () {
        final original = makeAlarm(repeatDays: [1, 2, 3, 4, 5]);
        final restored = Alarm.fromMap(original.toMap());
        expect(restored.repeatDays, [1, 2, 3, 4, 5]);
      });

      test('round-trips alarm with skippedDates', () {
        final skipped = [DateTime(2026, 3, 20), DateTime(2026, 3, 21)];
        final original = makeAlarm(skippedDates: skipped);
        final restored = Alarm.fromMap(original.toMap());
        expect(restored.skippedDates.length, 2);
        expect(restored.skippedDates[0].year, 2026);
        expect(restored.skippedDates[0].month, 3);
        expect(restored.skippedDates[0].day, 20);
      });

      test('round-trips inactive alarm', () {
        final original = makeAlarm(isActive: false);
        final restored = Alarm.fromMap(original.toMap());
        expect(restored.isActive, false);
      });

      test('round-trips sound path and name', () {
        final original = makeAlarm(
          soundPath: 'assets/alarm.mp3',
          soundName: 'Default',
        );
        final restored = Alarm.fromMap(original.toMap());
        expect(restored.soundPath, 'assets/alarm.mp3');
        expect(restored.soundName, 'Default');
      });

      test('toMap encodes isActive as 1/0', () {
        expect(makeAlarm(isActive: true).toMap()['isActive'], 1);
        expect(makeAlarm(isActive: false).toMap()['isActive'], 0);
      });

      test('toMap encodes empty repeatDays as empty string', () {
        final map = makeAlarm().toMap();
        expect(map['repeatDays'], '');
      });

      test('toMap encodes repeatDays as comma-separated string', () {
        final map = makeAlarm(repeatDays: [1, 2, 3]).toMap();
        expect(map['repeatDays'], '1,2,3');
      });

      test('fromMap handles null skippedDates gracefully', () {
        final map = makeAlarm().toMap();
        map['skippedDates'] = null;
        final alarm = Alarm.fromMap(map);
        expect(alarm.skippedDates, isEmpty);
      });

      test('fromMap handles empty skippedDates string', () {
        final map = makeAlarm().toMap();
        map['skippedDates'] = '';
        final alarm = Alarm.fromMap(map);
        expect(alarm.skippedDates, isEmpty);
      });
    });

    // ── copyWith ──────────────────────────────────────────────────────────
    group('copyWith()', () {
      test('copies all fields if nothing specified', () {
        final original = makeAlarm();
        final copy = original.copyWith();
        expect(copy.id, original.id);
        expect(copy.title, original.title);
        expect(copy.time, original.time);
        expect(copy.isActive, original.isActive);
      });

      test('overrides title only', () {
        final original = makeAlarm(title: 'Old');
        final copy = original.copyWith(title: 'New');
        expect(copy.title, 'New');
        expect(copy.id, original.id);
      });

      test('overrides isActive only', () {
        final original = makeAlarm(isActive: true);
        final copy = original.copyWith(isActive: false);
        expect(copy.isActive, false);
        expect(copy.title, original.title);
      });

      test('overrides repeatDays only', () {
        final original = makeAlarm();
        final copy = original.copyWith(repeatDays: [1, 2, 3, 4, 5]);
        expect(copy.repeatDays, [1, 2, 3, 4, 5]);
        expect(copy.title, original.title);
      });

      test('overrides skippedDates only', () {
        final skipped = [DateTime(2026, 3, 20)];
        final original = makeAlarm();
        final copy = original.copyWith(skippedDates: skipped);
        expect(copy.skippedDates.length, 1);
        expect(copy.repeatDays, original.repeatDays);
      });

      test('overrides soundPath and soundName', () {
        final original = makeAlarm();
        final copy = original.copyWith(
          soundPath: 'assets/bell.mp3',
          soundName: 'Bell',
        );
        expect(copy.soundPath, 'assets/bell.mp3');
        expect(copy.soundName, 'Bell');
      });
    });
  });
}
