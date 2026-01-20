import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/settings_provider.dart';
import '../providers/alarm_provider.dart';
import '../providers/note_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/notification_provider.dart';
import '../models/alarm.dart';
import '../models/note.dart';
import '../models/reminder.dart';
import '../theme/app_theme.dart';
import '../widgets/quill_note_viewer.dart';
import '../utils/extensions.dart';
import '../models/notification_log.dart';
import '../providers/weather_provider.dart';
import '../widgets/location_selector_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToChatbot;
  final VoidCallback? onNavigateToAlarm;
  final VoidCallback? onNavigateToNotes;
  final VoidCallback? onNavigateToReminders;
  
  const DashboardScreen({
    super.key,
    this.onNavigateToChatbot,
    this.onNavigateToAlarm,
    this.onNavigateToNotes,
    this.onNavigateToReminders,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final bool _isFirstLoad = true;
  
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data whenever dashboard becomes visible
    _refreshData();
  }

  void _refreshData() {
    // Always refresh to get latest data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<AlarmProvider>(context, listen: false).loadAlarms();
      Provider.of<NoteProvider>(context, listen: false).loadNotes();
      Provider.of<ReminderProvider>(context, listen: false).loadReminders();
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
    });
  }

  String _getGreeting(bool isTurkish) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return isTurkish ? 'Günaydın' : 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return isTurkish ? 'İyi Günler' : 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return isTurkish ? 'İyi Akşamlar' : 'Good Evening';
    } else {
      return isTurkish ? 'İyi Geceler' : 'Good Night';
    }
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return Icons.wb_sunny;
    } else if (hour >= 12 && hour < 17) {
      return Icons.wb_sunny_outlined;
    } else if (hour >= 17 && hour < 21) {
      return Icons.nights_stay_outlined;
    } else {
      return Icons.nights_stay;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isTurkish = settings.locale.languageCode == 'tr';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = settings.userName ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Main Content
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting
              _buildHeader(isTurkish, userName, isDark),
              const SizedBox(height: 24),
              
              // Quick Actions
              _buildQuickActions(isTurkish),
              const SizedBox(height: 20),
              
              // Weather Card (moved above AI chat)
              _buildWeatherCard(isTurkish, isDark),
              const SizedBox(height: 16),
              
              // AI Chatbot Card
              _buildAIChatbotCard(isTurkish, isDark),
              const SizedBox(height: 16),
              
              // Alarm & Tasks Row
              _buildAlarmTasksRow(isTurkish, isDark),
              const SizedBox(height: 16),
              
              // Recent Notes
              _buildRecentNotes(isTurkish, isDark),
              const SizedBox(height: 80), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTurkish, String userName, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getGreetingIcon(),
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _getGreeting(isTurkish),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              userName.isNotEmpty ? userName : 'PulseAssist',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: (Theme.of(context).textTheme.headlineMedium?.fontSize ?? 28) - 3,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                final unreadCount = notificationProvider.unreadCount;
                
                return GestureDetector(
                  onTap: () => _showNotifications(context, isTurkish, notificationProvider),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(bool isTurkish) {
    return Row(
      children: [
        _buildQuickActionButton(
          icon: Icons.smart_toy,
          label: isTurkish ? 'Asistan' : 'Assistant',
          color: AppColors.primary,
          onTap: widget.onNavigateToChatbot,
        ),
        const SizedBox(width: 12),
        _buildQuickActionButton(
          icon: Icons.note_alt,
          label: isTurkish ? 'Not' : 'Note',
          color: Colors.amber,
          onTap: widget.onNavigateToNotes,
        ),
        const SizedBox(width: 12),
        _buildQuickActionButton(
          icon: Icons.alarm,
          label: isTurkish ? 'Alarm' : 'Alarm',
          color: Colors.purple,
          onTap: widget.onNavigateToAlarm,
        ),
        const SizedBox(width: 12),
        _buildQuickActionButton(
          icon: Icons.notifications,
          label: isTurkish ? 'Hatırlat' : 'Remind',
          color: Colors.teal,
          onTap: widget.onNavigateToReminders,
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIChatbotCard(bool isTurkish, bool isDark) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final lastMessage = chatProvider.messages.isNotEmpty 
            ? chatProvider.messages.last 
            : null;
        
        return GestureDetector(
          onTap: widget.onNavigateToChatbot,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                    ? [const Color(0xFF1E3A5F), const Color(0xFF2D1B4E)]
                    : [AppColors.primary.withAlpha(40), Colors.purple.withAlpha(30)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTurkish ? 'AI Sohbet' : 'AI Chat',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isTurkish ? 'Aktif' : 'Active',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sohbete Dön butonu sağda
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isTurkish ? 'Sohbete Dön' : 'Go to Chat',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, color: AppColors.primary, size: 16),
                      ],
                    ),
                  ],
                ),
                if (lastMessage != null && !lastMessage.isUser) ...[ 
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity, // Full width
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTurkish ? 'Son yanıt' : 'Last response',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastMessage.content.length > 60 
                              ? '${lastMessage.content.substring(0, 60)}...' 
                              : lastMessage.content,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlarmTasksRow(bool isTurkish, bool isDark) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Next Alarm Card
          Expanded(
            child: Consumer<AlarmProvider>(
              builder: (context, alarmProvider, child) {
                final activeAlarms = alarmProvider.alarms.where((a) => a.isActive).toList();
                Alarm? nextAlarm;
                if (activeAlarms.isNotEmpty) {
                  activeAlarms.sort((a, b) => a.time.compareTo(b.time));
                  nextAlarm = activeAlarms.first;
                }
                
                return GestureDetector(
                  onTap: widget.onNavigateToAlarm,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDark ? null : [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.alarm, color: isDark ? Colors.purpleAccent[100] : Colors.purple, size: 24),
                            if (nextAlarm != null)
                              SizedBox(
                                height: 24,
                                child: Switch(
                                  value: nextAlarm.isActive,
                                  onChanged: (value) {
                                    alarmProvider.toggleAlarm(nextAlarm!);
                                  },
                                  activeThumbColor: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextAlarm != null 
                                  ? DateFormat('HH:mm').format(nextAlarm.time)
                                  : '--:--',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              nextAlarm?.title ?? (isTurkish ? 'Alarm yok' : 'No alarm'),
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Tasks Summary Card
          Expanded(
            child: Consumer<ReminderProvider>(
              builder: (context, reminderProvider, child) {
                final total = reminderProvider.reminders.length;
                final completed = reminderProvider.reminders.where((r) => r.isCompleted).length;
                final remaining = total - completed;
                
                return GestureDetector(
                  onTap: widget.onNavigateToReminders,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDark ? null : [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.check_circle_outline, color: isDark ? Colors.tealAccent[100] : Colors.teal, size: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.tealAccent : Colors.teal).withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isTurkish ? 'BUGÜN' : 'TODAY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.tealAccent[100] : Colors.teal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Row(
                              textBaseline: TextBaseline.alphabetic,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              children: [
                                Text(
                                  '$completed',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[400],
                                  ),
                                ),
                                Text(
                                  '/$total',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: total > 0 ? completed / total : 0,
                                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$remaining ${isTurkish ? 'görev kaldı' : 'tasks left'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentNotes(bool isTurkish, bool isDark) {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        final recentNotes = noteProvider.notes.take(2).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isTurkish ? 'Son Notlar' : 'Recent Notes',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: widget.onNavigateToNotes,
                  child: Icon(Icons.arrow_forward, color: Theme.of(context).iconTheme.color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentNotes.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isTurkish ? 'Henüz not yok' : 'No notes yet',
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ),
              )
            else
              ...recentNotes.map((note) => _buildNoteItem(note, isTurkish)),
          ],
        );
      },
    );
  }

  Widget _buildNoteItem(Note note, bool isTurkish) {
    Color color;
    try {
      final hexCode = note.color.replaceAll('#', '');
      color = Color(int.parse(hexCode, radix: 16) | 0xFF000000);
    } catch (e) {
      color = Colors.grey;
    }
    final timeDiff = DateTime.now().difference(note.updatedAt);
    String timeAgo;
    if (timeDiff.inMinutes < 60) {
      timeAgo = '${timeDiff.inMinutes}${isTurkish ? 'dk' : 'm'}';
    } else if (timeDiff.inHours < 24) {
      timeAgo = '${timeDiff.inHours}${isTurkish ? 's' : 'h'}';
    } else {
      timeAgo = '${timeDiff.inDays}${isTurkish ? 'g' : 'd'}';
    }
    
    return GestureDetector(
      onTap: widget.onNavigateToNotes,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (note.isPinned)
                        Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.push_pin, size: 12, color: Colors.amber),
                        ),
                      Expanded(
                        child: Text(
                          note.title.isEmpty ? (isTurkish ? 'Başlıksız' : 'Untitled') : note.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: QuillNoteViewer(
                          content: note.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (note.imagePaths.isNotEmpty) ...[
                        SizedBox(width: 4),
                        Icon(Icons.image, size: 12, color: Theme.of(context).hintColor),
                      ],
                      if (note.voiceNotePath != null) ...[
                        SizedBox(width: 4),
                        Icon(Icons.mic, size: 12, color: Colors.blue),
                      ],
                      if (note.tags.isNotEmpty) ...[
                        SizedBox(width: 4),
                        Icon(Icons.tag, size: 12, color: Colors.green),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              timeAgo,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return AppColors.priorityHigh;
      case 'medium':
        return AppColors.priorityMedium;
      case 'low':
        return AppColors.priorityLow;
      default:
        return AppColors.primary;
    }
  }
  
  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return Icons.warning;
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.remove;
    }
  }
  
  String _getPriorityLabel(String priority, bool isTurkish) {
    switch (priority) {
      case 'urgent':
        return isTurkish ? 'ACİL' : 'URGENT';
      case 'high':
        return isTurkish ? 'YÜKSEK' : 'HIGH';
      case 'medium':
        return isTurkish ? 'ORTA' : 'MED';
      case 'low':
        return isTurkish ? 'DÜŞÜK' : 'LOW';
      default:
        return '';
    }
  }

  void _showNotifications(BuildContext context, bool isTurkish, NotificationProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                // Sort by timestamp descending
                final notifications = List.from(provider.notifications)
                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.l10n.notifications,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (notifications.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                provider.clearAll();
                                Navigator.pop(context);
                              },
                              child: Text(
                                context.l10n.clearAll, 
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (notifications.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined, size: 64, color: Theme.of(context).hintColor),
                              const SizedBox(height: 16),
                              Text(
                                context.l10n.noNotifications,
                                style: TextStyle(color: Theme.of(context).hintColor),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            return _buildNotificationItem(notification, isTurkish);
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      provider.markAllAsRead();
    });
  }

  Widget _buildNotificationItem(NotificationLog notification, bool isTurkish) {
    final dateFormat = DateFormat('dd MMM HH:mm', isTurkish ? 'tr' : 'en');
    
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        Provider.of<NotificationProvider>(context, listen: false)
            .deleteNotification(notification.id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: notification.isRead 
              ? Colors.transparent 
              : Theme.of(context).primaryColor.withAlpha(10),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withAlpha(50),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        dateFormat.format(notification.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'alarm':
        return Icons.alarm;
      case 'reminder':
        return Icons.notifications_active;
      case 'system':
        return Icons.info_outline;
      case 'update':
        return Icons.system_update;
      default:
        return Icons.notifications;
    }
  }

  Widget _buildWeatherCard(bool isTurkish, bool isDark) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        final weather = weatherProvider.currentWeather;
        final forecast = weatherProvider.forecast;
        final isExpanded = weatherProvider.isExpanded;
        final l10n = context.l10n;

        return Container(
          width: double.infinity, // Full width
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: weather != null 
                  ? _getWeatherGradient(weather.description, isDark)
                  : (isDark
                      ? [Color(0xFF1E3A8A), Color(0xFF3B82F6)]
                      : [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.blue.withAlpha(50),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: weatherProvider.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : weather == null
                  ? GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const LocationSelectorDialog(),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.wb_sunny_outlined,
                              size: 48,
                              color: Colors.white.withAlpha(200),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.selectLocation,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isTurkish
                                  ? 'Hava durumu görmek için dokunun'
                                  : 'Tap to see weather',
                              style: TextStyle(
                                color: Colors.white.withAlpha(180),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Header with location and action buttons
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.white.withAlpha(200),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  weather.cityName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Refresh button
                              IconButton(
                                icon: Icon(Icons.refresh, color: Colors.white.withAlpha(200), size: 22),
                                onPressed: () {
                                  if (weatherProvider.selectedLocation != null) {
                                    final locale = Localizations.localeOf(context).languageCode;
                                    weatherProvider.fetchWeather(weatherProvider.selectedLocation!, language: locale);
                                  }
                                },
                                padding: EdgeInsets.all(8),
                                constraints: BoxConstraints(),
                              ),
                              // Change location button
                              IconButton(
                                icon: Icon(Icons.edit_location, color: Colors.white.withAlpha(200), size: 22),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const LocationSelectorDialog(),
                                  );
                                },
                                padding: EdgeInsets.all(8),
                                constraints: BoxConstraints(),
                              ),
                              // Expand/Collapse button
                              IconButton(
                                icon: Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: Colors.white.withAlpha(200),
                                  size: 24,
                                ),
                                onPressed: () => weatherProvider.toggleExpand(),
                                padding: EdgeInsets.all(8),
                                constraints: BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        
                        // Current weather
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              // Temperature
                              Text(
                                '${weather.temperature.round()}°',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Description and details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _translateWeatherCondition(weather.description, isTurkish),
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(240),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.thermostat, color: Colors.white.withAlpha(200), size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${weather.feelsLike.round()}°',
                                          style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 13),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(Icons.water_drop, color: Colors.white.withAlpha(200), size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${weather.humidity}%',
                                          style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 13),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(Icons.air, color: Colors.white.withAlpha(200), size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${weather.windSpeed.round()} km/h',
                                          style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Hourly Forecast (Next 24h)
                        if (isExpanded && weatherProvider.hourlyForecast != null && weatherProvider.hourlyForecast!.isNotEmpty)
                          Container(
                            height: 100,
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: weatherProvider.hourlyForecast!.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final hour = weatherProvider.hourlyForecast![index];
                                final time = hour['time'];
                                final temp = hour['temp'];
                                final condition = hour['condition'];
                                final icon = hour['icon'];
                                
                                // Dynamic color for each hour
                                final hourGradient = _getWeatherGradient(condition, isDark);
                                
                                return Container(
                                  width: 70,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: hourGradient.map((c) => c.withOpacity(0.8)).toList(),
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(20),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        time,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      CachedNetworkImage(
                                        imageUrl: icon,
                                        width: 32,
                                        height: 32,
                                        placeholder: (context, url) => const SizedBox(width: 32, height: 32),
                                        errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white, size: 20),
                                      ),
                                      Text(
                                        '${temp.round()}°',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        
                        // 3-day forecast (shown when expanded)
                        if (isExpanded && forecast != null && forecast.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: forecast.map((day) {
                                final date = DateTime.parse(day['date']);
                                final dayName = _getDayName(date, isTurkish);
                                return Column(
                                  children: [
                                    Text(
                                      dayName,
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(200),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${day['maxTemp'].round()}°',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${day['minTemp'].round()}°',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(180),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
        );
      },
    );
  }

  String _getDayName(DateTime date, bool isTurkish) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == today) {
      return isTurkish ? 'Bugün' : 'Today';
    } else if (targetDate == today.add(Duration(days: 1))) {
      return isTurkish ? 'Yarın' : 'Tomorrow';
    } else {
      final days = isTurkish
          ? ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
          : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    }
  }

  Widget _buildWeatherDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withAlpha(200),
          size: 16,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withAlpha(230),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _translateWeatherCondition(String condition, bool isTurkish) {
    if (!isTurkish) return condition;
    
    // Common weather conditions translation map
    final translations = {
      'clear': 'Açık',
      'sunny': 'Güneşli',
      'partly cloudy': 'Parçalı Bulutlu',
      'cloudy': 'Bulutlu',
      'overcast': 'Kapalı',
      'mist': 'Sisli',
      'patchy rain possible': 'Yer Yer Yağmur',
      'patchy snow possible': 'Yer Yer Kar',
      'patchy sleet possible': 'Yer Yer Sulu Kar',
      'patchy freezing drizzle possible': 'Yer Yer Dondurucu Çisenti',
      'thundery outbreaks possible': 'Gök Gürültülü Sağanak',
      'blowing snow': 'Tipi',
      'blizzard': 'Kar Fırtınası',
      'fog': 'Sis',
      'freezing fog': 'Dondurucu Sis',
      'patchy light drizzle': 'Hafif Çisenti',
      'light drizzle': 'Çisenti',
      'freezing drizzle': 'Dondurucu Çisenti',
      'heavy freezing drizzle': 'Yoğun Dondurucu Çisenti',
      'patchy light rain': 'Hafif Yağmur',
      'light rain': 'Hafif Yağmur',
      'moderate rain at times': 'Ara Ara Orta Yağmur',
      'moderate rain': 'Orta Yağmur',
      'heavy rain at times': 'Ara Ara Şiddetli Yağmur',
      'heavy rain': 'Şiddetli Yağmur',
      'light freezing rain': 'Hafif Dondurucu Yağmur',
      'moderate or heavy freezing rain': 'Orta/Şiddetli Dondurucu Yağmur',
      'light sleet': 'Hafif Sulu Kar',
      'moderate or heavy sleet': 'Orta/Şiddetli Sulu Kar',
      'patchy light snow': 'Hafif Kar',
      'light snow': 'Hafif Kar',
      'patchy moderate snow': 'Ara Ara Orta Kar',
      'moderate snow': 'Orta Kar',
      'patchy heavy snow': 'Ara Ara Yoğun Kar',
      'heavy snow': 'Yoğun Kar',
      'ice pellets': 'Buz Taneleri',
      'light rain shower': 'Hafif Sağanak Yağmur',
      'moderate or heavy rain shower': 'Orta/Şiddetli Sağanak',
      'torrential rain shower': 'Sağanak Yağmur',
      'light sleet showers': 'Hafif Sulu Kar Sağanağı',
      'moderate or heavy sleet showers': 'Orta/Şiddetli Sulu Kar Sağanağı',
      'light snow showers': 'Hafif Kar Sağanağı',
      'moderate or heavy snow showers': 'Orta/Şiddetli Kar Sağanağı',
      'light showers of ice pellets': 'Hafif Buz Tanesi Sağanağı',
      'moderate or heavy showers of ice pellets': 'Orta/Şiddetli Buz Tanesi Sağanağı',
      'patchy light rain with thunder': 'Gök Gürültülü Hafif Yağmur',
      'moderate or heavy rain with thunder': 'Gök Gürültülü Yağmur',
      'patchy light snow with thunder': 'Gök Gürültülü Hafif Kar',
      'moderate or heavy snow with thunder': 'Gök Gürültülü Kar',
    };
    
    final lowerCondition = condition.toLowerCase();
    return translations[lowerCondition] ?? condition;
  }

  List<Color> _getWeatherGradient(String condition, bool isDark) {
    final lowerCondition = condition.toLowerCase();
    
    // Clear / Sunny
    if (lowerCondition.contains('clear') || lowerCondition.contains('sunny') || 
        lowerCondition.contains('açık') || lowerCondition.contains('güneşli')) {
      return isDark
          ? [const Color(0xFF0F2027), const Color(0xFF2C5364)] // Night Sky
          : [const Color(0xFF2980B9), const Color(0xFF6DD5FA)]; // Clear Day Blue
    }
    
    // Clouds
    if (lowerCondition.contains('cloud') || lowerCondition.contains('bulut')) {
      if (lowerCondition.contains('scattered') || lowerCondition.contains('broken') || 
          lowerCondition.contains('parçalı') || lowerCondition.contains('az')) {
         return isDark
            ? [const Color(0xFF232526), const Color(0xFF414345)] // Dark Clouds
            : [const Color(0xFF5D4157), const Color(0xFFA8CABA)]; // Moody Clouds
      }
      return isDark
          ? [const Color(0xFF373B44), const Color(0xFF4286f4)] // Night Clouds
          : [const Color(0xFF8360c3), const Color(0xFF2ebf91)]; // Day Clouds
    }
    
    // Rain
    if (lowerCondition.contains('rain') || lowerCondition.contains('drizzle') || 
        lowerCondition.contains('yağmur') || lowerCondition.contains('çisenti') || lowerCondition.contains('sağanak')) {
      return isDark
          ? [const Color(0xFF000046), const Color(0xFF1CB5E0)] // Night Rain
          : [const Color(0xFF005C97), const Color(0xFF363795)]; // Deep Rain Blue
    }
    
    // Thunderstorm
    if (lowerCondition.contains('thunder') || lowerCondition.contains('gök gürültü') || lowerCondition.contains('fırtına')) {
      return isDark
          ? [const Color(0xFF141E30), const Color(0xFF243B55)]
          : [const Color(0xFF20002c), const Color(0xFFcbb4d4)];
    }
    
    // Snow
    if (lowerCondition.contains('snow') || lowerCondition.contains('blizzard') || 
        lowerCondition.contains('kar') || lowerCondition.contains('tipi')) {
      return isDark
          ? [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)]
          : [const Color(0xFF83a4d4), const Color(0xFFb6fbff)]; // Ice Cold
    }
    
    // Atmosphere (Fog, Mist, Smoke, Haze)
    if (lowerCondition.contains('fog') || lowerCondition.contains('mist') || 
        lowerCondition.contains('haze') || lowerCondition.contains('smoke') ||
        lowerCondition.contains('sis') || lowerCondition.contains('pus') || lowerCondition.contains('duman')) {
      return isDark
          ? [const Color(0xFF3E5151), const Color(0xFFDECBA4)]
          : [const Color(0xFF606c88), const Color(0xFF3f4c6b)];
    }
    
    // Default
    return isDark
        ? [const Color(0xFF141E30), const Color(0xFF243B55)]
        : [const Color(0xFF2193b0), const Color(0xFF6dd5fa)];
  }
}
