
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_log.dart';
import '../services/database_service.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationLog> _notifications = [];
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  List<NotificationLog> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications() async {
    _notifications = await _db.getNotificationLogs();
    notifyListeners();
  }

  Future<void> addNotification({
    required String title,
    required String body,
    String? type,
    String? payload,
  }) async {
    final notification = NotificationLog(
      id: _uuid.v4(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
      payload: payload,
    );

    await _db.insertNotificationLog(notification);
    await loadNotifications();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final updated = _notifications[index].copyWith(isRead: true);
      await _db.updateNotificationLog(updated);
      _notifications[index] = updated;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (var notification in _notifications) {
      if (!notification.isRead) {
        final updated = notification.copyWith(isRead: true);
        await _db.updateNotificationLog(updated);
      }
    }
    await loadNotifications();
  }

  Future<void> clearAll() async {
    await _db.deleteAllNotificationLogs();
    _notifications = [];
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    await _db.deleteNotificationLog(id);
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
