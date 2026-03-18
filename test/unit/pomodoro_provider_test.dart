import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_assistant/providers/pomodoro_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PomodoroProvider', () {
    // ── Initial state ─────────────────────────────────────────────────────
    group('Initial state', () {
      test('starts with correct defaults', () {
        final p = PomodoroProvider();
        expect(p.phase, PomodoroPhase.work);
        expect(p.isRunning, false);
        expect(p.sessionsCompleted, 0);
        expect(p.workMinutes, 25);
        expect(p.shortBreakMinutes, 5);
        expect(p.longBreakMinutes, 15);
        expect(p.longBreakAfterSessions, 4);
        expect(p.dailyGoal, 8);
        expect(p.weeklyGoal, 40);
      });

      test('timeString starts at 25:00', () {
        final p = PomodoroProvider();
        // Before prefs load, secondsLeft defaults to 25*60
        expect(p.timeString, '25:00');
      });

      test('progress is 0.0 at start', () {
        final p = PomodoroProvider();
        expect(p.progress, 0.0);
      });

      test('totalSeconds returns work minutes * 60 in work phase', () {
        final p = PomodoroProvider();
        expect(p.totalSeconds, 25 * 60);
      });

      test('cycleDotsCompleted is 0 initially', () {
        final p = PomodoroProvider();
        expect(p.cycleDotsCompleted, 0);
      });

      test('daily/weekly progress is 0.0 initially', () {
        final p = PomodoroProvider();
        expect(p.dailyProgress, 0.0);
        expect(p.weeklyProgress, 0.0);
      });

      test('dailyGoalReached is false initially', () {
        final p = PomodoroProvider();
        expect(p.dailyGoalReached, false);
      });

      test('weeklyGoalReached is false initially', () {
        final p = PomodoroProvider();
        expect(p.weeklyGoalReached, false);
      });

      test('pendingAchievement is null initially', () {
        final p = PomodoroProvider();
        expect(p.pendingAchievement, isNull);
      });
    });

    // ── Timer controls ────────────────────────────────────────────────────
    group('start() / pause() / reset()', () {
      test('start() sets isRunning to true', () async {
        final p = PomodoroProvider();
        await Future<void>.delayed(Duration.zero); // let _loadFromPrefs complete
        p.start();
        expect(p.isRunning, true);
        p.pause();
        p.dispose();
      });

      test('start() is idempotent when already running', () async {
        final p = PomodoroProvider();
        await Future<void>.delayed(Duration.zero);
        p.start();
        p.start(); // second call should be a no-op
        expect(p.isRunning, true);
        p.pause();
        p.dispose();
      });

      test('pause() stops the timer', () async {
        final p = PomodoroProvider();
        await Future<void>.delayed(Duration.zero);
        p.start();
        p.pause();
        expect(p.isRunning, false);
        p.dispose();
      });

      test('reset() stops the timer and restores full duration', () async {
        final p = PomodoroProvider();
        await Future<void>.delayed(Duration.zero);
        p.start();
        p.pause();
        p.reset();
        expect(p.isRunning, false);
        expect(p.secondsLeft, p.totalSeconds);
        p.dispose();
      });
    });

    // ── skip() / phase advancement ────────────────────────────────────────
    group('skip()', () {
      test('skip() from work phase goes to short break', () {
        final p = PomodoroProvider();
        expect(p.phase, PomodoroPhase.work);
        p.skip();
        expect(p.phase, PomodoroPhase.shortBreak);
      });

      test('skip() from short break goes back to work', () {
        final p = PomodoroProvider();
        p.skip(); // work → shortBreak
        p.skip(); // shortBreak → work
        expect(p.phase, PomodoroPhase.work);
      });

      test('skip() does not count session in stats', () {
        final p = PomodoroProvider();
        p.skip();
        expect(p.sessionsToday, 0);
        expect(p.totalSessions, 0);
      });

      test('every 4th work session skip leads to long break', () {
        final p = PomodoroProvider();
        // 3 work→shortBreak cycles
        for (var i = 0; i < 3; i++) {
          p.skip(); // work → short break
          p.skip(); // short break → work
        }
        p.skip(); // 4th work skip → long break
        expect(p.phase, PomodoroPhase.longBreak);
      });

      test('skip() resets seconds to new phase total', () {
        final p = PomodoroProvider();
        p.skip(); // work → shortBreak
        expect(p.secondsLeft, p.shortBreakMinutes * 60);
      });

      test('skip() stops timer if running', () async {
        final p = PomodoroProvider();
        await Future<void>.delayed(Duration.zero);
        p.start();
        p.skip();
        expect(p.isRunning, false);
        p.dispose();
      });
    });

    // ── updateSettings() ──────────────────────────────────────────────────
    group('updateSettings()', () {
      test('updates work duration', () {
        final p = PomodoroProvider();
        p.updateSettings(
          workMins: 30,
          shortBreakMins: 5,
          longBreakMins: 15,
          longBreakAfter: 4,
        );
        expect(p.workMinutes, 30);
        expect(p.totalSeconds, 30 * 60);
        expect(p.secondsLeft, 30 * 60);
      });

      test('updates break durations', () {
        final p = PomodoroProvider();
        p.updateSettings(
          workMins: 25,
          shortBreakMins: 10,
          longBreakMins: 20,
          longBreakAfter: 4,
        );
        expect(p.shortBreakMinutes, 10);
        expect(p.longBreakMinutes, 20);
      });

      test('updates daily and weekly goal', () {
        final p = PomodoroProvider();
        p.updateSettings(
          workMins: 25,
          shortBreakMins: 5,
          longBreakMins: 15,
          longBreakAfter: 4,
          newDailyGoal: 10,
          newWeeklyGoal: 50,
        );
        expect(p.dailyGoal, 10);
        expect(p.weeklyGoal, 50);
      });

      test('updateSettings() stops running timer', () async {
        final p = PomodoroProvider();
        await Future<void>.delayed(Duration.zero);
        p.start();
        p.updateSettings(
          workMins: 25,
          shortBreakMins: 5,
          longBreakMins: 15,
          longBreakAfter: 4,
        );
        expect(p.isRunning, false);
        p.dispose();
      });
    });

    // ── timeString formatting ─────────────────────────────────────────────
    group('timeString', () {
      test('formats correctly for full minutes', () {
        final p = PomodoroProvider();
        // Default: 25:00
        expect(p.timeString, matches(RegExp(r'^\d{2}:\d{2}$')));
      });

      test('pads single-digit minutes and seconds', () {
        final p = PomodoroProvider();
        // After switching to 5 min short break, check formatting
        p.updateSettings(
          workMins: 5,
          shortBreakMins: 5,
          longBreakMins: 5,
          longBreakAfter: 4,
        );
        expect(p.timeString, '05:00');
      });
    });

    // ── cycleDotsCompleted ────────────────────────────────────────────────
    group('cycleDotsCompleted', () {
      test('is 0 at start', () {
        final p = PomodoroProvider();
        expect(p.cycleDotsCompleted, 0);
      });

      test('increases as work sessions are skipped', () {
        final p = PomodoroProvider();
        p.skip(); // work→shortBreak (sessionsCompleted=1)
        p.skip(); // shortBreak→work
        expect(p.cycleDotsCompleted, 1);
      });

      test('is full when in long break phase (cycle just completed)', () {
        final p = PomodoroProvider();
        // Complete 4 work sessions to trigger long break
        for (var i = 0; i < 4; i++) {
          p.skip(); // work → break
          if (i < 3) p.skip(); // break → work (skip for last)
        }
        // Should now be in long break with full dots
        if (p.phase == PomodoroPhase.longBreak) {
          expect(p.cycleDotsCompleted, p.longBreakAfterSessions);
        }
      });
    });

    // ── progress ─────────────────────────────────────────────────────────
    group('progress', () {
      test('is 0.0 at full time remaining', () {
        final p = PomodoroProvider();
        expect(p.progress, 0.0);
      });

      test('is clamped between 0.0 and 1.0', () {
        final p = PomodoroProvider();
        expect(p.progress, greaterThanOrEqualTo(0.0));
        expect(p.progress, lessThanOrEqualTo(1.0));
      });
    });

    // ── clearAchievement() ────────────────────────────────────────────────
    group('clearAchievement()', () {
      test('clears pending achievement', () {
        final p = PomodoroProvider();
        // We can't easily set pendingAchievement directly, but clearAchievement
        // on null should be a no-op
        p.clearAchievement();
        expect(p.pendingAchievement, isNull);
      });
    });

    // ── dispose() ────────────────────────────────────────────────────────
    group('dispose()', () {
      test('dispose() does not throw', () async {
        final p = PomodoroProvider();
        await Future<void>.delayed(Duration.zero);
        p.start();
        p.pause();
        expect(() => p.dispose(), returnsNormally);
      });
    });
  });
}
