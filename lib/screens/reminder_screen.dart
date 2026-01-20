import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/reminder.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/extensions.dart';
import '../providers/reminder_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/voice_note_screen.dart';
import '../widgets/voice_player.dart';
import '../widgets/quill_note_viewer.dart';
import '../widgets/common/sheet_handle.dart';
import '../widgets/common/sheet_header.dart'; // Import shared widget

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
        filtered = filtered.where((r) => r.dateTime.isAfter(todayStart) && r.dateTime.isBefore(todayEnd)).toList();
        break;
      case ReminderFilter.upcoming:
        filtered = filtered.where((r) => r.dateTime.isAfter(todayEnd)).toList();
        break;
      case ReminderFilter.past:
        filtered = filtered.where((r) => r.dateTime.isBefore(now) && !r.isCompleted).toList();
        break;
      case ReminderFilter.all:
      default:
        break;
    }

    // Apply Search
    if (_searchQuery.isEmpty) {
      return filtered;
    }
    return filtered.where((r) => 
      r.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      r.description.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _addReminder() async {
    final l10n = context.l10n;
    final result = await showModalBottomSheet<Reminder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReminderSheet(l10n: l10n),
    );
    
    if (result != null) {
      await Provider.of<ReminderProvider>(context, listen: false).addReminder(result);
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
    
    if (result != null) {
      await Provider.of<ReminderProvider>(context, listen: false).updateReminder(result);
      // Cancel old notification and reschedule if not completed
      await _notifications.cancelNotification(reminder.id.hashCode);
      if (!result.isCompleted && result.dateTime.isAfter(DateTime.now())) {
        await _scheduleReminder(result);
      }
    }
  }

  Future<void> _toggleComplete(Reminder reminder) async {
    await Provider.of<ReminderProvider>(context, listen: false).toggleComplete(reminder);
    
    if (!reminder.isCompleted) {
      // It was not completed, now it is - cancel notification
      await _notifications.cancelNotification(reminder.id.hashCode);
    } else if (reminder.dateTime.isAfter(DateTime.now())) {
      // It was completed, now it's not - reschedule
      await _scheduleReminder(reminder.copyWith(isCompleted: false));
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    await Provider.of<ReminderProvider>(context, listen: false).deleteReminder(reminder);
    await _notifications.cancelNotification(reminder.id.hashCode);
  }
  
  Future<void> _togglePin(Reminder reminder) async {
    await Provider.of<ReminderProvider>(context, listen: false)
        .updateReminder(reminder.copyWith(isPinned: !reminder.isPinned));
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
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: l10n.searchReminders,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  hintStyle: TextStyle(color: Theme.of(context).hintColor),
                  prefixIcon: Icon(Icons.search, size: 20, color: Theme.of(context).hintColor),
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
          PopupMenuButton<ReminderFilter>(
            icon: Icon(Icons.filter_list),
            tooltip: 'Filter',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: ReminderFilter.all, child: Row(children: [Text('🗂️'), SizedBox(width: 8), Text(l10n.all)])),
              PopupMenuItem(value: ReminderFilter.today, child: Row(children: [Text('📅'), SizedBox(width: 8), Text(l10n.today)])),
              PopupMenuItem(value: ReminderFilter.upcoming, child: Row(children: [Text('🗓️'), SizedBox(width: 8), Text(l10n.upcoming)])),
              PopupMenuItem(value: ReminderFilter.past, child: Row(children: [Text('🕰️'), SizedBox(width: 8), Text(l10n.past)])),
            ],
          ),
        ],

      ),
      body: Consumer<ReminderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
          }
          
          final filteredReminders = _filterReminders(provider.reminders);
          
          if (filteredReminders.isEmpty && !_isSearching) {
            return _buildEmptyState(l10n);
          }
          
          return _buildReminderList(
            filteredReminders.where((r) => !r.isCompleted).toList(), 
            filteredReminders.where((r) => r.isCompleted).toList(), 
            l10n
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(100),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _addReminder,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: Icon(Icons.add_rounded, color: Colors.white, size: 24),
          label: Text(
            l10n.newReminder,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
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
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(127),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addReminderHint,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(77),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderList(List<Reminder> upcoming, List<Reminder> completed, AppLocalizations l10n) {
    // Split into pinned and unpinned
    final pinnedUpcoming = upcoming.where((r) => r.isPinned).toList();
    final unpinnedUpcoming = upcoming.where((r) => !r.isPinned).toList();
    
    // Split unpinned into Today and Later
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    final todayReminders = unpinnedUpcoming.where((r) => r.dateTime.isBefore(todayEnd) && r.dateTime.isAfter(now.subtract(const Duration(hours: 24)))).toList();
    final upcomingReminders = unpinnedUpcoming.where((r) => r.dateTime.isAfter(todayEnd)).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pinnedUpcoming.isNotEmpty) ...[
            _buildSectionHeader(l10n.pinned, pinnedUpcoming.length),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pinnedUpcoming.length,
              itemBuilder: (context, index) => _buildReminderCard(pinnedUpcoming[index]),
            ),
            const SizedBox(height: 16),
          ],
          if (todayReminders.isNotEmpty) ...[
            _buildSectionHeader(l10n.today, todayReminders.length),
            const SizedBox(height: 12),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayReminders.length,
              onReorder: (oldIndex, newIndex) => _onReorder(todayReminders, oldIndex, newIndex),
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
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcomingReminders.length,
              onReorder: (oldIndex, newIndex) => _onReorder(upcomingReminders, oldIndex, newIndex),
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
            ListView.builder(
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

  Future<void> _onReorder(List<Reminder> list, int oldIndex, int newIndex) async {
      setState(() {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final Reminder item = list.removeAt(oldIndex);
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withAlpha(51),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
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
        child: Icon(reminder.isPinned ? Icons.push_pin_outlined : Icons.push_pin, color: Colors.white),
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
        return true;
      },
      onDismissed: (_) => _deleteReminder(reminder),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: reminder.isCompleted
                ? Theme.of(context).dividerColor.withAlpha(20)
                : priorityColor.withAlpha(127),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _editReminder(reminder),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleComplete(reminder),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: reminder.isCompleted ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
                        width: 2,
                      ),
                      color: reminder.isCompleted ? Theme.of(context).primaryColor : Colors.transparent,
                    ),
                    child: reminder.isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
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
                            Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.push_pin, size: 14, color: Colors.amber),
                            ),
                          Expanded(
                            child: Text(
                              reminder.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: reminder.isCompleted 
                                    ? Theme.of(context).disabledColor 
                                    : Theme.of(context).textTheme.bodyLarge?.color,
                                decoration: reminder.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (reminder.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        QuillNoteViewer(
                          content: reminder.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isPast && !reminder.isCompleted
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM, HH:mm', Provider.of<SettingsProvider>(context, listen: false).locale.languageCode).format(reminder.dateTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: isPast && !reminder.isCompleted
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).hintColor,
                            ),
                          ),
                          if (reminder.voiceNotePath != null) ...[
                            SizedBox(width: 8),
                            Icon(Icons.mic, size: 14, color: Colors.blue),
                          ],
                          if (reminder.subtasks.isNotEmpty) ...[
                            SizedBox(width: 8),
                            Icon(Icons.checklist, size: 14, color: Colors.green),
                            SizedBox(width: 2),
                            Text(
                              '${reminder.completedSubtasksCount}/${reminder.totalSubtasksCount}',
                              style: TextStyle(fontSize: 11, color: Colors.green),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: priorityColor.withAlpha(38),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getPriorityIcon(reminder.priority),
                    size: 16,
                    color: priorityColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    _titleController = TextEditingController(text: widget.reminder?.title ?? '');
    
    // Initialize Quill controller
    if (widget.reminder?.description != null && widget.reminder!.description.isNotEmpty) {
      try {
        final doc = quill.Document.fromJson(jsonDecode(widget.reminder!.description));
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
    
    _selectedDate = widget.reminder?.dateTime ?? DateTime.now().add(const Duration(hours: 1));
    _priority = widget.reminder?.priority ?? 'medium';
    _voiceNotePath = widget.reminder?.voiceNotePath;
    _isPinned = widget.reminder?.isPinned ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.70, // Reduced from 0.92 to 0.70
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SheetHandle(), // Replaced
          
          // Top Toolbar
          SheetHeader(
            title: widget.reminder == null ? widget.l10n.newReminder : widget.l10n.reminder,
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reminder Title
                  TextField(
                    controller: _titleController,
                    // Reduced font size from titleLarge to titleMedium (~16sp) or slightly larger custom.
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), 
                    decoration: InputDecoration(
                      hintText: widget.l10n.reminderTitle,
                      border: InputBorder.none,
                      hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  
                  // Tags? No tags in reminders yet, skipping.
                  
                  // Reminder Content Editor 
                  // Removed box decoration to match Notes style
                  Container(
                    constraints: const BoxConstraints(minHeight: 150),
                    child: quill.QuillEditor.basic(
                      controller: _quillController,
                      config: quill.QuillEditorConfig(
                        placeholder: widget.l10n.description,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Date & Time
                  Text(
                    widget.l10n.dateTime,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimeButton(
                          icon: Icons.calendar_today,
                          text: DateFormat('dd MMM yyyy', Provider.of<SettingsProvider>(context, listen: false).locale.languageCode).format(_selectedDate),
                          onTap: _selectDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateTimeButton(
                          icon: Icons.access_time,
                          text: DateFormat('HH:mm').format(_selectedDate),
                          onTap: _selectTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Priority
                  Text(
                    widget.l10n.priority,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPrioritySelector(),
                  const SizedBox(height: 24),
                  
                  // Voice Note
                  Text(
                    Provider.of<SettingsProvider>(context, listen: false).locale.languageCode == 'tr' ? 'Sesli Not' : 'Voice Note',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
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
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.mic, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              Provider.of<SettingsProvider>(context, listen: false).locale.languageCode == 'tr' ? 'Ses Kaydet' : 'Record Voice',
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 200), // Extra space for scrolling
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
                  onTap: () => setState(() => _isToolbarExpanded = !_isToolbarExpanded),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          _isToolbarExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isToolbarExpanded ? widget.l10n.hideTools : widget.l10n.formattingTools,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        if (!_isToolbarExpanded) ...[
                          const Icon(Icons.format_bold, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          const Icon(Icons.format_italic, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          const Icon(Icons.format_list_bulleted, size: 16, color: Colors.grey),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_isToolbarExpanded) ...[
                  const Divider(height: 1),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
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
          _priorityChip('medium', widget.l10n.priorityMedium, AppColors.priorityMedium),
          const SizedBox(width: 8),
          _priorityChip('high', widget.l10n.priorityHigh, AppColors.priorityHigh),
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
          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      backgroundColor: Colors.transparent,
      selectedColor: color,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.transparent : color),
      ),
      onSelected: (selected) {
        if (selected) setState(() => _priority = value);
      },
    );
  }

  Future<void> _selectDate() async {
    DateTime tempDate = _selectedDate;
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
                    child: Text(widget.l10n.save, style: TextStyle(fontWeight: FontWeight.bold)),
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
    DateTime tempTime = _selectedDate;
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
                    child: Text(widget.l10n.save, style: TextStyle(fontWeight: FontWeight.bold)),
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
        SnackBar(content: Text("${widget.l10n.reminderTitle} ${widget.l10n.required}")),
      );
      return;
    }

    if (_selectedDate.isBefore(DateTime.now()) && widget.reminder == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geçmiş bir zamana hatırlatıcı kurulamaz! Please select a future time.")),
      );
      return;
    }

    // Serialize Quill content to JSON
    final descriptionJson = jsonEncode(_quillController.document.toDelta().toJson());

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.l10n.deleteReminder),
        content: Text(widget.l10n.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(widget.l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.reminder != null) {
      if (mounted) {
        await Provider.of<ReminderProvider>(context, listen: false).deleteReminder(widget.reminder!);
        await NotificationService.instance.cancelNotification(widget.reminder!.id.hashCode);
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
