import 'dart:async';

import 'package:flutter/material.dart';

enum PomodoroPhase { work, shortBreak, longBreak }

class PomodoroProvider extends ChangeNotifier {
  // Configurable durations (minutes)
  int workMinutes = 25;
  int shortBreakMinutes = 5;
  int longBreakMinutes = 15;
  int longBreakAfterSessions = 4;

  PomodoroPhase _phase = PomodoroPhase.work;
  int _secondsLeft = 25 * 60;
  bool _isRunning = false;
  int _sessionsCompleted = 0;
  Timer? _timer;

  PomodoroPhase get phase => _phase;
  int get secondsLeft => _secondsLeft;
  bool get isRunning => _isRunning;
  int get sessionsCompleted => _sessionsCompleted;

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
    _advancePhase(notify: false);
    notifyListeners();
  }

  void updateSettings({
    required int workMins,
    required int shortBreakMins,
    required int longBreakMins,
    required int longBreakAfter,
  }) {
    workMinutes = workMins;
    shortBreakMinutes = shortBreakMins;
    longBreakMinutes = longBreakMins;
    longBreakAfterSessions = longBreakAfter;
    // Reset to reflect new duration
    _isRunning = false;
    _timer?.cancel();
    _secondsLeft = totalSeconds;
    notifyListeners();
  }

  void _tick() {
    if (_secondsLeft > 0) {
      _secondsLeft--;
      notifyListeners();
    } else {
      _timer?.cancel();
      _isRunning = false;
      _advancePhase(notify: true);
    }
  }

  void _advancePhase({required bool notify}) {
    if (_phase == PomodoroPhase.work) {
      _sessionsCompleted++;
      final isLongBreak = _sessionsCompleted % longBreakAfterSessions == 0;
      _phase = isLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
    } else {
      _phase = PomodoroPhase.work;
    }
    _secondsLeft = totalSeconds;
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
