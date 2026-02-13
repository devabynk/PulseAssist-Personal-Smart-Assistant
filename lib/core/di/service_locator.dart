import 'package:get_it/get_it.dart';

import '../../services/ai/ai_manager.dart';
import '../../services/database_service.dart';
import '../../services/nlp/nlp_engine.dart';
import '../../services/notification_service.dart';
import '../config/app_config.dart';
import '../error/error_handler.dart';
import '../logging/app_logger.dart';

/// Service locator for dependency injection
final getIt = GetIt.instance;

/// Initialize dependency injection
Future<void> setupServiceLocator({AppConfig? config}) async {
  // Core services
  getIt.registerLazySingleton<AppLogger>(() => AppLogger.instance);
  getIt.registerLazySingleton<ErrorHandler>(() => ErrorHandler.instance);

  // Configuration
  if (config != null) {
    getIt.registerSingleton<AppConfig>(config);
  }

  // Database service
  getIt.registerLazySingleton<DatabaseService>(() => DatabaseService.instance);

  // Notification service
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService.instance,
  );

  // NLP Engine
  getIt.registerLazySingleton<NlpEngine>(() => NlpEngine.instance);

  // AI Manager
  getIt.registerLazySingleton<AiManager>(() => AiManager.instance);

  // Initialize logger
  getIt<AppLogger>().initialize(config: config);

  // Initialize error handler
  getIt<ErrorHandler>().initialize();
}

/// Reset service locator (useful for testing)
Future<void> resetServiceLocator() async {
  await getIt.reset();
}
