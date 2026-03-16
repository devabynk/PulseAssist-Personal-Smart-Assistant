import 'dart:math' as math;

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/alarm_provider.dart';
import '../theme/app_theme.dart';

class AlarmRingScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingScreen({super.key, required this.alarmSettings});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = widget.alarmSettings.dateTime.hour
        .toString()
        .padLeft(2, '0');
    final minute = widget.alarmSettings.dateTime.minute
        .toString()
        .padLeft(2, '0');
    final title = widget.alarmSettings.notificationSettings.title;
    final body = widget.alarmSettings.notificationSettings.body;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Pulsing alarm icon
              ScaleTransition(
                scale: _pulseAnim,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow ring
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) => Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(
                              ((_pulseController.value) * 80).toInt(),
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // Inner circle
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(30),
                        border: Border.all(
                          color: Colors.white.withAlpha(80),
                          width: 1.5,
                        ),
                      ),
                    ),
                    // Bell icon with slight rotation
                    AnimatedBuilder(
                      animation: _rotateController,
                      builder: (context, _) => Transform.rotate(
                        angle:
                            (_rotateController.value - 0.5) * 0.25 * math.pi / 6,
                        child: const Icon(
                          Icons.alarm_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Time
              Text(
                '$hour:$minute',
                style: GoogleFonts.outfit(
                  fontSize: 72,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                  letterSpacing: -2,
                ),
              ),

              const SizedBox(height: 12),

              // Alarm title
              if (title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

              const SizedBox(height: 6),

              // Alarm body / subtitle
              if (body.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    body,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withAlpha(180),
                    ),
                  ),
                ),

              const Spacer(flex: 2),

              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    // Snooze
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await Provider.of<AlarmProvider>(
                              context,
                              listen: false,
                            ).snoozeAlarm(
                              widget.alarmSettings.id,
                              const Duration(minutes: 5),
                              widget.alarmSettings.notificationSettings.title,
                              widget.alarmSettings.notificationSettings.body,
                            );
                          } catch (_) {}
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.snooze_rounded, size: 22),
                        label: Text(
                          l10n.snoozeButton,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppPalette.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Stop
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await Provider.of<AlarmProvider>(
                              context,
                              listen: false,
                            ).stopRingingAlarm(widget.alarmSettings.id);
                          } catch (_) {}
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.stop_circle_rounded, size: 22),
                        label: Text(
                          l10n.stopButton,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withAlpha(180),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
