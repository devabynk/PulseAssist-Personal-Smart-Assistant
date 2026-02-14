import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/extensions.dart';
import '../core/utils/responsive.dart';
import '../l10n/app_localizations.dart';
import '../models/alarm.dart';
// DatabaseService and NotificationService moved to Provider
import '../providers/alarm_provider.dart';
import '../services/system_ringtone_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/confirmation_dialog.dart';
import '../widgets/common/custom_text_field.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  // DB and Notifications handled by Provider now
  // final NotificationService ... we might need it for direct calls? No, Provider handles it.

  @override
  void initState() {
    super.initState();
    // Refresh alarms on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AlarmProvider>(context, listen: false).loadAlarms();
    });
  }

  Future<void> _showAddEditSheet({Alarm? alarm}) async {
    final l10n = context.l10n;
    final result = await showModalBottomSheet<Alarm>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditAlarmSheet(alarm: alarm, l10n: l10n),
    );

    if (result != null) {
      if (!mounted) return;

      final alarmsProvider = Provider.of<AlarmProvider>(context, listen: false);
      final messenger = ScaffoldMessenger.of(context);
      final isTurkish = l10n.localeName == 'tr';

      try {
        // Check for duplicate alarms
        final duplicate = alarmsProvider.checkDuplicateAlarm(result);

        if (duplicate != null && mounted) {
          // Format time and days for display
          final timeStr =
              '${result.time.hour.toString().padLeft(2, '0')}:${result.time.minute.toString().padLeft(2, '0')}';
          String daysStr;

          if (result.repeatDays.isEmpty) {
            // One-time alarm - show date
            final now = DateTime.now();
            final isToday =
                result.time.day == now.day && result.time.month == now.month;
            final isTomorrow =
                result.time.day == now.add(const Duration(days: 1)).day;

            if (isToday) {
              daysStr = l10n.today;
            } else if (isTomorrow) {
              daysStr = l10n.tomorrow;
            } else {
              daysStr =
                  '${result.time.day}/${result.time.month}/${result.time.year}';
            }
          } else {
            // Repeating alarm - show days
            if (result.repeatDays.length == 7) {
              daysStr = l10n.everyDay;
            } else {
              daysStr = l10n.custom;
            }
          }

          // Show confirmation dialog
          final choice = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.duplicateAlarmTitle),
              content: Text(l10n.duplicateAlarmMessage(timeStr, daysStr)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'replace'),
                  child: Text(l10n.duplicateAlarmReplace),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'keep_both'),
                  child: Text(l10n.duplicateAlarmKeepBoth),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'cancel'),
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          );

          if (choice == 'replace') {
            // Delete the old alarm and add the new one
            await alarmsProvider.deleteAlarm(duplicate);
            await alarmsProvider.addAlarm(result);
          } else if (choice == 'keep_both') {
            // Just add the new alarm
            if (alarm == null) {
              await alarmsProvider.addAlarm(result);
            } else {
              await alarmsProvider.updateAlarm(result);
            }
          }
          // If 'cancel', do nothing
        } else {
          // No duplicate, proceed normally
          if (alarm == null) {
            await alarmsProvider.addAlarm(result);
          } else {
            await alarmsProvider.updateAlarm(result);
          }
        }
      } catch (e) {
        debugPrint('Error saving alarm: $e');
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isTurkish
                  ? 'Alarm kaydedilemedi. Lütfen izinleri kontrol edin.'
                  : 'Failed to save alarm. Please check permissions.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleAlarm(Alarm alarm) async {
    final alarmsProvider = Provider.of<AlarmProvider>(context, listen: false);
    final isTurkish = Localizations.localeOf(context).languageCode == 'tr';

    // If turning OFF and it's a repeating alarm
    if (alarm.isActive && alarm.repeatDays.isNotEmpty) {
      // Show dialog
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isTurkish ? 'Alarmı Kapat' : 'Turn Off Alarm'),
          content: Text(
            isTurkish
                ? 'Bu tekrarlayan bir alarm. Nasıl kapatmak istersiniz?'
                : 'This is a repeating alarm. How do you want to turn it off?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'skip'),
              child: Text(
                isTurkish ? 'Sadece Yarın İçin' : 'Only for Tomorrow',
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'all'),
              child: Text(isTurkish ? 'Tamamen Kapat' : 'Turn Off Completely'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.cancel),
            ),
          ],
        ),
      );

      if (choice == 'skip') {
        await alarmsProvider.skipNextAlarm(alarm);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isTurkish
                    ? 'Alarm bir sonraki gün için atlandı'
                    : 'Alarm skipped for next occurrence',
              ),
            ),
          );
        }
      } else if (choice == 'all') {
        await alarmsProvider.toggleAlarm(alarm);
      }
    } else {
      await alarmsProvider.toggleAlarm(alarm);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.alarmPageTitle),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        bottom: true,
        child: Consumer<AlarmProvider>(
          builder: (context, alarmProvider, child) {
            if (alarmProvider.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              );
            }
            if (alarmProvider.alarms.isEmpty) {
              return _buildEmptyState(l10n);
            }

            final isTablet = context.isTablet || context.isDesktop;

            if (isTablet) {
              return GridView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: context.horizontalPadding,
                  vertical: 24,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: alarmProvider.alarms.length,
                itemBuilder: (context, index) {
                  final alarm = alarmProvider.alarms[index];
                  return _buildAlarmCard(alarm);
                },
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alarmProvider.alarms.length,
              itemBuilder: (context, index) {
                final alarm = alarmProvider.alarms[index];
                return _buildAlarmCard(alarm);
              },
            );
          },
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
          onPressed: () => _showAddEditSheet(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          label: Text(
            l10n.newAlarm,
            style: const TextStyle(
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
            Icons.alarm_off,
            size: 80,
            color: Theme.of(context).iconTheme.color?.withAlpha(77),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noAlarms,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withAlpha(127),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addAlarmHint,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withAlpha(77),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmCard(Alarm alarm) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Format repeat text
    var repeatText = '';
    if (alarm.repeatDays.isEmpty) {
      repeatText = context.l10n.oneTime;
    } else if (alarm.repeatDays.length == 7) {
      repeatText = context.l10n.everyDay;
    } else {
      // Simple logic for weekdays/weeks
      // We need a helper, but for now just show count or "Custom"
      repeatText = context.l10n.custom;
      // todo: localized days
    }

    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog for all alarms
        final confirmed = await ConfirmationDialog.show(
          context: context,
          title: context.l10n.deleteAlarm,
          message: context.l10n.deleteAlarmConfirm,
          confirmText: context.l10n.delete,
          cancelText: context.l10n.cancel,
        );

        if (confirmed == true) {
          if (!mounted) return false;
          await Provider.of<AlarmProvider>(
            context,
            listen: false,
          ).deleteAlarm(alarm);
          return true; // Dismiss
        }
        return false; // Cancel
      },
      child: GestureDetector(
        onTap: () => _showAddEditSheet(alarm: alarm),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withAlpha(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 50 : 10),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('HH:mm').format(alarm.time),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: alarm.isActive
                          ? theme.textTheme.bodyLarge?.color
                          : theme.disabledColor,
                    ),
                  ),
                  Row(
                    children: [
                      if (alarm.title.isNotEmpty && alarm.title != 'Alarm')
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          child: Text(
                            alarm.title,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withAlpha(150),
                            ),
                          ),
                        ),
                      Icon(Icons.repeat, size: 12, color: theme.disabledColor),
                      const SizedBox(width: 4),
                      Text(
                        repeatText, // Placeholder
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.disabledColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Switch.adaptive(
                value: alarm.isActive,
                onChanged: (_) => _toggleAlarm(alarm),
                activeTrackColor: theme.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddEditAlarmSheet extends StatefulWidget {
  final Alarm? alarm;
  final AppLocalizations l10n;
  const _AddEditAlarmSheet({this.alarm, required this.l10n});

  @override
  State<_AddEditAlarmSheet> createState() => _AddEditAlarmSheetState();
}

class _AddEditAlarmSheetState extends State<_AddEditAlarmSheet> {
  late TextEditingController _titleController;
  late DateTime _selectedTime;
  List<int> _repeatDays = [];
  bool _repeatExpanded = false;
  String _selectedSound = 'assets/alarm.mp3';
  String _selectedSoundName = 'Default';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.alarm?.title ?? '');
    // If editing, use alarm time. If adding, use next hour.
    if (widget.alarm != null) {
      _selectedTime = widget.alarm!.time;
      _repeatDays = List.from(widget.alarm!.repeatDays);
      _selectedSound = widget.alarm?.soundPath ?? 'assets/alarm.mp3';
      _selectedSoundName = widget.alarm?.soundName ?? 'Default';
    } else {
      final now = DateTime.now();
      _selectedTime = now.add(const Duration(minutes: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... no changes to build structure ...
    final theme = Theme.of(context);
    final l10n = widget.l10n;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  child: Text(l10n.cancel),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  widget.alarm == null ? l10n.newAlarm : l10n.editAlarm,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(onPressed: _save, child: Text(l10n.save)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Time Picker
                SizedBox(
                  height: 200,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: _selectedTime,
                    use24hFormat: true,
                    onDateTimeChanged: (val) {
                      setState(() => _selectedTime = val);
                    },
                  ),
                ),

                // Info Form
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _titleController,
                        hintText: l10n.alarmTitle,
                        prefixIcon: const Icon(Icons.label_outline),
                      ),
                      const SizedBox(height: 16),
                      _buildRepeatSection(l10n),
                      if (_repeatDays.isEmpty) ...[
                        const SizedBox(height: 16),
                        const SizedBox(height: 16),
                        _buildDateSection(l10n),
                      ],
                      const SizedBox(height: 16),
                      _buildSoundSection(l10n),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final isToday =
        _selectedTime.day == DateTime.now().day &&
        _selectedTime.month == DateTime.now().month;
    final isTomorrow =
        _selectedTime.day == DateTime.now().add(const Duration(days: 1)).day;

    var dateText = DateFormat(
      'EEE, d MMM',
      locale.toString(),
    ).format(_selectedTime);
    if (isToday) dateText = '${l10n.today} - $dateText';
    if (isTomorrow) dateText = '${l10n.tomorrow} - $dateText';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(l10n.date),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dateText,
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_today, size: 16),
          ],
        ),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedTime,
            firstDate: now,
            lastDate: now.add(const Duration(days: 365)),
            locale: locale,
          );
          if (picked != null) {
            setState(() {
              _selectedTime = DateTime(
                picked.year,
                picked.month,
                picked.day,
                _selectedTime.hour,
                _selectedTime.minute,
              );
            });
          }
        },
      ),
    );
  }

  Widget _buildRepeatSection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final firstDayIndex = MaterialLocalizations.of(
      context,
    ).firstDayOfWeekIndex; // 0=Sunday, 1=Monday

    // Create ordered list of day indices (1=Mon ... 7=Sun)
    // MaterialLocalizations: 0=Sunday.
    // DateTime: 7=Sunday.
    // So if firstDayIndex=0 (Sun), start with 7, then 1,2,3...
    // If firstDayIndex=1 (Mon), start with 1,2,3...

    final orderedDays = <int>[];
    final startDay = firstDayIndex == 0
        ? 7
        : firstDayIndex; // Convert 0(Sun) to 7(Sun) for DateTime

    for (var i = 0; i < 7; i++) {
      var day = startDay + i;
      if (day > 7) day -= 7;
      orderedDays.add(day);
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(l10n.repeat),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getRepeatSummary(l10n),
                  style: TextStyle(color: theme.disabledColor, fontSize: 14),
                ),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
            onTap: () {
              setState(() {
                _repeatExpanded = !_repeatExpanded;
              });
            },
          ),
          if (_repeatExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: orderedDays.map((day) {
                        // Generate label
                        // Use a specific week in 2024 where Jan 1 = Monday
                        final date = DateTime(2024, 1, day);
                        var label = DateFormat.E(locale).format(date);
                        // Optional: trim or ensure short length if needed, usually E is 3 chars (Mon, Pzt)
                        // Remove ending period if present (Pzt. -> Pzt)
                        label = label.replaceAll('.', '');

                        return _buildDayToggle(day, label);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ActionChip(
                        label: Text(l10n.weekdays),
                        onPressed: () =>
                            setState(() => _repeatDays = [1, 2, 3, 4, 5]),
                      ),
                      ActionChip(
                        label: Text(l10n.weekends),
                        onPressed: () => setState(() => _repeatDays = [6, 7]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayToggle(int dayIndex, String label) {
    final isSelected = _repeatDays.contains(dayIndex);
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _repeatDays.remove(dayIndex);
          } else {
            _repeatDays.add(dayIndex);
          }
        });
      },
      child: Container(
        width: 36,
        height: 36, // Slightly larger
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? theme.primaryColor : theme.canvasColor,
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.bold,
            fontSize: 11, // Smaller font to fit 3 chars
          ),
        ),
      ),
    );
  }

  String _getRepeatSummary(AppLocalizations l10n) {
    if (_repeatDays.isEmpty) return l10n.oneTime; // "Never"
    if (_repeatDays.length == 7) return l10n.everyDay;
    if (_repeatDays.length == 5 &&
        [1, 2, 3, 4, 5].every((d) => _repeatDays.contains(d))) {
      return 'Weekdays'; // todo localize
    }
    if (_repeatDays.length == 2 && [6, 7].every((d) => _repeatDays.contains(d))) {
      return 'Weekends';
    }
    return '${_repeatDays.length} days';
  }

  Widget _buildSoundSection(AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(l10n.alarmSound),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                _selectedSound == 'assets/alarm.mp3'
                    ? l10n.soundDefault
                    : _selectedSoundName,
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.music_note, size: 16),
          ],
        ),
        onTap: () => _showSoundPicker(l10n),
      ),
    );
  }

  void _showSoundPicker(AppLocalizations l10n) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _RingtonePickerSheet(),
    );

    if (result != null) {
      setState(() {
        _selectedSound = result['path']!;
        _selectedSoundName = result['name']!;
      });
    }
  }

  void _save() {
    final now = DateTime.now();

    // Construct DateTime based on picker just for Hour/Minute info
    final alarmTimeDate = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final alarm = Alarm(
      id: widget.alarm?.id ?? const Uuid().v4(),
      title: _titleController.text.isEmpty ? 'Alarm' : _titleController.text,
      time: alarmTimeDate,
      isActive: true, // Default active on save
      repeatDays: _repeatDays,
      soundPath: _selectedSound,
      soundName: _selectedSoundName,
    );

    Navigator.pop(context, alarm);
  }
}

// We need to patch the _AddEditAlarmSheetState to include _selectedSoundName
// Since I can't edit the class definition directly easily without replacing the whole thing often,
// I will just add the logic in _save to use a lookup or simple default if not available.
// Actually, let's fix _AddEditAlarmSheetState properly in next step.

class _RingtonePickerSheet extends StatefulWidget {
  const _RingtonePickerSheet();

  @override
  State<_RingtonePickerSheet> createState() => _RingtonePickerSheetState();
}

class _RingtonePickerSheetState extends State<_RingtonePickerSheet> {
  List<SystemRingtone> _ringtones = [];
  bool _isLoading = true;
  String? _playingUri;

  @override
  void initState() {
    super.initState();
    _loadRingtones();
  }

  @override
  void dispose() {
    SystemRingtoneService.stopRingtone();
    super.dispose();
  }

  Future<void> _loadRingtones() async {
    try {
      final ringtones = await SystemRingtoneService.getRingtones();
      setState(() {
        _ringtones = ringtones;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading ringtones: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _playRingtone(String uri) async {
    if (_playingUri == uri) {
      await SystemRingtoneService.stopRingtone();
      setState(() => _playingUri = null);
    } else {
      await SystemRingtoneService.playRingtone(uri);
      setState(() => _playingUri = uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(50),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.selectSound,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _ringtones.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListTile(
                          leading: const Icon(Icons.music_note),
                          title: Text(l10n.soundDefault),
                          onTap: () {
                            SystemRingtoneService.stopRingtone();
                            Navigator.pop(context, {
                              'path': 'assets/alarm.mp3',
                              'name': l10n.soundDefault,
                            });
                          },
                        );
                      }
                      final ringtone = _ringtones[index - 1];
                      final isPlaying = _playingUri == ringtone.uri;

                      return ListTile(
                        leading: IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.stop_circle
                                : Icons.play_circle_outline,
                          ),
                          onPressed: () => _playRingtone(ringtone.uri),
                          color: Theme.of(context).primaryColor,
                        ),
                        title: Text(ringtone.title),
                        onTap: () {
                          SystemRingtoneService.stopRingtone();
                          Navigator.pop(context, {
                            'path': ringtone.uri,
                            'name': ringtone.title,
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
