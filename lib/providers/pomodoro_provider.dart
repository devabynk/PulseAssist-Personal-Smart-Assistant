import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PomodoroPhase { work, shortBreak, longBreak }

class PomodoroAchievement {
  final String title;
  final String message;
  final String emoji;
  const PomodoroAchievement({
    required this.title,
    required this.message,
    required this.emoji,
  });
}

class PomodoroProvider extends ChangeNotifier {
  // ── Preference keys ──────────────────────────────────────────────────────
  static const _kWorkMins = 'pomo_work_mins';
  static const _kShortBreakMins = 'pomo_short_break_mins';
  static const _kLongBreakMins = 'pomo_long_break_mins';
  static const _kLongBreakAfter = 'pomo_long_break_after';
  static const _kDailyGoal = 'pomo_daily_goal';
  static const _kWeeklyGoal = 'pomo_weekly_goal';
  static const _kTodayCount = 'pomo_today_count';
  static const _kTodayDate = 'pomo_today_date';
  static const _kWeekCount = 'pomo_week_count';
  static const _kWeekStart = 'pomo_week_start';
  static const _kTotalCount = 'pomo_total_count';

  // ── Settings ──────────────────────────────────────────────────────────────
  int workMinutes = 25;
  int shortBreakMinutes = 5;
  int longBreakMinutes = 15;
  int longBreakAfterSessions = 4;
  int dailyGoal = 8;
  int weeklyGoal = 40;

  // ── Timer state ───────────────────────────────────────────────────────────
  PomodoroPhase _phase = PomodoroPhase.work;
  int _secondsLeft = 25 * 60;
  bool _isRunning = false;
  int _sessionsCompleted = 0;
  Timer? _timer;

  // ── Progress tracking ─────────────────────────────────────────────────────
  int _sessionsToday = 0;
  int _sessionsThisWeek = 0;
  int _totalSessions = 0;

  // ── Achievement callback ──────────────────────────────────────────────────
  PomodoroAchievement? _pendingAchievement;

  // ── Getters ───────────────────────────────────────────────────────────────
  PomodoroPhase get phase => _phase;
  int get secondsLeft => _secondsLeft;
  bool get isRunning => _isRunning;
  int get sessionsCompleted => _sessionsCompleted;
  int get sessionsToday => _sessionsToday;
  int get sessionsThisWeek => _sessionsThisWeek;
  int get totalSessions => _totalSessions;
  PomodoroAchievement? get pendingAchievement => _pendingAchievement;

  bool get dailyGoalReached => _sessionsToday >= dailyGoal;
  bool get weeklyGoalReached => _sessionsThisWeek >= weeklyGoal;
  double get dailyProgress =>
      dailyGoal == 0 ? 0 : (_sessionsToday / dailyGoal).clamp(0.0, 1.0);
  double get weeklyProgress =>
      weeklyGoal == 0 ? 0 : (_sessionsThisWeek / weeklyGoal).clamp(0.0, 1.0);

  int get totalSeconds {
    switch (_phase) {
      case PomodoroPhase.work:
        return workMinutes * 60;
      case PomodoroPhase.shortBreak:
        return shortBreakMinutes * 60;
      case PomodoroPhase.longBreak:
        return longBreakMinutes * 60;
    }
  }

  double get progress =>
      _secondsLeft == totalSeconds ? 0.0 : 1.0 - (_secondsLeft / totalSeconds);

  String get timeString {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Dots completed in current cycle (0..longBreakAfterSessions).
  /// Shows all filled when currently in a long break (cycle just finished).
  int get cycleDotsCompleted {
    if (_phase == PomodoroPhase.longBreak &&
        _sessionsCompleted % longBreakAfterSessions == 0) {
      return longBreakAfterSessions;
    }
    return _sessionsCompleted % longBreakAfterSessions;
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  PomodoroProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    workMinutes = prefs.getInt(_kWorkMins) ?? 25;
    shortBreakMinutes = prefs.getInt(_kShortBreakMins) ?? 5;
    longBreakMinutes = prefs.getInt(_kLongBreakMins) ?? 15;
    longBreakAfterSessions = prefs.getInt(_kLongBreakAfter) ?? 4;
    dailyGoal = prefs.getInt(_kDailyGoal) ?? 8;
    weeklyGoal = prefs.getInt(_kWeeklyGoal) ?? 40;
    _totalSessions = prefs.getInt(_kTotalCount) ?? 0;

    // Refresh daily count
    final todayStr = _dateStr(DateTime.now());
    final savedDate = prefs.getString(_kTodayDate) ?? '';
    _sessionsToday = savedDate == todayStr ? (prefs.getInt(_kTodayCount) ?? 0) : 0;

    // Refresh weekly count
    final weekStartStr = _weekStartStr(DateTime.now());
    final savedWeekStart = prefs.getString(_kWeekStart) ?? '';
    _sessionsThisWeek =
        savedWeekStart == weekStartStr ? (prefs.getInt(_kWeekCount) ?? 0) : 0;

    _secondsLeft = workMinutes * 60;
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Daily
    final todayStr = _dateStr(now);
    final savedDate = prefs.getString(_kTodayDate) ?? '';
    if (savedDate != todayStr) {
      _sessionsToday = 0;
      await prefs.setString(_kTodayDate, todayStr);
    }
    await prefs.setInt(_kTodayCount, _sessionsToday);

    // Weekly
    final weekStartStr = _weekStartStr(now);
    final savedWeekStart = prefs.getString(_kWeekStart) ?? '';
    if (savedWeekStart != weekStartStr) {
      _sessionsThisWeek = 0;
      await prefs.setString(_kWeekStart, weekStartStr);
    }
    await prefs.setInt(_kWeekCount, _sessionsThisWeek);
    await prefs.setInt(_kTotalCount, _totalSessions);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWorkMins, workMinutes);
    await prefs.setInt(_kShortBreakMins, shortBreakMinutes);
    await prefs.setInt(_kLongBreakMins, longBreakMinutes);
    await prefs.setInt(_kLongBreakAfter, longBreakAfterSessions);
    await prefs.setInt(_kDailyGoal, dailyGoal);
    await prefs.setInt(_kWeeklyGoal, weeklyGoal);
  }

  // ── Controls ──────────────────────────────────────────────────────────────
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void pause() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _timer?.cancel();
    _secondsLeft = totalSeconds;
    notifyListeners();
  }

  void skip() {
    _isRunning = false;
    _timer?.cancel();
    _advancePhase(notify: false, countSession: false);
    notifyListeners();
  }

  void clearAchievement() {
    _pendingAchievement = null;
    notifyListeners();
  }

  void updateSettings({
    required int workMins,
    required int shortBreakMins,
    required int longBreakMins,
    required int longBreakAfter,
    int? newDailyGoal,
    int? newWeeklyGoal,
  }) {
    workMinutes = workMins;
    shortBreakMinutes = shortBreakMins;
    longBreakMinutes = longBreakMins;
    longBreakAfterSessions = longBreakAfter;
    if (newDailyGoal != null) dailyGoal = newDailyGoal;
    if (newWeeklyGoal != null) weeklyGoal = newWeeklyGoal;
    _isRunning = false;
    _timer?.cancel();
    _secondsLeft = totalSeconds;
    _saveSettings();
    notifyListeners();
  }

  // ── Internal ──────────────────────────────────────────────────────────────
  void _tick() {
    if (_secondsLeft > 0) {
      _secondsLeft--;
      notifyListeners();
    } else {
      _timer?.cancel();
      _isRunning = false;
      _advancePhase(notify: true, countSession: true);
    }
  }

  void _advancePhase({required bool notify, required bool countSession}) {
    if (_phase == PomodoroPhase.work) {
      _sessionsCompleted++;

      if (countSession) {
        _sessionsToday++;
        _sessionsThisWeek++;
        _totalSessions++;
        _saveProgress();
        _checkAchievements();
      }

      final isLongBreak = _sessionsCompleted % longBreakAfterSessions == 0;
      _phase = isLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
    } else {
      _phase = PomodoroPhase.work;
    }
    _secondsLeft = totalSeconds;
    if (notify) notifyListeners();
  }

  void _checkAchievements() {
    // Daily goal just reached
    if (_sessionsToday == dailyGoal) {
      _pendingAchievement = const PomodoroAchievement(
        title: 'Günlük Hedef! 🎯',
        message: 'Harika iş! Bugünkü pomodoro hedefinize ulaştınız.',
        emoji: '🏆',
      );
      return;
    }
    // Weekly goal just reached
    if (_sessionsThisWeek == weeklyGoal) {
      _pendingAchievement = const PomodoroAchievement(
        title: 'Haftalık Hedef! 🌟',
        message: 'İnanılmaz! Bu haftalık pomodoro hedefinizi tamamladınız.',
        emoji: '🎉',
      );
      return;
    }
    // Milestone sessions
    if (_totalSessions == 10 ||
        _totalSessions == 25 ||
        _totalSessions == 50 ||
        _totalSessions == 100) {
      _pendingAchievement = PomodoroAchievement(
        title: '$_totalSessions Pomodoro! 🔥',
        message: 'Toplam $_totalSessions pomodoro tamamladınız. Süper odak!',
        emoji: '🔥',
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _weekStartStr(DateTime d) {
    final monday = d.subtract(Duration(days: d.weekday - 1));
    return _dateStr(monday);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
