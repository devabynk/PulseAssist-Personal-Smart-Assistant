class ApiConfig {
  // Prevent instantiation
  ApiConfig._();

  // Groq API Keys
  // Get yours from: https://console.groq.com/keys
  static const List<String> groqApiKeys = [
    'YOUR_GROQ_API_KEY_1',
    'YOUR_GROQ_API_KEY_2',
  ];

  // CollectAPI (Pharmacy) Keys
  // Get yours from: https://collectapi.com/tr/api/health/nobetci-eczane-api
  static const List<String> pharmacyApiKeys = [
    'apikey YOUR_COLLECT_API_KEY_1',
    'apikey YOUR_COLLECT_API_KEY_2',
  ];

  // Ticketmaster (Events) Key
  // Get yours from: https://developer.ticketmaster.com
  static const String eventApiKey = 'YOUR_TICKETMASTER_API_KEY';

  // OpenWeatherMap API Key
  // Get yours from: https://home.openweathermap.org/api_keys
  static const String weatherApiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
}
