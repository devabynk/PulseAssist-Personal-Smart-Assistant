import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../services/widget_service.dart';

class NoteProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  
  List<Note> _notes = [];
  bool _isLoading = true;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  NoteProvider() {
    loadNotes();
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    final notes = await _db.getNotes();
    _notes = notes;
    _isLoading = false;
    notifyListeners();
    // Update all note widgets
    await WidgetService.updateWidget(notes);
    await WidgetService.updateNotesListWidget(notes);
    await WidgetService.updateSingleNoteWidget(notes);
  }

  Future<void> addNote(Note note) async {
    await _db.insertNote(note);
    await loadNotes();
  }

  Future<void> updateNote(Note note) async {
    await _db.updateNote(note);
    await loadNotes();
  }

  Future<void> deleteNote(Note note) async {
    await _db.deleteNote(note.id);
    await loadNotes();
  }

  Future<void> reorderNotes(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final Note item = _notes.removeAt(oldIndex);
    _notes.insert(newIndex, item);
    notifyListeners(); // Optimistic update
    
    await _db.updateNoteOrder(_notes);
    // Update all note widgets
    await WidgetService.updateWidget(_notes);
    await WidgetService.updateNotesListWidget(_notes);
    await WidgetService.updateSingleNoteWidget(_notes);
  }
}
