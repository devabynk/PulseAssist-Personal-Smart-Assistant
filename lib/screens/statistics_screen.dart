import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/utils/extensions.dart';
import '../providers/alarm_provider.dart';
import '../providers/note_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../providers/reminder_provider.dart';
import '../theme/app_theme.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.statisticsTitle),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Consumer<PomodoroProvider>(
        builder: (context, pomodoro, _) =>
            Consumer3<AlarmProvider, NoteProvider, ReminderProvider>(
        builder: (context, alarms, notes, reminders, _) {
          final activeAlarms =
              alarms.alarms.where((a) => a.isActive).length;
          final inactiveAlarms = alarms.alarms.length - activeAlarms;

          final completedReminders =
              reminders.reminders.where((r) => r.isCompleted).length;
          final pendingReminders =
              reminders.reminders.length - completedReminders;

          final pinnedNotes = notes.notes.where((n) => n.isPinned).length;
          final taggedNotes =
              notes.notes.where((n) => n.tags.isNotEmpty).length;
          final notesWithImages =
              notes.notes.where((n) => n.imagePaths.isNotEmpty).length;
          final voiceNotesCount =
              notes.notes.where((n) => n.voiceNotePath != null).length;

          // Notes created per weekday (last 7 days)
          final now = DateTime.now();
          final weeklyData = List.generate(7, (i) {
            final day = now.subtract(Duration(days: 6 - i));
            final count = notes.notes
                .where((n) =>
                    n.createdAt.year == day.year &&
                    n.createdAt.month == day.month &&
                    n.createdAt.day == day.day)
                .length;
            return (day, count);
          });

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview cards
                  Text(
                    l10n.overview,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _OverviewGrid(
                    items: [
                      _StatItem(
                        label: l10n.notes_count,
                        value: notes.notes.length,
                        icon: Icons.notes_rounded,
                        color: AppColors.primary,
                      ),
                      _StatItem(
                        label: l10n.alarms_count,
                        value: alarms.alarms.length,
                        icon: Icons.alarm_rounded,
                        color: const Color(0xFFFF6B6B),
                      ),
                      _StatItem(
                        label: l10n.reminders_count,
                        value: reminders.reminders.length,
                        icon: Icons.notifications_rounded,
                        color: const Color(0xFF4ECDC4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Weekly notes chart
                  Text(
                    l10n.weeklyActivity,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _WeeklyChart(
                    data: weeklyData,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  // Alarms breakdown
                  _SectionCard(
                    title: l10n.alarms_count,
                    icon: Icons.alarm_rounded,
                    color: const Color(0xFFFF6B6B),
                    children: [
                      _BarRow(
                          label: l10n.activeAlarms,
                          count: activeAlarms,
                          total: alarms.alarms.length,
                          color: const Color(0xFF4CAF50)),
                      _BarRow(
                          label: l10n.inactiveAlarms,
                          count: inactiveAlarms,
                          total: alarms.alarms.length,
                          color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Reminders breakdown
                  _SectionCard(
                    title: l10n.reminders_count,
                    icon: Icons.notifications_rounded,
                    color: const Color(0xFF4ECDC4),
                    children: [
                      _BarRow(
                          label: l10n.completedReminders,
                          count: completedReminders,
                          total: reminders.reminders.length,
                          color: const Color(0xFF4CAF50)),
                      _BarRow(
                          label: l10n.pendingReminders,
                          count: pendingReminders,
                          total: reminders.reminders.length,
                          color: const Color(0xFFFF9800)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Notes breakdown
                  _SectionCard(
                    title: l10n.notes_count,
                    icon: Icons.notes_rounded,
                    color: AppColors.primary,
                    children: [
                      _BarRow(
                          label: l10n.pinnedNotes,
                          count: pinnedNotes,
                          total: notes.notes.length,
                          color: const Color(0xFFFFD700)),
                      _BarRow(
                          label: l10n.taggedNotes,
                          count: taggedNotes,
                          total: notes.notes.length,
                          color: AppColors.primary),
                      _BarRow(
                          label: l10n.notesWithImages,
                          count: notesWithImages,
                          total: notes.notes.length,
                          color: const Color(0xFF9C27B0)),
                      _BarRow(
                          label: l10n.voiceNotesCount,
                          count: voiceNotesCount,
                          total: notes.notes.length,
                          color: const Color(0xFF2196F3)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Pomodoro section
                  _SectionCard(
                    title: l10n.pomodoroStats,
                    icon: Icons.timer_rounded,
                    color: AppColors.primary,
                    children: [
                      // Overview row: today / week / total
                      Row(
                        children: [
                          _MiniStatCard(
                            label: l10n.today,
                            value: pomodoro.sessionsToday,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          _MiniStatCard(
                            label: l10n.thisWeek,
                            value: pomodoro.sessionsThisWeek,
                            color: const Color(0xFF4ECDC4),
                          ),
                          const SizedBox(width: 8),
                          _MiniStatCard(
                            label: l10n.totalSessions,
                            value: pomodoro.totalSessions,
                            color: const Color(0xFFFF9800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _BarRow(
                        label: l10n.dailyGoalLabel,
                        count: pomodoro.sessionsToday,
                        total: pomodoro.dailyGoal,
                        color: AppColors.primary,
                      ),
                      _BarRow(
                        label: l10n.weeklyGoalLabel,
                        count: pomodoro.sessionsThisWeek,
                        total: pomodoro.weeklyGoal,
                        color: const Color(0xFF4ECDC4),
                      ),
                      const SizedBox(height: 4),
                      // Timer settings row
                      Row(
                        children: [
                          _TimerChip(
                            label: l10n.workDuration,
                            minutes: pomodoro.workMinutes,
                            minuteShort: l10n.minuteShort,
                          ),
                          const SizedBox(width: 8),
                          _TimerChip(
                            label: l10n.shortBreakDuration,
                            minutes: pomodoro.shortBreakMinutes,
                            minuteShort: l10n.minuteShort,
                          ),
                          const SizedBox(width: 8),
                          _TimerChip(
                            label: l10n.longBreakDuration,
                            minutes: pomodoro.longBreakMinutes,
                            minuteShort: l10n.minuteShort,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
}

class _OverviewGrid extends StatelessWidget {
  final List<_StatItem> items;
  const _OverviewGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map((item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: item.color.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: item.color.withAlpha(40), width: 1),
                    ),
                    child: Column(
                      children: [
                        Icon(item.icon, color: item.color, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          '${item.value}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: item.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).hintColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<(DateTime, int)> data;
  final bool isDark;

  const _WeeklyChart({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.map((d) => d.$2).fold(0, (a, b) => a > b ? a : b);
    final locale = Localizations.localeOf(context).languageCode;

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          maxY: (maxVal < 3 ? 3 : maxVal + 1).toDouble(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat.E(locale).format(data[idx].$1),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark
                  ? Colors.white.withAlpha(15)
                  : Colors.black.withAlpha(10),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            data.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].$2.toDouble(),
                  color: AppColors.primary,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  final String label;
  final int minutes;
  final String minuteShort;

  const _TimerChip({
    required this.label,
    required this.minutes,
    required this.minuteShort,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$minutes $minuteShort',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _BarRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 13, color: Theme.of(context).hintColor)),
              Text('$count',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: color.withAlpha(25),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
