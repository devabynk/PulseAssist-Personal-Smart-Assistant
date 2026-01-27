import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:alarm/alarm.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'providers/settings_provider.dart';
import 'l10n/app_localizations.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'services/ai/ai_manager.dart';
import 'providers/chat_provider.dart';
import 'providers/alarm_provider.dart';
import 'providers/note_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/weather_provider.dart';
import 'screens/alarm_ring_screen.dart' as import_screens;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Database Service (Hive)
  await DatabaseService.instance.init();
  
  // Initialize alarm package for reliable background alarms
  await Alarm.init();
  
  // Initialize notification service safely - app should continue even if it fails
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    // Continue even if notification initialization fails
    debugPrint('Notification service initialization failed: $e');
  }
  
  // Initialize AI Manager (multi-provider with fallback)
  try {
    await AiManager.instance.initialize();
  } catch (e) {
    debugPrint('AI Manager initialization failed: $e');
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

class _PulseAssistAppState extends State<PulseAssistApp> {
  @override
  void initState() {
    super.initState();
    // Listen for alarm ring events
    Alarm.ringStream.stream.listen((alarmSettings) {
      debugPrint('Alarm Ring Stream Received: ${alarmSettings.id}');
      
      // Delegate state updates (logging, deactivation) to provider
      // context.read is safe to use within the callback usually, but check mounted
      if (mounted) {
         context.read<AlarmProvider>().handleAlarmRing(alarmSettings);
      }
      
      // Navigate to Ring Screen
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => import_screens.AlarmRingScreen(alarmSettings: alarmSettings),
        ),
      );
    });
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
          supportedLocales: const [
            Locale('tr', ''),
            Locale('en', ''),
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}
