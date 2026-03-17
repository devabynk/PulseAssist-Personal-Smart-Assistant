import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/extensions.dart';
import '../providers/alarm_provider.dart';
import '../providers/note_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai/ai_manager.dart';
import '../theme/app_theme.dart';

class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  static const _prefKey = 'weekly_summary_text';
  static const _prefDateKey = 'weekly_summary_date';

  String? _summary;
  String? _lastDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCached();
  }

  Future<void> _loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _summary = prefs.getString(_prefKey);
      _lastDate = prefs.getString(_prefDateKey);
    });
  }

  Future<void> _generate() async {
    if (_isLoading) return;

    final isTurkish =
        context.read<SettingsProvider>().locale.languageCode == 'tr';
    final alarms = context.read<AlarmProvider>().alarms;
    final notes = context.read<NoteProvider>().notes;
    final reminders = context.read<ReminderProvider>().reminders;

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    // Build context data for AI
    final data = {
      'period': '${DateFormat('dd MMM').format(weekAgo)} – ${DateFormat('dd MMM yyyy').format(now)}',
      'notes_created': notes.where((n) => n.createdAt.isAfter(weekAgo)).length,
      'total_notes': notes.length,
      'pinned_notes': notes.where((n) => n.isPinned).length,
      'active_alarms': alarms.where((a) => a.isActive).length,
      'total_alarms': alarms.length,
      'reminders_completed':
          reminders.where((r) => r.isCompleted && r.dateTime.isAfter(weekAgo)).length,
      'reminders_pending': reminders.where((r) => !r.isCompleted).length,
      'total_reminders': reminders.length,
    };

    setState(() => _isLoading = true);
    try {
      final groq = AiManager.instance.groqProvider;
      if (!groq.isAvailable) {
        _showError();
        return;
      }
      final result = await groq.generateWeeklySummary(
        data: data,
        isTurkish: isTurkish,
      );

      if (result != null && result.isNotEmpty) {
        final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(now);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, result);
        await prefs.setString(_prefDateKey, dateStr);
        if (mounted) {
          setState(() {
            _summary = result;
            _lastDate = dateStr;
          });
        }
      } else {
        _showError();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.summaryError),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.weeklyDigest),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (_summary != null && !_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l10n.regenerate,
              onPressed: _generate,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header illustration
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withAlpha(40),
                      AppColors.primary.withAlpha(10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.weeklyDigest,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.weeklyDigestDesc,
                      style: TextStyle(
                          color: Theme.of(context).hintColor, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_isLoading) ...[
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                          color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(l10n.generatingSummary,
                          style: TextStyle(
                              color: Theme.of(context).hintColor)),
                    ],
                  ),
                ),
              ] else if (_summary != null) ...[
                if (_lastDate != null)
                  Text(
                    l10n.lastGenerated(_lastDate!),
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).hintColor),
                  ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _summary!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.7),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Text(
                  l10n.noSummaryYet,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.noSummaryHint,
                  style: TextStyle(
                      color: Theme.of(context).hintColor, height: 1.5),
                ),
              ],

              if (!_isLoading) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _generate,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(_summary != null
                        ? l10n.regenerate
                        : l10n.generateSummary),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
