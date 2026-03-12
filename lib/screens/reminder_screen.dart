import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/extensions.dart';
import '../core/utils/responsive.dart';
import '../l10n/app_localizations.dart';
import '../models/reminder.dart';
import '../providers/reminder_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/voice_note_screen.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/confirmation_dialog.dart';
import '../widgets/common/sheet_handle.dart';
import '../widgets/common/sheet_header.dart'; // Import shared widget
import '../widgets/quill_note_viewer.dart';
import '../widgets/voice_player.dart';

enum ReminderFilter { all, today, upcoming, past }

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final NotificationService _notifications = NotificationService.instance;
  String _searchQuery = '';
  bool _isSearching = false;
  ReminderFilter _selectedFilter = ReminderFilter.all; // Default filter
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load reminders on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReminderProvider>(context, listen: false).loadReminders();
    });
  }

  List<Reminder> _filterReminders(List<Reminder> reminders) {
    var filtered = reminders;

    // Apply Filter Chips logic
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final todayStart = DateTime(now.year, now.month, now.day);

    switch (_selectedFilter) {
      case ReminderFilter.today:
        filtered = filtered
            .where(
              (r) =>
                  r.dateTime.isAfter(todayStart) &&
                  r.dateTime.isBefore(todayEnd),
            )
            .toList();
        break;
      case ReminderFilter.upcoming:
        filtered = filtered.where((r) => r.dateTime.isAfter(todayEnd)).toList();
        break;
      case ReminderFilter.past:
        filtered = filtered
            .where((r) => r.dateTime.isBefore(now) && !r.isCompleted)
            .toList();
        break;
      case ReminderFilter.all:
        break;
    }

    // Apply Search
    if (_searchQuery.isEmpty) {
      return filtered;
    }
    return filtered
        .where(
          (r) =>
              r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.description.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  Future<void> _addReminder() async {
    final l10n = context.l10n;
    final result = await showModalBottomSheet<Reminder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReminderSheet(l10n: l10n),
    );

    if (!mounted) return;

    if (result != null) {
      await Provider.of<ReminderProvider>(
        context,
        listen: false,
      ).addReminder(result);
      await _scheduleReminder(result);
    }
  }

  Future<void> _editReminder(Reminder reminder) async {
    final l10n = context.l10n;
    final result = await showModalBottomSheet<Reminder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReminderSheet(l10n: l10n, reminder: reminder),
    );

    if (!mounted) return;

    if (result != null) {
      await Provider.of<ReminderProvider>(
        context,
        listen: false,
      ).updateReminder(result);
      // Cancel old notification and reschedule if not completed
      await _notifications.cancelNotification(reminder.id.hashCode);
      if (!result.isCompleted && result.dateTime.isAfter(DateTime.now())) {
        await _scheduleReminder(result);
      }
    }
  }

  Future<void> _toggleComplete(Reminder reminder) async {
    await Provider.of<ReminderProvider>(
      context,
      listen: false,
    ).toggleComplete(reminder);

    if (!reminder.isCompleted) {
      // It was not completed, now it is - cancel notification
      await _notifications.cancelNotification(reminder.id.hashCode);
    } else if (reminder.dateTime.isAfter(DateTime.now())) {
      // It was completed, now it's not - reschedule
      await _scheduleReminder(reminder.copyWith(isCompleted: false));
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    await Provider.of<ReminderProvider>(
      context,
      listen: false,
    ).deleteReminder(reminder);
    await _notifications.cancelNotification(reminder.id.hashCode);
  }

  Future<void> _togglePin(Reminder reminder) async {
    await Provider.of<ReminderProvider>(
      context,
      listen: false,
    ).updateReminder(reminder.copyWith(isPinned: !reminder.isPinned));
  }

  Future<void> _scheduleReminder(Reminder reminder) async {
    if (reminder.dateTime.isAfter(DateTime.now())) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final isTurkish = settings.locale.languageCode == 'tr';
      await _notifications.scheduleNotification(
        id: reminder.id.hashCode,
        title: isTurkish ? '🔔 Hatırlatıcı' : '🔔 Reminder',
        body: reminder.title,
        scheduledDate: reminder.dateTime,
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: _isSearching
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.searchReminders,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    hintStyle: TextStyle(color: Theme.of(context).hintColor),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  onChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                  },
                ),
              )
            : Text(l10n.reminders),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            _buildFilterChips(l10n),
            Expanded(
              child: Consumer<ReminderProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    );
                  }

                  final filteredReminders = _filterReminders(provider.reminders);
                  final isTablet = context.isTablet || context.isDesktop;

                  if (filteredReminders.isEmpty && !_isSearching) {
                    return _buildEmptyState(l10n);
                  }

                  return _buildReminderList(
                    filteredReminders.where((r) => !r.isCompleted).toList(),
                    filteredReminders.where((r) => r.isCompleted).toList(),
                    l10n,
                    isTablet,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(100),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _addReminder,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          label: Text(
            l10n.newReminder,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n) {
    final filters = <(ReminderFilter, String, IconData)>[
      (ReminderFilter.all, l10n.all, Icons.apps_rounded),
      (ReminderFilter.today, l10n.today, Icons.today_rounded),
      (ReminderFilter.upcoming, l10n.upcoming, Icons.upcoming_rounded),
      (ReminderFilter.past, l10n.past, Icons.history_rounded),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final (value, label, icon) = filters[index];
          final isSelected = _selectedFilter == value;
          return FilterChip(
            selected: isSelected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).iconTheme.color?.withAlpha(180),
                ),
                const SizedBox(width: 4),
                Text(label),
              ],
            ),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            selectedColor: Theme.of(context).primaryColor,
            backgroundColor: Theme.of(context).cardColor,
            showCheckmark: false,
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : Theme.of(context).dividerColor.withAlpha(40),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            onSelected: (_) => setState(() => _selectedFilter = value),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Theme.of(context).iconTheme.color?.withAlpha(77),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noReminders,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withAlpha(127),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addReminderHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withAlpha(77),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderList(
    List<Reminder> upcoming,
    List<Reminder> completed,
    AppLocalizations l10n,
    bool isTablet,
  ) {
    // Split into pinned and unpinned
    final pinnedUpcoming = upcoming.where((r) => r.isPinned).toList();
    final unpinnedUpcoming = upcoming.where((r) => !r.isPinned).toList();

    // Split unpinned into Today and Later
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final todayReminders = unpinnedUpcoming
        .where(
          (r) =>
              r.dateTime.isBefore(todayEnd) &&
              r.dateTime.isAfter(now.subtract(const Duration(hours: 24))),
        )
        .toList();
    final upcomingReminders = unpinnedUpcoming
        .where((r) => r.dateTime.isAfter(todayEnd))
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pinnedUpcoming.isNotEmpty) ...[
            _buildSectionHeader(l10n.pinned, pinnedUpcoming.length),
            const SizedBox(height: 12),
            isTablet
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 0,
                        ),
                    itemCount: pinnedUpcoming.length,
                    itemBuilder: (context, index) =>
                        _buildReminderCard(pinnedUpcoming[index]),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pinnedUpcoming.length,
                    itemBuilder: (context, index) =>
                        _buildReminderCard(pinnedUpcoming[index]),
                  ),
            const SizedBox(height: 16),
          ],
          if (todayReminders.isNotEmpty) ...[
            _buildSectionHeader(l10n.today, todayReminders.length),
            const SizedBox(height: 12),
            isTablet
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 0,
                        ),
                    itemCount: todayReminders.length,
                    itemBuilder: (context, index) =>
                        _buildReminderCard(todayReminders[index]),
                  )
                : ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todayReminders.length,
                    onReorder: (oldIndex, newIndex) =>
                        _onReorder(todayReminders, oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final reminder = todayReminders[index];
                      return Container(
                        key: Key(reminder.id),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: _buildReminderCard(reminder),
                      );
                    },
                  ),
            const SizedBox(height: 16),
          ],
          if (upcomingReminders.isNotEmpty) ...[
            _buildSectionHeader(l10n.upcoming, upcomingReminders.length),
            const SizedBox(height: 12),
            isTablet
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 0,
                        ),
                    itemCount: upcomingReminders.length,
                    itemBuilder: (context, index) =>
                        _buildReminderCard(upcomingReminders[index]),
                  )
                : ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: upcomingReminders.length,
                    onReorder: (oldIndex, newIndex) =>
                        _onReorder(upcomingReminders, oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final reminder = upcomingReminders[index];
                      return Container(
                        key: Key(reminder.id),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: _buildReminderCard(reminder),
                      );
                    },
                  ),
          ],
          if (completed.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(l10n.completed, completed.length),
            const SizedBox(height: 12),
            isTablet
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 0,
                        ),
                    itemCount: completed.length,
                    itemBuilder: (context, index) =>
                        _buildReminderCard(completed[index]),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: completed.length,
                    itemBuilder: (context, index) {
                      return _buildReminderCard(completed[index]);
                    },
                  ),
          ],
        ],
      ),
    );
  }

  Future<void> _onReorder(
    List<Reminder> list,
    int oldIndex,
    int newIndex,
  ) async {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);
    });
    // We need to update the ACTUAL main list's order based on this sublist change
    // Or easier: update the orderIndex of these items based on their new position
    await DatabaseService.instance.updateReminderOrder(list);
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final isPast = reminder.dateTime.isBefore(DateTime.now());
    final priorityColor = _getPriorityColor(reminder.priority);

    return Dismissible(
      key: Key(reminder.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          reminder.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _togglePin(reminder);
          return false;
        }
        
        // Show confirmation before deleting
        final confirmed = await ConfirmationDialog.show(
          context: context,
          title: context.l10n.deleteReminder,
          message: context.l10n.deleteConfirmation,
          confirmText: context.l10n.delete,
          cancelText: context.l10n.cancel,
        );

        if (confirmed == true) {
          return true; // Dismiss
        }
        return false; // Cancel
      },
      onDismissed: (_) => _deleteReminder(reminder),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(Theme.of(context).brightness == Brightness.dark ? 40 : 10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: priorityColor),
                Expanded(
                  child: InkWell(
          onTap: () => _editReminder(reminder),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _toggleComplete(reminder),
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: reminder.isCompleted
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).iconTheme.color?.withAlpha(80) ?? Colors.grey,
                        width: reminder.isCompleted ? 0 : 1.5,
                      ),
                      color: reminder.isCompleted
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                    ),
                    child: reminder.isCompleted
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (reminder.isPinned)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.push_pin,
                                size: 14,
                                color: Colors.amber,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              reminder.title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: reminder.isCompleted
                                    ? Theme.of(context).disabledColor
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                decoration: reminder.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (reminder.priority != 'low' && reminder.priority != 'none') ...[
                             const SizedBox(width: 8),
                             Icon(
                               _getPriorityIcon(reminder.priority),
                               size: 16,
                               color: priorityColor,
                             ),
                          ]
                        ],
                      ),
                      if (reminder.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        QuillNoteViewer(
                          content: reminder.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                               color: isPast && !reminder.isCompleted
                                   ? Theme.of(context).colorScheme.error.withAlpha(20)
                                   : Theme.of(context).primaryColor.withAlpha(15),
                               borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: isPast && !reminder.isCompleted
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context).primaryColor.withAlpha(200),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat(
                                      'dd MMM, HH:mm',
                                      Provider.of<SettingsProvider>(
                                        context,
                                        listen: false,
                                      ).locale.languageCode,
                                    ).format(reminder.dateTime),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: isPast && !reminder.isCompleted
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(context).primaryColor.withAlpha(200),
                                    ),
                                  ),
                              ],
                            )
                          ),
                          if (reminder.voiceNotePath != null) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.mic, size: 16, color: Colors.blue),
                          ],
                        ],
                      ),
                      if (reminder.subtasks.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: reminder.totalSubtasksCount > 0
                                      ? reminder.completedSubtasksCount /
                                          reminder.totalSubtasksCount
                                      : 0,
                                  backgroundColor: Colors.green.withAlpha(40),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Colors.green,
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${reminder.completedSubtasksCount}/${reminder.totalSubtasksCount}',
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),    // Padding
        ),      // InkWell
                ),  // Expanded
              ],    // stretched Row children
            ),      // stretched Row
          ),        // IntrinsicHeight
        ),          // ClipRRect
      ),            // Container
    );
  }
}

class _ReminderSheet extends StatefulWidget {
  final AppLocalizations l10n;
  final Reminder? reminder;
  const _ReminderSheet({required this.l10n, this.reminder});

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late TextEditingController _titleController;
  late quill.QuillController _quillController;
  late DateTime _selectedDate;
  late String _priority;
  String? _voiceNotePath;
  bool _isToolbarExpanded = false; // Toolbar collapsed by default
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.reminder?.title ?? '',
    );

    // Initialize Quill controller
    if (widget.reminder?.description != null &&
        widget.reminder!.description.isNotEmpty) {
      try {
        final doc = quill.Document.fromJson(
          jsonDecode(widget.reminder!.description),
        );
        _quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        _quillController = quill.QuillController.basic();
      }
    } else {
      _quillController = quill.QuillController.basic();
    }

    _selectedDate =
        widget.reminder?.dateTime ??
        DateTime.now().add(const Duration(hours: 1));
    _priority = widget.reminder?.priority ?? 'medium';
    _voiceNotePath = widget.reminder?.voiceNotePath;
    _isPinned = widget.reminder?.isPinned ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height *
          0.80, // Slightly increased from 0.70 to give more breathing room
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor, // Use scaffold background for cleaner look
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SheetHandle(), // Replaced
          // Top Toolbar
          SheetHeader(
            title: widget.reminder == null
                ? widget.l10n.newReminder
                : widget.l10n.reminder,
            isPinned: _isPinned,
            onPin: () => setState(() => _isPinned = !_isPinned),
            onDelete: widget.reminder != null ? _delete : null,
            onSave: _save,
            pinTooltip: widget.l10n.pin,
            unpinTooltip: widget.l10n.unpin,
            deleteTooltip: widget.l10n.delete,
            saveTooltip: widget.l10n.save,
          ), // Replaced

          const Divider(height: 1),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // Reminder Title
                    TextField(
                      controller: _titleController,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.l10n.reminderTitle,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).hintColor.withAlpha(120),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Theme.of(context).dividerColor.withAlpha(30)),
                    const SizedBox(height: 12),
  
                    // Reminder Content Editor
                    Container(
                      constraints: const BoxConstraints(minHeight: 80),
                      child: Theme(
                         data: Theme.of(context).copyWith(
                           canvasColor: Colors.transparent,
                         ),
                         child: quill.QuillEditor.basic(
                          controller: _quillController,
                          config: quill.QuillEditorConfig(
                            placeholder: widget.l10n.description,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  Divider(color: Theme.of(context).dividerColor.withAlpha(40)),
                  const SizedBox(height: 16),
                  
                  // Date & Time
                  Text(
                    widget.l10n.dateTime.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimeButton(
                          icon: Icons.calendar_today_rounded,
                          text: DateFormat(
                            'dd MMM yyyy',
                            Provider.of<SettingsProvider>(
                              context,
                              listen: false,
                            ).locale.languageCode,
                          ).format(_selectedDate),
                          onTap: _selectDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateTimeButton(
                          icon: Icons.access_time_rounded,
                          text: DateFormat('HH:mm').format(_selectedDate),
                          onTap: _selectTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Priority
                  Text(
                    widget.l10n.priority.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPrioritySelector(),
                  const SizedBox(height: 24),

                  // Voice Note
                  Text(
                    (Provider.of<SettingsProvider>(
                              context,
                              listen: false,
                            ).locale.languageCode ==
                            'tr'
                        ? 'Sesli Not'
                        : 'Voice Note').toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_voiceNotePath != null)
                    VoicePlayer(
                      path: _voiceNotePath!,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                      onDelete: () => setState(() => _voiceNotePath = null),
                    )
                  else
                    InkWell(
                      onTap: _recordVoice,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.withAlpha(50),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.mic_rounded, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              Provider.of<SettingsProvider>(
                                        context,
                                        listen: false,
                                      ).locale.languageCode ==
                                      'tr'
                                  ? 'Ses Kaydet'
                                  : 'Record Voice',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(
                    height: 32,
                  ),
                ],
              ),
            ),
          ),

          // Quill Toolbar (at bottom like notes)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Colors.grey.withAlpha(50))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () =>
                      setState(() => _isToolbarExpanded = !_isToolbarExpanded),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isToolbarExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isToolbarExpanded
                              ? widget.l10n.hideTools
                              : widget.l10n.formattingTools,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (!_isToolbarExpanded) ...[
                          const Icon(
                            Icons.format_bold,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.format_italic,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.format_list_bulleted,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_isToolbarExpanded) ...[
                  const Divider(height: 1),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: quill.QuillSimpleToolbar(
                      controller: _quillController,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withAlpha(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(Theme.of(context).brightness == Brightness.dark ? 20 : 5),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ]
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _priorityChip('low', widget.l10n.priorityLow, AppColors.priorityLow),
          const SizedBox(width: 8),
          _priorityChip(
            'medium',
            widget.l10n.priorityMedium,
            AppColors.priorityMedium,
          ),
          const SizedBox(width: 8),
          _priorityChip(
            'high',
            widget.l10n.priorityHigh,
            AppColors.priorityHigh,
          ),
          const SizedBox(width: 8),
          _priorityChip('urgent', widget.l10n.priorityUrgent, Colors.red),
        ],
      ),
    );
  }

  Widget _priorityChip(String value, String label, Color color) {
    final isSelected = _priority == value;
    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? Colors.white
              : Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: color,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: isSelected ? Colors.transparent : Theme.of(context).dividerColor.withAlpha(30),
        ),
      ),
      onSelected: (selected) {
        if (selected) setState(() => _priority = value);
      },
    );
  }

  Future<void> _selectDate() async {
    var tempDate = _selectedDate;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 320,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(widget.l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(
                          tempDate.year,
                          tempDate.month,
                          tempDate.day,
                          _selectedDate.hour,
                          _selectedDate.minute,
                        );
                      });
                      Navigator.pop(context);
                    },
                    child: Text(
                      widget.l10n.save,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                minimumDate: DateTime.now(),
                maximumDate: DateTime.now().add(const Duration(days: 365)),
                onDateTimeChanged: (date) => tempDate = date,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    var tempTime = _selectedDate;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 320,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(widget.l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          tempTime.hour,
                          tempTime.minute,
                        );
                      });
                      Navigator.pop(context);
                    },
                    child: Text(
                      widget.l10n.save,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: _selectedDate,
                use24hFormat: true,
                onDateTimeChanged: (time) => tempTime = time,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.l10n.reminderTitle} ${widget.l10n.required}'),
        ),
      );
      return;
    }

    if (_selectedDate.isBefore(DateTime.now()) && widget.reminder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Geçmiş bir zamana hatırlatıcı kurulamaz! Please select a future time.',
          ),
        ),
      );
      return;
    }

    // Serialize Quill content to JSON
    final descriptionJson = jsonEncode(
      _quillController.document.toDelta().toJson(),
    );

    final reminder = Reminder(
      id: widget.reminder?.id ?? const Uuid().v4(),
      title: _titleController.text,
      description: descriptionJson,
      dateTime: _selectedDate,
      priority: _priority,
      voiceNotePath: _voiceNotePath,
      isPinned: _isPinned,
    );
    Navigator.pop(context, reminder);
  }

  Future<void> _delete() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: widget.l10n.deleteReminder,
      message: widget.l10n.deleteConfirmation,
      confirmText: widget.l10n.delete,
      cancelText: widget.l10n.cancel,
    );

    if (confirmed == true && widget.reminder != null) {
      if (mounted) {
        await Provider.of<ReminderProvider>(
          context,
          listen: false,
        ).deleteReminder(widget.reminder!);
        await NotificationService.instance.cancelNotification(
          widget.reminder!.id.hashCode,
        );
        if (!mounted) return;
        Navigator.pop(context, null);
      }
    }
  }

  Future<void> _recordVoice() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceNoteScreen(existingPath: _voiceNotePath),
      ),
    );

    if (result != null) {
      setState(() => _voiceNotePath = result);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }
}
