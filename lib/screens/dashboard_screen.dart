import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/utils/extensions.dart';
import '../core/utils/responsive.dart';
import '../l10n/app_localizations.dart';
import '../models/alarm.dart';
import '../models/note.dart';
import '../models/notification_log.dart';
import '../providers/alarm_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/note_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/location_selector_dialog.dart';
import '../widgets/quill_note_viewer.dart';
import 'pomodoro_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'weekly_summary_screen.dart';

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
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).loadNotifications();
    });
  }

  String _getGreeting(bool isTurkish) {
    final hour = DateTime.now().hour;
    if (isTurkish) {
      if (hour >= 5 && hour < 9) return 'Günaydın! ☀️';
      if (hour >= 9 && hour < 12) return 'Hayırlı sabahlar';
      if (hour >= 12 && hour < 14) return 'İyi öğleler 🌤️';
      if (hour >= 14 && hour < 17) return 'Günün nasıl geçiyor?';
      if (hour >= 17 && hour < 20) return 'İyi akşamlar 🌙';
      if (hour >= 20 && hour < 23) return 'İyi geceler 🌙';
      return 'Gece geç saatler 🌑';
    } else {
      if (hour >= 5 && hour < 9) return 'Good morning! ☀️';
      if (hour >= 9 && hour < 12) return 'Hope your morning is great';
      if (hour >= 12 && hour < 14) return 'Good noon! 🌤️';
      if (hour >= 14 && hour < 17) return 'Good afternoon';
      if (hour >= 17 && hour < 20) return 'Good evening 🌙';
      if (hour >= 20 && hour < 23) return 'Good night 🌙';
      return 'Burning the midnight oil 🌑';
    }
  }


  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isTurkish = settings.locale.languageCode == 'tr';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = settings.userName ?? '';
    final l10n = context.l10n;

    final useTabletLayout = context.isDesktop ||
        (context.isTablet && !Responsive.isPortraitTablet(context));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Main Content
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.horizontalPadding,
            vertical: 16,
          ),
          child: useTabletLayout
              ? _buildTabletView(isTurkish, userName, isDark, l10n)
              : _buildMobileView(isTurkish, userName, isDark, l10n),
        ),
      ),
    );
  }

  Widget _buildMobileView(bool isTurkish, String userName, bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with greeting
        _buildHeader(isTurkish, userName, isDark, l10n),
        const SizedBox(height: 20),

        // Weather Card
        _buildWeatherCard(isTurkish, isDark),
        const SizedBox(height: 16),

        // AI Chatbot Card
        _buildAIChatbotCard(isTurkish, isDark, l10n),
        const SizedBox(height: 16),

        // Alarm & Tasks Row
        _buildAlarmTasksRow(isTurkish, isDark, l10n),
        const SizedBox(height: 16),

        // Recent Notes
        _buildRecentNotes(isTurkish, isDark, l10n),
        const SizedBox(height: 16),

        // Tools row: Pomodoro + Statistics
        _buildToolsRow(isDark, l10n),
        const SizedBox(height: 16),

        // Weekly Digest card
        _buildWeeklyDigestCard(isDark, l10n),
        const SizedBox(height: 80), // Space for bottom nav
      ],
    );
  }

  Widget _buildTabletView(bool isTurkish, String userName, bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(isTurkish, userName, isDark, l10n),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildWeatherCard(isTurkish, isDark),
                  const SizedBox(height: 16),
                  _buildAIChatbotCard(isTurkish, isDark, l10n),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right Column
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _buildAlarmTasksRow(isTurkish, isDark, l10n),
                  const SizedBox(height: 24),
                  _buildRecentNotes(isTurkish, isDark, l10n),
                  const SizedBox(height: 24),
                  _buildToolsRow(isDark, l10n),
                  const SizedBox(height: 24),
                  _buildWeeklyDigestCard(isDark, l10n),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildToolsRow(bool isDark, AppLocalizations l10n) {
    return IntrinsicHeight(
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _ToolCard(
            icon: Icons.timer_rounded,
            label: l10n.focusTime,
            subtitle: l10n.focusTimeDesc,
            color: AppColors.primary,
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PomodoroScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ToolCard(
            icon: Icons.bar_chart_rounded,
            label: l10n.statistics,
            subtitle: l10n.statsDesc,
            color: const Color(0xFF4ECDC4),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildWeeklyDigestCard(bool isDark, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WeeklySummaryScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF6B6B).withAlpha(isDark ? 50 : 30),
              const Color(0xFFFF8E53).withAlpha(isDark ? 30 : 15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF6B6B).withAlpha(60),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFFF6B6B),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.weeklyDigest,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.weeklyDigestDesc,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white.withAlpha(150)
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? Colors.white54 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTurkish, String userName, bool isDark, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(isTurkish),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              userName.isNotEmpty ? userName : 'PulseAssist',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        Row(
          children: [
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                final unreadCount = notificationProvider.unreadCount;

                return GestureDetector(
                  onTap: () => _showNotifications(
                    context,
                    isTurkish,
                    notificationProvider,
                  ),
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
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
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
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.settings_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAIChatbotCard(bool isTurkish, bool isDark, AppLocalizations l10n) {
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
                    : [
                        AppColors.primary.withAlpha(40),
                        Colors.purple.withAlpha(30),
                      ],
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
                      child: const Icon(
                        Icons.smart_toy,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTurkish ? 'Akıllı Asistan' : 'Smart Assistant',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n.widgetActive,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                          l10n.goToChat,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward,
                          color: AppColors.primary,
                          size: 16,
                        ),
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
                      color: Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withAlpha(200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.lastResponse,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastMessage.content.length > 60
                              ? '${lastMessage.content.substring(0, 60)}...'
                              : lastMessage.content,
                          style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildAlarmTasksRow(bool isTurkish, bool isDark, AppLocalizations l10n) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Next Alarm Card
          Expanded(
            child: Consumer<AlarmProvider>(
              builder: (context, alarmProvider, child) {
                final activeAlarms = alarmProvider.alarms
                    .where((a) => a.isActive)
                    .toList();
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
                      boxShadow: isDark
                          ? null
                          : [
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
                            Icon(
                              Icons.alarm,
                              color: isDark
                                  ? Colors.purpleAccent[100]
                                  : Colors.purple,
                              size: 24,
                            ),
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
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              nextAlarm?.title ?? l10n.noAlarms,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
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
                final completed = reminderProvider.reminders
                    .where((r) => r.isCompleted)
                    .length;
                final remaining = total - completed;

                return GestureDetector(
                  onTap: widget.onNavigateToReminders,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDark
                          ? null
                          : [
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
                            Icon(
                              Icons.check_circle_outline,
                              color: isDark
                                  ? Colors.tealAccent[100]
                                  : Colors.teal,
                              size: 24,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isDark ? Colors.tealAccent : Colors.teal)
                                        .withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                l10n.today.toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.tealAccent[100]
                                      : Colors.teal,
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
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[400],
                                  ),
                                ),
                                Text(
                                  '/$total',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: total > 0 ? completed / total : 0,
                                backgroundColor: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary,
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.tasksLeft(remaining),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
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

  Widget _buildRecentNotes(bool isTurkish, bool isDark, AppLocalizations l10n) {
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
                      l10n.recentNotes,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: widget.onNavigateToNotes,
                  child: Icon(
                    Icons.arrow_forward,
                    color: Theme.of(context).iconTheme.color,
                    size: 20,
                  ),
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
                    l10n.noNotes,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              )
            else
              ...recentNotes.map((note) => _buildNoteItem(note, l10n)),
          ],
        );
      },
    );
  }

  Widget _buildNoteItem(Note note, AppLocalizations l10n) {
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
      timeAgo = '${timeDiff.inMinutes}${l10n.minutesShort}';
    } else if (timeDiff.inHours < 24) {
      timeAgo = '${timeDiff.inHours}${l10n.hoursShort}';
    } else {
      timeAgo = '${timeDiff.inDays}${l10n.daysShort}';
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
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (note.isPinned)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.push_pin,
                            size: 12,
                            color: Colors.amber,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          note.title.isEmpty
                              ? l10n.untitled
                              : note.title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
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
                        const SizedBox(width: 4),
                        Icon(
                          Icons.image,
                          size: 12,
                          color: Theme.of(context).hintColor,
                        ),
                      ],
                      if (note.voiceNotePath != null) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.mic, size: 12, color: Colors.blue),
                      ],
                      if (note.tags.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.tag, size: 12, color: Colors.green),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              timeAgo,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(
    BuildContext context,
    bool isTurkish,
    NotificationProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Consumer2<NotificationProvider, ReminderProvider>(
                builder: (context, notifProvider, reminderProvider, _) {
                  final notifications = List.from(notifProvider.notifications)
                    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                  final now = DateTime.now();
                  final upcomingReminders = reminderProvider.pendingReminders
                      .where((r) => r.dateTime.isAfter(now))
                      .toList()
                    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
                  final nextReminders = upcomingReminders.take(3).toList();

                  final hasAny =
                      notifications.isNotEmpty || nextReminders.isNotEmpty;

                  return Column(
                    children: [
                      // Handle bar
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).dividerColor.withAlpha(120),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isTurkish ? 'Bildirimler' : 'Notifications',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (notifications.isNotEmpty)
                              GestureDetector(
                                onTap: () => notifProvider.clearAll(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withAlpha(20),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.delete_sweep_rounded,
                                        color: Colors.red,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isTurkish ? 'Tümünü Sil' : 'Clear all',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: hasAny
                            ? ListView(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                children: [
                                  // Upcoming reminders section
                                  if (nextReminders.isNotEmpty) ...[
                                    _sectionLabel(
                                      isTurkish
                                          ? 'Yaklaşan Hatırlatıcılar'
                                          : 'Upcoming Reminders',
                                      Icons.event_rounded,
                                      Colors.teal,
                                    ),
                                    const SizedBox(height: 8),
                                    ...nextReminders.map(
                                      (r) => _buildReminderItem(
                                        r,
                                        isTurkish,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  // Notifications
                                  if (notifications.isNotEmpty) ...[
                                    _sectionLabel(
                                      isTurkish
                                          ? 'Bildirimler'
                                          : 'Notifications',
                                      Icons.notifications_rounded,
                                      Colors.orange,
                                    ),
                                    const SizedBox(height: 8),
                                    ...notifications.map(
                                      (n) => _buildNotificationItem(
                                        n,
                                        isTurkish,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                ],
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_off_outlined,
                                      size: 56,
                                      color: Theme.of(context).hintColor,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      isTurkish
                                          ? 'Bildirim yok'
                                          : 'No notifications',
                                      style: TextStyle(
                                        color: Theme.of(context).hintColor,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      provider.markAllAsRead();
    });
  }

  Widget _sectionLabel(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildReminderItem(dynamic reminder, bool isTurkish) {
    final dateFormat = DateFormat('d MMM · HH:mm', isTurkish ? 'tr' : 'en');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: Colors.teal, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.alarm_rounded,
              size: 18,
              color: Colors.teal,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((reminder.description as String).isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      reminder.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              dateFormat.format(reminder.dateTime),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.teal,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationLog notification, bool isTurkish) {
    final dateFormat = DateFormat('d MMM · HH:mm', isTurkish ? 'tr' : 'en');
    final accent = _getNotificationColor(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).deleteNotification(notification.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: accent, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _getNotificationIcon(notification.type),
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 12),
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
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(notification.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).hintColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!notification.isRead)
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  GestureDetector(
                    onTap: () {
                      Provider.of<NotificationProvider>(
                        context,
                        listen: false,
                      ).deleteNotification(notification.id);
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Theme.of(context).hintColor.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'alarm':
        return Colors.purple;
      case 'reminder':
        return Colors.teal;
      case 'chat':
        return AppColors.primary;
      case 'system':
        return Colors.blueGrey;
      case 'update':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
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
    return _WeatherCard(
      isTurkish: isTurkish,
      isDark: isDark,
      translateCondition: _translateWeatherCondition,
      getGradient: _getWeatherGradient,
      getDayName: _getDayName,
    );
  }

  String _getDayName(DateTime date, bool isTurkish, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return l10n.today;
    } else if (targetDate == today.add(const Duration(days: 1))) {
      return l10n.tomorrow;
    } else {
      final days = isTurkish
          ? ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
          : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    }
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
      'moderate or heavy showers of ice pellets':
          'Orta/Şiddetli Buz Tanesi Sağanağı',
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
    if (lowerCondition.contains('clear') ||
        lowerCondition.contains('sunny') ||
        lowerCondition.contains('açık') ||
        lowerCondition.contains('güneşli')) {
      return isDark
          ? [const Color(0xFF0F2027), const Color(0xFF2C5364)] // Night Sky
          : [
              const Color(0xFF2980B9),
              const Color(0xFF6DD5FA),
            ]; // Clear Day Blue
    }

    // Clouds
    if (lowerCondition.contains('cloud') || lowerCondition.contains('bulut')) {
      if (lowerCondition.contains('scattered') ||
          lowerCondition.contains('broken') ||
          lowerCondition.contains('parçalı') ||
          lowerCondition.contains('az')) {
        return isDark
            ? [const Color(0xFF232526), const Color(0xFF414345)] // Dark Clouds
            : [
                const Color(0xFF5D4157),
                const Color(0xFFA8CABA),
              ]; // Moody Clouds
      }
      return isDark
          ? [const Color(0xFF373B44), const Color(0xFF4286f4)] // Night Clouds
          : [const Color(0xFF8360c3), const Color(0xFF2ebf91)]; // Day Clouds
    }

    // Rain
    if (lowerCondition.contains('rain') ||
        lowerCondition.contains('drizzle') ||
        lowerCondition.contains('yağmur') ||
        lowerCondition.contains('çisenti') ||
        lowerCondition.contains('sağanak')) {
      return isDark
          ? [const Color(0xFF000046), const Color(0xFF1CB5E0)] // Night Rain
          : [
              const Color(0xFF005C97),
              const Color(0xFF363795),
            ]; // Deep Rain Blue
    }

    // Thunderstorm
    if (lowerCondition.contains('thunder') ||
        lowerCondition.contains('gök gürültü') ||
        lowerCondition.contains('fırtına')) {
      return isDark
          ? [const Color(0xFF141E30), const Color(0xFF243B55)]
          : [const Color(0xFF20002c), const Color(0xFFcbb4d4)];
    }

    // Snow
    if (lowerCondition.contains('snow') ||
        lowerCondition.contains('blizzard') ||
        lowerCondition.contains('kar') ||
        lowerCondition.contains('tipi')) {
      return isDark
          ? [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)]
          : [const Color(0xFF83a4d4), const Color(0xFFb6fbff)]; // Ice Cold
    }

    // Atmosphere (Fog, Mist, Smoke, Haze)
    if (lowerCondition.contains('fog') ||
        lowerCondition.contains('mist') ||
        lowerCondition.contains('haze') ||
        lowerCondition.contains('smoke') ||
        lowerCondition.contains('sis') ||
        lowerCondition.contains('pus') ||
        lowerCondition.contains('duman')) {
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

// ─── Animated Weather Card ───────────────────────────────────────────────────

class _WeatherCard extends StatefulWidget {
  final bool isTurkish;
  final bool isDark;
  final String Function(String, bool) translateCondition;
  final List<Color> Function(String, bool) getGradient;
  final String Function(DateTime, bool, AppLocalizations) getDayName;

  const _WeatherCard({
    required this.isTurkish,
    required this.isDark,
    required this.translateCondition,
    required this.getGradient,
    required this.getDayName,
  });

  @override
  State<_WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<_WeatherCard>
    with TickerProviderStateMixin {
  late final AnimationController _rotateCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _flashCtrl;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _floatCtrl.dispose();
    _flashCtrl.dispose();
    super.dispose();
  }

  Widget _animatedWeatherIcon(String condition, double size) {
    final c = condition.toLowerCase();
    if (c.contains('sun') ||
        c.contains('clear') ||
        c.contains('açık') ||
        c.contains('güneş')) {
      return RotationTransition(
        turns: _rotateCtrl,
        child: Icon(
          Icons.wb_sunny_rounded,
          size: size,
          color: const Color(0xFFFFD54F),
        ),
      );
    } else if (c.contains('thunder') ||
        c.contains('gök gürültü') ||
        c.contains('fırtına')) {
      return FadeTransition(
        opacity: Tween<double>(
          begin: 0.3,
          end: 1.0,
        ).animate(_flashCtrl),
        child: Icon(
          Icons.bolt_rounded,
          size: size,
          color: const Color(0xFFFFEE58),
        ),
      );
    } else if (c.contains('snow') ||
        c.contains('blizzard') ||
        c.contains('kar') ||
        c.contains('tipi')) {
      return RotationTransition(
        turns: _rotateCtrl,
        child: Icon(
          Icons.ac_unit_rounded,
          size: size,
          color: const Color(0xFFB3E5FC),
        ),
      );
    } else if (c.contains('rain') ||
        c.contains('drizzle') ||
        c.contains('shower') ||
        c.contains('yağmur') ||
        c.contains('çisenti') ||
        c.contains('sağanak')) {
      return AnimatedBuilder(
        animation: _floatCtrl,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (_floatCtrl.value - 0.5) * 8),
          child: child,
        ),
        child: Icon(
          Icons.water_drop_rounded,
          size: size,
          color: const Color(0xFF81D4FA),
        ),
      );
    } else if (c.contains('fog') ||
        c.contains('mist') ||
        c.contains('sis') ||
        c.contains('pus')) {
      return FadeTransition(
        opacity: Tween<double>(
          begin: 0.4,
          end: 0.9,
        ).animate(_floatCtrl),
        child: Icon(Icons.blur_on_rounded, size: size, color: Colors.white70),
      );
    } else if (c.contains('cloud') ||
        c.contains('overcast') ||
        c.contains('bulut') ||
        c.contains('kapalı')) {
      return AnimatedBuilder(
        animation: _floatCtrl,
        builder: (context, child) => Transform.translate(
          offset: Offset((_floatCtrl.value - 0.5) * 8, 0),
          child: child,
        ),
        child: Icon(Icons.cloud_rounded, size: size, color: Colors.white),
      );
    }
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, (_floatCtrl.value - 0.5) * 4),
        child: child,
      ),
      child: Icon(Icons.wb_cloudy_rounded, size: size, color: Colors.white70),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, wp, _) {
        final weather = wp.currentWeather;
        final forecast = wp.forecast;
        final isExpanded = wp.isExpanded;
        final l10n = context.l10n;
        final isTurkish = widget.isTurkish;
        final isDark = widget.isDark;

        final gradientColors = weather != null
            ? widget.getGradient(weather.description, isDark)
            : (isDark
                  ? [const Color(0xFF141E30), const Color(0xFF243B55)]
                  : [const Color(0xFF2193b0), const Color(0xFF6dd5fa)]);

        return Container(
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withAlpha(90),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles for depth
              Positioned(
                top: -30,
                right: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(18),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: 20,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(10),
                  ),
                ),
              ),
              // Content
              if (wp.isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else if (weather == null)
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const LocationSelectorDialog(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 20,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wb_sunny_outlined,
                          size: 42,
                          color: Colors.white.withAlpha(200),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.selectLocation,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isTurkish
                                  ? 'Hava durumu için konumu seçin'
                                  : 'Tap to set your location',
                              style: TextStyle(
                                color: Colors.white.withAlpha(180),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: city + action buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: Colors.white.withAlpha(200),
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              weather.cityName,
                              style: TextStyle(
                                color: Colors.white.withAlpha(230),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: Colors.white.withAlpha(200),
                              size: 20,
                            ),
                            onPressed: () {
                              if (wp.selectedLocation != null) {
                                final locale = Localizations.localeOf(
                                  context,
                                ).languageCode;
                                wp.fetchWeather(
                                  wp.selectedLocation!,
                                  language: locale,
                                  displayLabel: wp.selectedLocation,
                                  state: wp.selectedState,
                                  district: wp.selectedDistrict,
                                  countryCode: wp.selectedCountry,
                                );
                              }
                            },
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit_location_rounded,
                              color: Colors.white.withAlpha(200),
                              size: 20,
                            ),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => const LocationSelectorDialog(),
                            ),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: Icon(
                              isExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: Colors.white.withAlpha(200),
                              size: 22,
                            ),
                            onPressed: () => wp.toggleExpand(),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // Details: temp/condition + feels like + humidity + wind
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withAlpha(45),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Weather icon + temp + condition
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _animatedWeatherIcon(weather.description, 26),
                                const SizedBox(height: 2),
                                Text(
                                  '${weather.temperature.round()}°',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  widget.translateCondition(
                                    weather.description,
                                    isTurkish,
                                  ),
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(180),
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: Colors.white.withAlpha(50),
                            ),
                            _detailItem(
                              Icons.thermostat_rounded,
                              '${weather.feelsLike.round()}°',
                              isTurkish ? 'Hissedilen' : 'Feels like',
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: Colors.white.withAlpha(50),
                            ),
                            _detailItem(
                              Icons.water_drop_rounded,
                              '${weather.humidity}%',
                              isTurkish ? 'Nem' : 'Humidity',
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: Colors.white.withAlpha(50),
                            ),
                            _detailItem(
                              Icons.air_rounded,
                              '${weather.windSpeed.round()} km/h',
                              isTurkish ? 'Rüzgar' : 'Wind',
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Hourly forecast
                    if (isExpanded &&
                        wp.hourlyForecast != null &&
                        wp.hourlyForecast!.isNotEmpty)
                      SizedBox(
                        height: 96,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          itemCount: wp.hourlyForecast!.length,
                          separatorBuilder: (context, _) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final hour = wp.hourlyForecast![index];
                            return Container(
                              width: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withAlpha(45),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    hour['time'],
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(200),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  CachedNetworkImage(
                                    imageUrl: hour['icon'],
                                    width: 28,
                                    height: 28,
                                    placeholder: (context, _) =>
                                        const SizedBox(width: 28, height: 28),
                                    errorWidget: (context, url, _) => const Icon(
                                      Icons.wb_cloudy,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${hour['temp'].round()}°',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    // 3-day forecast
                    if (isExpanded && forecast != null && forecast.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withAlpha(45),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: forecast.map((day) {
                              final date = DateTime.parse(day['date']);
                              final dayName =
                                  widget.getDayName(date, isTurkish, l10n);
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${day['minTemp'].round()}°',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(170),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withAlpha(210), size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 10),
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 35 : 20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? Colors.white.withAlpha(130)
                    : Colors.black45,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
