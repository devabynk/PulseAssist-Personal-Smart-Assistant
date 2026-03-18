import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/models/note.dart';

void main() {
  final now = DateTime(2026, 3, 18, 10, 0);

  Note makeNote({
    String id = 'note-id-1',
    String title = 'Test Note',
    String content = 'Some content',
    String color = '#FFB74D',
    int orderIndex = 0,
    bool isPinned = false,
    bool isFullWidth = false,
    List<String> imagePaths = const [],
    String? drawingData,
    String? voiceNotePath,
    List<String> tags = const [],
  }) {
    return Note(
      id: id,
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      color: color,
      orderIndex: orderIndex,
      isPinned: isPinned,
      isFullWidth: isFullWidth,
      imagePaths: imagePaths,
      drawingData: drawingData,
      voiceNotePath: voiceNotePath,
      tags: tags,
    );
  }

  group('Note model', () {
    // ── Constructor defaults ─────────────────────────────────────────────
    group('Constructor defaults', () {
      test('color defaults to #FFB74D', () {
        final n = Note(id: '1', title: 'T', content: 'C', createdAt: now, updatedAt: now);
        expect(n.color, '#FFB74D');
      });

      test('orderIndex defaults to 0', () {
        final n = Note(id: '1', title: 'T', content: 'C', createdAt: now, updatedAt: now);
        expect(n.orderIndex, 0);
      });

      test('isPinned defaults to false', () {
        final n = Note(id: '1', title: 'T', content: 'C', createdAt: now, updatedAt: now);
        expect(n.isPinned, false);
      });

      test('isFullWidth defaults to false', () {
        final n = Note(id: '1', title: 'T', content: 'C', createdAt: now, updatedAt: now);
        expect(n.isFullWidth, false);
      });

      test('imagePaths defaults to empty list', () {
        final n = Note(id: '1', title: 'T', content: 'C', createdAt: now, updatedAt: now);
        expect(n.imagePaths, isEmpty);
      });

      test('tags defaults to empty list', () {
        final n = Note(id: '1', title: 'T', content: 'C', createdAt: now, updatedAt: now);
        expect(n.tags, isEmpty);
      });
    });

    // ── toMap / fromMap ───────────────────────────────────────────────────
    group('toMap() / fromMap()', () {
      test('round-trips basic note', () {
        final original = makeNote();
        final restored = Note.fromMap(original.toMap());

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.content, original.content);
        expect(restored.color, original.color);
        expect(restored.orderIndex, original.orderIndex);
        expect(restored.isPinned, original.isPinned);
        expect(restored.isFullWidth, original.isFullWidth);
      });

      test('round-trips dates', () {
        final original = makeNote();
        final restored = Note.fromMap(original.toMap());
        expect(restored.createdAt, original.createdAt);
        expect(restored.updatedAt, original.updatedAt);
      });

      test('round-trips tags list', () {
        final original = makeNote(tags: ['work', 'important', 'flutter']);
        final restored = Note.fromMap(original.toMap());
        expect(restored.tags, ['work', 'important', 'flutter']);
      });

      test('round-trips imagePaths list', () {
        final original = makeNote(imagePaths: ['/path/to/img1.jpg', '/path/to/img2.jpg']);
        final restored = Note.fromMap(original.toMap());
        expect(restored.imagePaths, ['/path/to/img1.jpg', '/path/to/img2.jpg']);
      });

      test('round-trips empty tags and imagePaths', () {
        final original = makeNote();
        final restored = Note.fromMap(original.toMap());
        expect(restored.tags, isEmpty);
        expect(restored.imagePaths, isEmpty);
      });

      test('round-trips isPinned = true', () {
        final original = makeNote(isPinned: true);
        final restored = Note.fromMap(original.toMap());
        expect(restored.isPinned, true);
      });

      test('round-trips drawingData', () {
        final original = makeNote(drawingData: '{"strokes":[]}');
        final restored = Note.fromMap(original.toMap());
        expect(restored.drawingData, '{"strokes":[]}');
      });

      test('round-trips voiceNotePath', () {
        final original = makeNote(voiceNotePath: '/storage/voice.m4a');
        final restored = Note.fromMap(original.toMap());
        expect(restored.voiceNotePath, '/storage/voice.m4a');
      });

      test('toMap encodes isPinned as 1/0', () {
        expect(makeNote(isPinned: true).toMap()['isPinned'], 1);
        expect(makeNote(isPinned: false).toMap()['isPinned'], 0);
      });

      test('toMap encodes isFullWidth as 1/0', () {
        expect(makeNote(isFullWidth: true).toMap()['isFullWidth'], 1);
        expect(makeNote(isFullWidth: false).toMap()['isFullWidth'], 0);
      });

      test('fromMap with null imagePaths returns empty list', () {
        final map = makeNote().toMap();
        map['imagePaths'] = null;
        final note = Note.fromMap(map);
        expect(note.imagePaths, isEmpty);
      });

      test('fromMap with null tags returns empty list', () {
        final map = makeNote().toMap();
        map['tags'] = null;
        final note = Note.fromMap(map);
        expect(note.tags, isEmpty);
      });

      test('fromMap uses default color if missing', () {
        final map = makeNote().toMap();
        map['color'] = null;
        final note = Note.fromMap(map);
        expect(note.color, '#FFB74D');
      });
    });

    // ── copyWith ──────────────────────────────────────────────────────────
    group('copyWith()', () {
      test('copies all fields when nothing overridden', () {
        final original = makeNote();
        final copy = original.copyWith();
        expect(copy.id, original.id);
        expect(copy.title, original.title);
        expect(copy.content, original.content);
        expect(copy.color, original.color);
      });

      test('overrides title', () {
        final original = makeNote(title: 'Old Title');
        final copy = original.copyWith(title: 'New Title');
        expect(copy.title, 'New Title');
        expect(copy.content, original.content);
      });

      test('overrides content', () {
        final original = makeNote(content: 'Old');
        final copy = original.copyWith(content: 'New content here');
        expect(copy.content, 'New content here');
        expect(copy.id, original.id);
      });

      test('overrides isPinned', () {
        final original = makeNote(isPinned: false);
        final copy = original.copyWith(isPinned: true);
        expect(copy.isPinned, true);
        expect(copy.title, original.title);
      });

      test('overrides color', () {
        final original = makeNote(color: '#FFB74D');
        final copy = original.copyWith(color: '#42A5F5');
        expect(copy.color, '#42A5F5');
      });

      test('overrides tags', () {
        final original = makeNote(tags: ['old']);
        final copy = original.copyWith(tags: ['new', 'tags']);
        expect(copy.tags, ['new', 'tags']);
      });

      test('overrides orderIndex', () {
        final original = makeNote(orderIndex: 0);
        final copy = original.copyWith(orderIndex: 5);
        expect(copy.orderIndex, 5);
      });
    });
  });
}
