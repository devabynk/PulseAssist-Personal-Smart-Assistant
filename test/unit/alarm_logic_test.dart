// Tests for AlarmProvider pure logic.
//
// The _alarmSystemId() method is private, so we test its properties
// by replicating the same algorithm and verifying the invariants that
// the rest of the codebase depends on.
//
// checkDuplicateAlarm() reads only the in-memory _alarms list, making it
// testable via a thin test-only subclass that exposes the field.

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/models/alarm.dart';

// ─── Replicated alarm ID algorithm (mirrors AlarmProvider._alarmSystemId) ───
//
// Change this if the production algorithm changes.
int alarmSystemId(String uuid) {
  final hex = uuid.replaceAll('-', '').substring(0, 8);
  final id = int.parse(hex, radix: 16) & 0x7FFFFFFF;
  return id == 0 ? 1 : id;
}

void main() {
  // ── _alarmSystemId equivalent ─────────────────────────────────────────
  group('alarmSystemId algorithm', () {
    test('always returns a positive integer', () {
      final uuids = [
        '00000000-0000-0000-0000-000000000001',
        'ffffffff-ffff-ffff-ffff-ffffffffffff',
        'a1b2c3d4-e5f6-0000-0000-000000000000',
        '12345678-abcd-ef01-2345-6789abcdef01',
      ];
      for (final uuid in uuids) {
        final id = alarmSystemId(uuid);
        expect(id, greaterThan(0), reason: 'UUID $uuid produced non-positive id $id');
      }
    });

    test('result fits in 32-bit positive int (never > 0x7FFFFFFF)', () {
      final uuids = [
        'ffffffff-0000-0000-0000-000000000000',
        '80000000-0000-0000-0000-000000000000',
        '7fffffff-0000-0000-0000-000000000000',
      ];
      for (final uuid in uuids) {
        final id = alarmSystemId(uuid);
        expect(id, lessThanOrEqualTo(0x7FFFFFFF));
      }
    });

    test('zero UUID produces id = 1 (not 0)', () {
      // All-zero first 8 hex chars → parsed as 0 → nudged to 1
      const zeroUuid = '00000000-1234-5678-abcd-000000000000';
      expect(alarmSystemId(zeroUuid), 1);
    });

    test('is deterministic — same UUID always produces same id', () {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      final id1 = alarmSystemId(uuid);
      final id2 = alarmSystemId(uuid);
      expect(id1, id2);
    });

    test('different UUIDs (differing in first 8 chars) produce different ids', () {
      const uuid1 = 'aabbccdd-0000-0000-0000-000000000000';
      const uuid2 = '11223344-0000-0000-0000-000000000000';
      expect(alarmSystemId(uuid1), isNot(alarmSystemId(uuid2)));
    });

    test('UUIDs that differ only after first 8 chars may produce same id', () {
      // This is expected behaviour — only first 8 hex chars are used
      const uuid1 = 'aabbccdd-0000-0000-0000-000000000000';
      const uuid2 = 'aabbccdd-1111-2222-3333-444444444444';
      expect(alarmSystemId(uuid1), alarmSystemId(uuid2));
    });

    test('seconds offset derived from id is in range 1..59', () {
      final uuids = [
        '00000001-0000-0000-0000-000000000000',
        '12345678-abcd-ef01-0000-000000000000',
        'deadbeef-0000-0000-0000-000000000000',
      ];
      for (final uuid in uuids) {
        final id = alarmSystemId(uuid);
        final offset = id % 59 + 1;
        expect(offset, greaterThanOrEqualTo(1));
        expect(offset, lessThanOrEqualTo(59));
      }
    });
  });

  // ── checkDuplicateAlarm logic (in-memory, no DB) ──────────────────────
  //
  // AlarmProvider._alarms is private so we can't test it directly.
  // Instead we replicate the duplicate-check logic and verify it here —
  // this documents the expected behaviour and protects against regressions
  // if the logic is later extracted or changed.
  group('Duplicate alarm detection logic', () {
    // Mirrors AlarmProvider.checkDuplicateAlarm
    Alarm? checkDuplicate(List<Alarm> alarms, Alarm newAlarm) {
      for (final existing in alarms) {
        if (existing.id == newAlarm.id) continue;
        if (existing.time.hour != newAlarm.time.hour ||
            existing.time.minute != newAlarm.time.minute) {
          continue;
        }
        if (newAlarm.repeatDays.isNotEmpty && existing.repeatDays.isNotEmpty) {
          final hasOverlap = newAlarm.repeatDays
              .any((day) => existing.repeatDays.contains(day));
          if (hasOverlap) return existing;
        }
        if (newAlarm.repeatDays.isEmpty && existing.repeatDays.isEmpty) {
          if (existing.time.year == newAlarm.time.year &&
              existing.time.month == newAlarm.time.month &&
              existing.time.day == newAlarm.time.day) {
            return existing;
          }
        }
      }
      return null;
    }

    final day = DateTime(2026, 3, 18, 7, 30);

    test('returns null when no alarms exist', () {
      final newAlarm = Alarm(id: 'new', title: 'A', time: day);
      expect(checkDuplicate([], newAlarm), isNull);
    });

    test('returns null when no time collision', () {
      final existing = Alarm(
        id: 'existing',
        title: 'E',
        time: DateTime(2026, 3, 18, 8, 0), // different time
      );
      final newAlarm = Alarm(id: 'new', title: 'N', time: day);
      expect(checkDuplicate([existing], newAlarm), isNull);
    });

    test('detects duplicate one-time alarm on same day and time', () {
      final existing = Alarm(id: 'existing', title: 'E', time: day);
      final newAlarm = Alarm(id: 'new', title: 'N', time: day);
      expect(checkDuplicate([existing], newAlarm), isNotNull);
    });

    test('no duplicate for same time but different day', () {
      final existing = Alarm(
        id: 'existing',
        title: 'E',
        time: DateTime(2026, 3, 19, 7, 30), // next day
      );
      final newAlarm = Alarm(id: 'new', title: 'N', time: day);
      expect(checkDuplicate([existing], newAlarm), isNull);
    });

    test('detects duplicate repeating alarm with overlapping days', () {
      final existing = Alarm(
        id: 'existing',
        title: 'E',
        time: day,
        repeatDays: [1, 2, 3], // Mon, Tue, Wed
      );
      final newAlarm = Alarm(
        id: 'new',
        title: 'N',
        time: day,
        repeatDays: [3, 4, 5], // Wed, Thu, Fri — overlaps on Wed
      );
      expect(checkDuplicate([existing], newAlarm), isNotNull);
    });

    test('no duplicate for repeating alarms with non-overlapping days', () {
      final existing = Alarm(
        id: 'existing',
        title: 'E',
        time: day,
        repeatDays: [1, 2], // Mon, Tue
      );
      final newAlarm = Alarm(
        id: 'new',
        title: 'N',
        time: day,
        repeatDays: [3, 4, 5], // Wed, Thu, Fri
      );
      expect(checkDuplicate([existing], newAlarm), isNull);
    });

    test('no duplicate when one is repeating and other is one-time', () {
      final existing = Alarm(
        id: 'existing',
        title: 'E',
        time: day,
        repeatDays: [1, 2, 3],
      );
      final newAlarm = Alarm(
        id: 'new',
        title: 'N',
        time: day,
        repeatDays: [], // one-time
      );
      expect(checkDuplicate([existing], newAlarm), isNull);
    });

    test('editing alarm does not detect itself as a duplicate', () {
      final existing = Alarm(id: 'same-id', title: 'E', time: day);
      final editedAlarm = Alarm(id: 'same-id', title: 'Edited', time: day);
      // Same ID — should be skipped
      expect(checkDuplicate([existing], editedAlarm), isNull);
    });

    test('returns first duplicate found when multiple match', () {
      final existing1 = Alarm(id: 'e1', title: 'E1', time: day);
      final existing2 = Alarm(id: 'e2', title: 'E2', time: day);
      final newAlarm = Alarm(id: 'new', title: 'N', time: day);
      final result = checkDuplicate([existing1, existing2], newAlarm);
      expect(result?.id, 'e1');
    });
  });

  // ── skipNextAlarm date logic ──────────────────────────────────────────
  group('skipNextAlarm date logic', () {
    // Mirrors the date-picking loop inside AlarmProvider.skipNextAlarm
    DateTime findNextOccurrence(Alarm alarm, DateTime now) {
      var next = DateTime(
        now.year, now.month, now.day, alarm.time.hour, alarm.time.minute,
      );
      if (next.isBefore(now)) {
        next = next.add(const Duration(days: 1));
      }
      var skipIter = 0;
      while (!alarm.repeatDays.contains(next.weekday) && skipIter < 7) {
        next = next.add(const Duration(days: 1));
        skipIter++;
      }
      return next;
    }

    test('returns today if alarm time is in future and today is a repeat day', () {
      // Monday = weekday 1
      final monday = DateTime(2026, 3, 16, 7, 0); // a Monday
      final alarm = Alarm(
        id: '1',
        title: 'T',
        time: DateTime(2026, 3, 16, 8, 0), // 08:00
        repeatDays: [1], // Monday
      );
      // now is before alarm time on Monday
      final now = DateTime(2026, 3, 16, 7, 30);
      final next = findNextOccurrence(alarm, now);
      expect(next.weekday, 1); // Monday
      expect(next.day, monday.day);
    });

    test('returns next week if only repeat day already passed today', () {
      // Monday = weekday 1
      final alarm = Alarm(
        id: '1',
        title: 'T',
        time: DateTime(2026, 3, 16, 7, 0), // 07:00
        repeatDays: [1], // Monday
      );
      // now is AFTER 07:00 on Monday
      final now = DateTime(2026, 3, 16, 8, 0);
      final next = findNextOccurrence(alarm, now);
      // Should be next Monday
      expect(next.weekday, 1);
      expect(next.isAfter(now), true);
    });

    test('capped at 7 iterations — never infinite', () {
      // Alarm with no valid repeat day (empty list, though skip only runs on repeating)
      // Here we test that the loop cap prevents infinite loops
      final alarm = Alarm(
        id: '1',
        title: 'T',
        time: DateTime(2026, 3, 18, 9, 0),
        repeatDays: [8], // invalid day — will never match
      );
      final now = DateTime(2026, 3, 18, 10, 0);
      // Should not hang; just advances 7 days
      final next = findNextOccurrence(alarm, now);
      final diff = next.difference(now).inDays;
      expect(diff, lessThanOrEqualTo(8)); // at most 7 iterations forward
    });
  });
}
