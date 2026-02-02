import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/alarm_provider.dart';
import '../theme/app_theme.dart';

class AlarmRingScreen extends StatelessWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingScreen({super.key, required this.alarmSettings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.primary,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Spacer(),
            // Animated Icon or Image
            const Icon(Icons.alarm, size: 100, color: Colors.white),
            const SizedBox(height: 30),
            // Time
            Text(
              "${alarmSettings.dateTime.hour.toString().padLeft(2, '0')}:${alarmSettings.dateTime.minute.toString().padLeft(2, '0')}",
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                alarmSettings.notificationSettings.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, color: Colors.white70),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                alarmSettings.notificationSettings.body,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.white60),
              ),
            ),
            const Spacer(),
            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  // Snooze Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          // Snooze for 5 minutes
                          const duration = Duration(minutes: 5);
                          await Provider.of<AlarmProvider>(
                            context,
                            listen: false,
                          ).snoozeAlarm(
                            alarmSettings.id,
                            duration,
                            alarmSettings.notificationSettings.title,
                            alarmSettings.notificationSettings.body,
                          );
                        } catch (e) {
                          debugPrint('Error snoozing alarm: $e');
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.snooze, size: 28),
                      label: Text(
                        AppLocalizations.of(context)!.snoozeButton,
                        style: const TextStyle(fontSize: 20),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppPalette.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stop Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await Provider.of<AlarmProvider>(
                            context,
                            listen: false,
                          ).stopRingingAlarm(alarmSettings.id);
                        } catch (e) {
                          debugPrint('Error stopping alarm: $e');
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.stop_circle_outlined, size: 28),
                      label: Text(
                        AppLocalizations.of(context)!.stopButton,
                        style: const TextStyle(fontSize: 20),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
