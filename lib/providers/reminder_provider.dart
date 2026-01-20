import 'package:flutter/foundation.dart';
import '../models/reminder.dart';
import '../services/database_service.dart';
import '../services/widget_service.dart';

class ReminderProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  List<Reminder> get reminders => _reminders;
  List<Reminder> get pendingReminders => _reminders.where((r) => !r.isCompleted).toList();
  List<Reminder> get completedReminders => _reminders.where((r) => r.isCompleted).toList();
  bool get isLoading => _isLoading;

  ReminderProvider() {
    loadReminders();
  }

  Future<void> loadReminders() async {
    _isLoading = true;
    notifyListeners();
    
    final reminders = await _db.getReminders();
    _reminders = reminders;
    _isLoading = false;
    notifyListeners();
    // Update all reminder widgets
    await WidgetService.updateRemindersListWidget(reminders);
    await WidgetService.updateSingleReminderWidget(reminders);
  }

  Future<void> addReminder(Reminder reminder) async {
    await _db.insertReminder(reminder);
    await loadReminders();
  }

  Future<void> updateReminder(Reminder reminder) async {
    await _db.updateReminder(reminder);
    await loadReminders();
  }

  Future<void> deleteReminder(Reminder reminder) async {
    await _db.deleteReminder(reminder.id);
    await loadReminders();
  }

  Future<void> toggleComplete(Reminder reminder) async {
    final updated = Reminder(
      id: reminder.id,
      title: reminder.title,
      description: reminder.description,
      dateTime: reminder.dateTime,
      priority: reminder.priority,
      isCompleted: !reminder.isCompleted,
    );
    await updateReminder(updated);
  }
}
