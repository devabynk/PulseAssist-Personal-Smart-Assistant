import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/alarm_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/note_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/weather_provider.dart';
import 'screens/alarm_ring_screen.dart' as import_screens;
import 'screens/splash_screen.dart';
import 'services/ai/ai_manager.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Database Service (Hive) - CRITICAL: Must succeed
  await DatabaseService.instance.init();

  // Initialize alarm package for reliable background alarms
  await Alarm.init();

  // Initialize notification service safely - app should continue even if it fails
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    // Continue even if notification initialization fails
  }

  // Initialize AI Manager (multi-provider with fallback)
  try {
    await AiManager.instance.initialize();
  } catch (e) {
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => AlarmProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()..initialize()),
      ],
      child: const PulseAssistApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class PulseAssistApp extends StatefulWidget {
  const PulseAssistApp({super.key});

  @override
  State<PulseAssistApp> createState() => _PulseAssistAppState();
}

class _PulseAssistAppState extends State<PulseAssistApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen for alarm ring events
    Alarm.ringing.listen((alarmSet) {
      if (alarmSet.alarms.isEmpty) return;
      final alarmSettings = alarmSet.alarms.last;

      // Both provider update and navigation must be guarded by mounted
      if (!mounted) return;

      context.read<AlarmProvider>().handleAlarmRing(alarmSettings);

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) =>
              import_screens.AlarmRingScreen(alarmSettings: alarmSettings),
        ),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // Flush and close Hive boxes cleanly when the app process is ending
      DatabaseService.instance.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'PulseAssist',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          locale: settings.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr', ''), Locale('en', '')],
          home: const SplashScreen(),
        );
      },
    );
  }
}
