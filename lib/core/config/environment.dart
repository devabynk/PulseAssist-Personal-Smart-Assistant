/// Environment types for the application
enum Environment {
  development,
  staging,
  production;

  /// Check if current environment is development
  bool get isDevelopment => this == Environment.development;

  /// Check if current environment is staging
  bool get isStaging => this == Environment.staging;

  /// Check if current environment is production
  bool get isProduction => this == Environment.production;

  /// Get environment from string
  static Environment fromString(String env) {
    switch (env.toLowerCase()) {
      case 'dev':
      case 'development':
        return Environment.development;
      case 'staging':
      case 'stg':
        return Environment.staging;
      case 'prod':
      case 'production':
        return Environment.production;
      default:
        return Environment.development;
    }
  }
}
