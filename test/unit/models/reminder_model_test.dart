import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/models/reminder.dart';

void main() {
  final baseDateTime = DateTime(2026, 3, 18, 15, 0);

  Reminder makeReminder({
    String id = 'rem-id-1',
    String title = 'Test Reminder',
    String description = '',
    bool isCompleted = false,
    String priority = 'medium',
    int orderIndex = 0,
    bool isPinned = false,
    String? voiceNotePath,
    List<Subtask> subtasks = const [],
  }) {
    return Reminder(
      id: id,
      title: title,
      description: description,
      dateTime: baseDateTime,
      isCompleted: isCompleted,
      priority: priority,
      orderIndex: orderIndex,
      isPinned: isPinned,
      voiceNotePath: voiceNotePath,
      subtasks: subtasks,
    );
  }

  Subtask makeSubtask({
    String id = 'sub-1',
    String title = 'Subtask title',
    bool isCompleted = false,
  }) {
    return Subtask(id: id, title: title, isCompleted: isCompleted);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Subtask
  // ═══════════════════════════════════════════════════════════════════════
  group('Subtask model', () {
    group('Constructor defaults', () {
      test('isCompleted defaults to false', () {
        final s = Subtask(id: '1', title: 'T');
        expect(s.isCompleted, false);
      });
    });

    group('toMap() / fromMap()', () {
      test('round-trips basic subtask', () {
        final original = makeSubtask();
        final restored = Subtask.fromMap(original.toMap());
        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.isCompleted, original.isCompleted);
      });

      test('round-trips completed subtask', () {
        final original = makeSubtask(isCompleted: true);
        final restored = Subtask.fromMap(original.toMap());
        expect(restored.isCompleted, true);
      });

      test('fromMap handles missing isCompleted gracefully', () {
        final map = {'id': '1', 'title': 'T'};
        final s = Subtask.fromMap(map);
        expect(s.isCompleted, false);
      });
    });

    group('copyWith()', () {
      test('copies without changes', () {
        final original = makeSubtask();
        final copy = original.copyWith();
        expect(copy.id, original.id);
        expect(copy.title, original.title);
        expect(copy.isCompleted, original.isCompleted);
      });

      test('overrides isCompleted', () {
        final original = makeSubtask(isCompleted: false);
        final copy = original.copyWith(isCompleted: true);
        expect(copy.isCompleted, true);
        expect(copy.title, original.title);
      });

      test('overrides title', () {
        final original = makeSubtask(title: 'Old');
        final copy = original.copyWith(title: 'New');
        expect(copy.title, 'New');
        expect(copy.id, original.id);
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Reminder
  // ═══════════════════════════════════════════════════════════════════════
  group('Reminder model', () {
    // ── Constructor defaults ─────────────────────────────────────────────
    group('Constructor defaults', () {
      test('description defaults to empty string', () {
        final r = Reminder(id: '1', title: 'T', dateTime: baseDateTime);
        expect(r.description, '');
      });

      test('isCompleted defaults to false', () {
        final r = Reminder(id: '1', title: 'T', dateTime: baseDateTime);
        expect(r.isCompleted, false);
      });

      test('priority defaults to medium', () {
        final r = Reminder(id: '1', title: 'T', dateTime: baseDateTime);
        expect(r.priority, 'medium');
      });

      test('orderIndex defaults to 0', () {
        final r = Reminder(id: '1', title: 'T', dateTime: baseDateTime);
        expect(r.orderIndex, 0);
      });

      test('isPinned defaults to false', () {
        final r = Reminder(id: '1', title: 'T', dateTime: baseDateTime);
        expect(r.isPinned, false);
      });

      test('subtasks defaults to empty list', () {
        final r = Reminder(id: '1', title: 'T', dateTime: baseDateTime);
        expect(r.subtasks, isEmpty);
      });
    });

    // ── toMap / fromMap ───────────────────────────────────────────────────
    group('toMap() / fromMap()', () {
      test('round-trips basic reminder', () {
        final original = makeReminder();
        final restored = Reminder.fromMap(original.toMap());
        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.description, original.description);
        expect(restored.dateTime, original.dateTime);
        expect(restored.isCompleted, original.isCompleted);
        expect(restored.priority, original.priority);
      });

      test('round-trips completed reminder', () {
        final original = makeReminder(isCompleted: true);
        final restored = Reminder.fromMap(original.toMap());
        expect(restored.isCompleted, true);
      });

      test('round-trips all priority levels', () {
        for (final priority in ['low', 'medium', 'high', 'urgent']) {
          final original = makeReminder(priority: priority);
          final restored = Reminder.fromMap(original.toMap());
          expect(restored.priority, priority);
        }
      });

      test('round-trips isPinned', () {
        final original = makeReminder(isPinned: true);
        final restored = Reminder.fromMap(original.toMap());
        expect(restored.isPinned, true);
      });

      test('round-trips voiceNotePath', () {
        final original = makeReminder(voiceNotePath: '/storage/voice.m4a');
        final restored = Reminder.fromMap(original.toMap());
        expect(restored.voiceNotePath, '/storage/voice.m4a');
      });

      test('round-trips subtasks list', () {
        final subtasks = [
          makeSubtask(id: 'sub-1', title: 'Step 1'),
          makeSubtask(id: 'sub-2', title: 'Step 2', isCompleted: true),
        ];
        final original = makeReminder(subtasks: subtasks);
        final restored = Reminder.fromMap(original.toMap());
        expect(restored.subtasks.length, 2);
        expect(restored.subtasks[0].title, 'Step 1');
        expect(restored.subtasks[0].isCompleted, false);
        expect(restored.subtasks[1].title, 'Step 2');
        expect(restored.subtasks[1].isCompleted, true);
      });

      test('toMap encodes isCompleted as 1/0', () {
        expect(makeReminder(isCompleted: true).toMap()['isCompleted'], 1);
        expect(makeReminder(isCompleted: false).toMap()['isCompleted'], 0);
      });

      test('toMap encodes isPinned as 1/0', () {
        expect(makeReminder(isPinned: true).toMap()['isPinned'], 1);
        expect(makeReminder(isPinned: false).toMap()['isPinned'], 0);
      });

      test('fromMap handles missing description gracefully', () {
        final map = makeReminder().toMap();
        map.remove('description');
        final r = Reminder.fromMap(map);
        expect(r.description, '');
      });

      test('fromMap handles missing priority gracefully', () {
        final map = makeReminder().toMap();
        map.remove('priority');
        final r = Reminder.fromMap(map);
        expect(r.priority, 'medium');
      });

      test('fromMap handles null subtasks gracefully', () {
        final map = makeReminder().toMap();
        map['subtasks'] = null;
        final r = Reminder.fromMap(map);
        expect(r.subtasks, isEmpty);
      });

      test('fromMap handles empty subtasks string gracefully', () {
        final map = makeReminder().toMap();
        map['subtasks'] = '';
        final r = Reminder.fromMap(map);
        expect(r.subtasks, isEmpty);
      });
    });

    // ── copyWith ──────────────────────────────────────────────────────────
    group('copyWith()', () {
      test('copies without changes', () {
        final original = makeReminder();
        final copy = original.copyWith();
        expect(copy.id, original.id);
        expect(copy.title, original.title);
        expect(copy.priority, original.priority);
      });

      test('overrides isCompleted', () {
        final original = makeReminder(isCompleted: false);
        final copy = original.copyWith(isCompleted: true);
        expect(copy.isCompleted, true);
        expect(copy.title, original.title);
      });

      test('overrides priority', () {
        final original = makeReminder(priority: 'low');
        final copy = original.copyWith(priority: 'urgent');
        expect(copy.priority, 'urgent');
      });

      test('overrides subtasks', () {
        final original = makeReminder();
        final newSubtasks = [makeSubtask(title: 'New task')];
        final copy = original.copyWith(subtasks: newSubtasks);
        expect(copy.subtasks.length, 1);
        expect(copy.subtasks.first.title, 'New task');
      });

      test('overrides isPinned', () {
        final original = makeReminder(isPinned: false);
        final copy = original.copyWith(isPinned: true);
        expect(copy.isPinned, true);
      });

      test('overrides dateTime', () {
        final newTime = DateTime(2026, 4, 1, 9, 0);
        final original = makeReminder();
        final copy = original.copyWith(dateTime: newTime);
        expect(copy.dateTime, newTime);
        expect(copy.id, original.id);
      });
    });

    // ── Computed properties ───────────────────────────────────────────────
    group('Computed properties', () {
      test('completedSubtasksCount with no subtasks is 0', () {
        final r = makeReminder();
        expect(r.completedSubtasksCount, 0);
      });

      test('totalSubtasksCount with no subtasks is 0', () {
        final r = makeReminder();
        expect(r.totalSubtasksCount, 0);
      });

      test('subtasksProgress with no subtasks is 0.0', () {
        final r = makeReminder();
        expect(r.subtasksProgress, 0.0);
      });

      test('completedSubtasksCount counts only completed subtasks', () {
        final r = makeReminder(subtasks: [
          makeSubtask(id: '1', isCompleted: true),
          makeSubtask(id: '2', isCompleted: false),
          makeSubtask(id: '3', isCompleted: true),
        ]);
        expect(r.completedSubtasksCount, 2);
      });

      test('totalSubtasksCount counts all subtasks', () {
        final r = makeReminder(subtasks: [
          makeSubtask(id: '1'),
          makeSubtask(id: '2'),
          makeSubtask(id: '3'),
        ]);
        expect(r.totalSubtasksCount, 3);
      });

      test('subtasksProgress is 0.5 when half complete', () {
        final r = makeReminder(subtasks: [
          makeSubtask(id: '1', isCompleted: true),
          makeSubtask(id: '2', isCompleted: false),
        ]);
        expect(r.subtasksProgress, 0.5);
      });

      test('subtasksProgress is 1.0 when all complete', () {
        final r = makeReminder(subtasks: [
          makeSubtask(id: '1', isCompleted: true),
          makeSubtask(id: '2', isCompleted: true),
        ]);
        expect(r.subtasksProgress, 1.0);
      });

      test('subtasksProgress is 0.0 when none complete', () {
        final r = makeReminder(subtasks: [
          makeSubtask(id: '1', isCompleted: false),
          makeSubtask(id: '2', isCompleted: false),
        ]);
        expect(r.subtasksProgress, 0.0);
      });
    });
  });
}
