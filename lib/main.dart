import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:home_widget/home_widget.dart';
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

  // Configure home_widget App Group for iOS widget data sharing
  await HomeWidget.setAppGroupId('group.com.abynk.smartAssistant');

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
  } catch (_) {}

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProxyProvider<NotificationProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (_, notifProvider, chatProvider) {
            chatProvider!.setNotificationProvider(notifProvider);
            return chatProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => AlarmProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
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
  StreamSubscription? _alarmSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen for alarm ring events.
    // Alarm.ringing is a BehaviorSubject that emits on every state change
    // (including when a new alarm is merely scheduled). Track the last shown
    // alarm ID to avoid pushing a duplicate ring screen for the same event.
    int? lastShownRingingId;
    _alarmSubscription = Alarm.ringing.listen((alarmSet) {
      if (alarmSet.alarms.isEmpty) {
        lastShownRingingId = null;
        return;
      }
      final alarmSettings = alarmSet.alarms.last;

      // Skip if we already opened the ring screen for this alarm instance.
      if (alarmSettings.id == lastShownRingingId) return;
      lastShownRingingId = alarmSettings.id;

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
    _alarmSubscription?.cancel();
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
