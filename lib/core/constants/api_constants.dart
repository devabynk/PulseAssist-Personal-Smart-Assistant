/// API-related constants
library;

class ApiConstants {
  ApiConstants._();

  // Base URLs
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String weatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String pharmacyBaseUrl = 'https://api.collectapi.com';
  static const String ticketmasterBaseUrl = 'https://app.ticketmaster.com/discovery/v2';

  // Groq API Endpoints
  static const String groqChatEndpoint = '/chat/completions';
  static const String groqModelsEndpoint = '/models';

  // Weather API Endpoints
  static const String weatherCurrentEndpoint = '/weather';
  static const String weatherForecastEndpoint = '/forecast';

  // Pharmacy API Endpoints
  static const String pharmacyEndpoint = '/health/dutyPharmacy';

  // Ticketmaster API Endpoints
  static const String eventsEndpoint = '/events.json';

  // AI Model Names
  static const String primaryChatModel = 'deepseek-r1-distill-llama-70b';
  static const String fallbackChatModel = 'llama-3.3-70b-versatile';
  static const String visionModel = 'llama-3.2-90b-vision-preview';
  static const String audioModel = 'whisper-large-v3';

  // Request Headers
  static const String headerContentType = 'Content-Type';
  static const String headerAuthorization = 'Authorization';
  static const String headerApiKey = 'authorization';

  // Content Types
  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormData = 'multipart/form-data';

  // HTTP Status Codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusTooManyRequests = 429;
  static const int statusInternalServerError = 500;
  static const int statusServiceUnavailable = 503;

  // Error Messages
  static const String errorNetworkFailure = 'Network connection failed';
  static const String errorServerFailure = 'Server error occurred';
  static const String errorUnauthorized = 'Unauthorized access';
  static const String errorNotFound = 'Resource not found';
  static const String errorTimeout = 'Request timeout';
  static const String errorRateLimit = 'Rate limit exceeded';
  static const String errorUnknown = 'An unknown error occurred';
}
