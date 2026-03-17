import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/extensions.dart';
import '../providers/pomodoro_provider.dart';
import '../theme/app_theme.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: context.read<PomodoroProvider>(),
      child: const _PomodoroView(),
    );
  }
}

class _PomodoroView extends StatelessWidget {
  const _PomodoroView();

  Color _phaseColor(PomodoroPhase phase, bool isDark) {
    switch (phase) {
      case PomodoroPhase.work:
        return AppColors.primary;
      case PomodoroPhase.shortBreak:
        return const Color(0xFF4CAF50);
      case PomodoroPhase.longBreak:
        return const Color(0xFF2196F3);
    }
  }

  String _phaseLabel(PomodoroPhase phase, BuildContext context) {
    final l10n = context.l10n;
    switch (phase) {
      case PomodoroPhase.work:
        return l10n.workSession;
      case PomodoroPhase.shortBreak:
        return l10n.shortBreak;
      case PomodoroPhase.longBreak:
        return l10n.longBreak;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.pomodoroTimer),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: l10n.pomodoroSettings,
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: Consumer<PomodoroProvider>(
        builder: (context, provider, _) {
          final color = _phaseColor(provider.phase, isDark);
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Phase label
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _phaseLabel(provider.phase, context),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Circular timer
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(260, 260),
                            painter: _TimerPainter(
                              progress: provider.progress,
                              color: color,
                              isDark: isDark,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                provider.timeString,
                                style: TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w300,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.sessionsCompleted(provider.sessionsCompleted),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reset
                        _ControlButton(
                          icon: Icons.refresh_rounded,
                          onTap: provider.reset,
                          size: 48,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(width: 20),
                        // Play/Pause — main button
                        GestureDetector(
                          onTap: provider.isRunning ? provider.pause : provider.start,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withAlpha(180)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withAlpha(80),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              provider.isRunning
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Skip phase
                        _ControlButton(
                          icon: Icons.skip_next_rounded,
                          onTap: provider.skip,
                          size: 48,
                          color: Theme.of(context).hintColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Session dots
                    _SessionDots(
                      completed: provider.sessionsCompleted %
                          provider.longBreakAfterSessions,
                      total: provider.longBreakAfterSessions,
                      color: color,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSettings(BuildContext context) {
    final provider = context.read<PomodoroProvider>();
    var work = provider.workMinutes;
    var shortB = provider.shortBreakMinutes;
    var longB = provider.longBreakMinutes;
    var longAfter = provider.longBreakAfterSessions;
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.pomodoroSettings,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              _SettingRow(
                label: '${l10n.workDuration} (${l10n.minutes})',
                value: work,
                min: 5,
                max: 60,
                onChanged: (v) => setModalState(() => work = v),
              ),
              _SettingRow(
                label: '${l10n.shortBreakDuration} (${l10n.minutes})',
                value: shortB,
                min: 1,
                max: 30,
                onChanged: (v) => setModalState(() => shortB = v),
              ),
              _SettingRow(
                label: '${l10n.longBreakDuration} (${l10n.minutes})',
                value: longB,
                min: 5,
                max: 60,
                onChanged: (v) => setModalState(() => longB = v),
              ),
              _SettingRow(
                label: l10n.longBreakAfter,
                value: longAfter,
                min: 2,
                max: 8,
                onChanged: (v) => setModalState(() => longAfter = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    provider.updateSettings(
                      workMins: work,
                      shortBreakMins: shortB,
                      longBreakMins: longB,
                      longBreakAfter: longAfter,
                    );
                    Navigator.pop(ctx);
                  },
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}

class _SessionDots extends StatelessWidget {
  final int completed;
  final int total;
  final Color color;

  const _SessionDots({
    required this.completed,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final filled = i < completed;
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : color.withAlpha(40),
          ),
        );
      }),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _SettingRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _TimerPainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 8.0;

    // Background track
    final trackPaint = Paint()
      ..color = isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TimerPainter old) =>
      old.progress != progress || old.color != color;
}
