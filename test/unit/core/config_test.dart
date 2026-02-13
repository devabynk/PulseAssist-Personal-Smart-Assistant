import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/core/config/app_config.dart';
import 'package:smart_assistant/core/config/environment.dart';

void main() {
  group('AppConfig Tests', () {
    test('DevConfig should have correct environment', () {
      final config = DevConfig();
      expect(config.environment, Environment.development);
      expect(config.appName, 'PulseAssist (Dev)');
      expect(config.enableLogging, true);
      expect(config.enableAnalytics, false);
    });

    test('StagingConfig should have correct environment', () {
      final config = StagingConfig();
      expect(config.environment, Environment.staging);
      expect(config.appName, 'PulseAssist (Staging)');
      expect(config.enableLogging, true);
      expect(config.enableAnalytics, true);
    });

    test('ProductionConfig should have correct environment', () {
      final config = ProductionConfig();
      expect(config.environment, Environment.production);
      expect(config.appName, 'PulseAssist');
      expect(config.enableLogging, false);
      expect(config.enableAnalytics, true);
    });

    test('ConfigFactory should initialize with correct config', () {
      ConfigFactory.initialize(Environment.development);
      expect(ConfigFactory.config, isA<DevConfig>());

      ConfigFactory.initialize(Environment.staging);
      expect(ConfigFactory.config, isA<StagingConfig>());

      ConfigFactory.initialize(Environment.production);
      expect(ConfigFactory.config, isA<ProductionConfig>());
    });
  });

  group('Environment Tests', () {
    test('Environment.fromString should parse correctly', () {
      expect(Environment.fromString('dev'), Environment.development);
      expect(Environment.fromString('development'), Environment.development);
      expect(Environment.fromString('staging'), Environment.staging);
      expect(Environment.fromString('stg'), Environment.staging);
      expect(Environment.fromString('prod'), Environment.production);
      expect(Environment.fromString('production'), Environment.production);
      expect(Environment.fromString('unknown'), Environment.development);
    });

    test('Environment helpers should work correctly', () {
      expect(Environment.development.isDevelopment, true);
      expect(Environment.development.isStaging, false);
      expect(Environment.development.isProduction, false);

      expect(Environment.staging.isDevelopment, false);
      expect(Environment.staging.isStaging, true);
      expect(Environment.staging.isProduction, false);

      expect(Environment.production.isDevelopment, false);
      expect(Environment.production.isStaging, false);
      expect(Environment.production.isProduction, true);
    });
  });
}
