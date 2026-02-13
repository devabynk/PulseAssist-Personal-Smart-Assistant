import 'environment.dart';

/// Base configuration class for the application
abstract class AppConfig {
  /// Current environment
  Environment get environment;

  /// Application name
  String get appName;

  /// API base URL
  String get apiBaseUrl;

  /// Enable debug logging
  bool get enableLogging;

  /// Enable analytics
  bool get enableAnalytics;

  /// API timeout duration in seconds
  int get apiTimeout;

  /// Maximum number of retry attempts for failed requests
  int get maxRetryAttempts;

  /// Database name
  String get databaseName;

  /// Enable crash reporting
  bool get enableCrashReporting;
}

/// Development configuration
class DevConfig implements AppConfig {
  @override
  Environment get environment => Environment.development;

  @override
  String get appName => 'PulseAssist (Dev)';

  @override
  String get apiBaseUrl => 'https://api.groq.com/openai/v1';

  @override
  bool get enableLogging => true;

  @override
  bool get enableAnalytics => false;

  @override
  int get apiTimeout => 60;

  @override
  int get maxRetryAttempts => 3;

  @override
  String get databaseName => 'pulse_assist_dev.db';

  @override
  bool get enableCrashReporting => false;
}

/// Staging configuration
class StagingConfig implements AppConfig {
  @override
  Environment get environment => Environment.staging;

  @override
  String get appName => 'PulseAssist (Staging)';

  @override
  String get apiBaseUrl => 'https://api.groq.com/openai/v1';

  @override
  bool get enableLogging => true;

  @override
  bool get enableAnalytics => true;

  @override
  int get apiTimeout => 45;

  @override
  int get maxRetryAttempts => 3;

  @override
  String get databaseName => 'pulse_assist_staging.db';

  @override
  bool get enableCrashReporting => true;
}

/// Production configuration
class ProductionConfig implements AppConfig {
  @override
  Environment get environment => Environment.production;

  @override
  String get appName => 'PulseAssist';

  @override
  String get apiBaseUrl => 'https://api.groq.com/openai/v1';

  @override
  bool get enableLogging => false;

  @override
  bool get enableAnalytics => true;

  @override
  int get apiTimeout => 30;

  @override
  int get maxRetryAttempts => 2;

  @override
  String get databaseName => 'pulse_assist.db';

  @override
  bool get enableCrashReporting => true;
}

/// Factory to get the appropriate configuration based on environment
class ConfigFactory {
  static AppConfig _config = DevConfig();

  /// Initialize configuration based on environment
  static void initialize(Environment environment) {
    switch (environment) {
      case Environment.development:
        _config = DevConfig();
        break;
      case Environment.staging:
        _config = StagingConfig();
        break;
      case Environment.production:
        _config = ProductionConfig();
        break;
    }
  }

  /// Get current configuration
  static AppConfig get config => _config;
}
