/// Application-wide constants
library;

class AppConstants {
  AppConstants._();

  // App Information
  static const String appName = 'PulseAssist';
  static const String appDescription = 'Your Smart Personal Assistant';
  static const String appVersion = '1.3.3';

  // Database
  static const String databaseName = 'pulse_assist.db';
  static const int databaseVersion = 1;

  // Hive Boxes
  static const String conversationsBox = 'conversations';
  static const String messagesBox = 'messages';
  static const String alarmsBox = 'alarms';
  static const String notesBox = 'notes';
  static const String remindersBox = 'reminders';
  static const String notificationLogsBox = 'notification_logs';
  static const String userHabitsBox = 'user_habits';
  static const String userLocationsBox = 'user_locations';

  // Shared Preferences Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyLocale = 'locale';
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String keyLastWeatherUpdate = 'last_weather_update';
  static const String keySelectedCity = 'selected_city';
  static const String keySelectedDistrict = 'selected_district';

  // API Timeouts (in seconds)
  static const int defaultTimeout = 30;
  static const int longTimeout = 60;
  static const int shortTimeout = 15;

  // Retry Configuration
  static const int maxRetryAttempts = 3;
  static const int retryDelayMs = 1000;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;

  // Animation Durations (in milliseconds)
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String fullDateTimeFormat = 'EEEE, dd MMMM yyyy HH:mm';

  // Notification Channels
  static const String alarmChannelId = 'alarm_channel';
  static const String alarmChannelName = 'Alarms';
  static const String reminderChannelId = 'reminder_channel';
  static const String reminderChannelName = 'Reminders';
  static const String generalChannelId = 'general_channel';
  static const String generalChannelName = 'General Notifications';

  // File Paths
  static const String notesDirectory = 'notes';
  static const String voiceNotesDirectory = 'voice_notes';
  static const String imagesDirectory = 'images';
  static const String backupsDirectory = 'backups';

  // Limits
  static const int maxMessageLength = 5000;
  static const int maxNoteLength = 50000;
  static const int maxTitleLength = 100;
  static const int maxConversationHistory = 50;
  static const int maxSearchResults = 100;

  // Cache Duration (in hours)
  static const int weatherCacheDuration = 1;
  static const int pharmacyCacheDuration = 24;
  static const int eventsCacheDuration = 6;
}
