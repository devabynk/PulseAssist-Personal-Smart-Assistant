import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather.dart';
import '../config/api_config.dart';
import '../utils/key_manager.dart';

class WeatherService {
  final KeyManager _keyManager = KeyManager(ApiConfig.weatherApiKeys, serviceName: 'Weather');
  static const String _baseUrl = 'https://api.openweathermap.org';

  /// Get coordinates from location query (supports hierarchy)
  /// Examples: "Kadıköy, İstanbul", "New York, NY", "London, UK"
  Future<Map<String, dynamic>?> getCoordinates(String query, {String? language}) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      
      return await _keyManager.executeWithRetry((apiKey) async {
        final url = Uri.parse('$_baseUrl/geo/1.0/direct?q=$encodedQuery&limit=1&appid=$apiKey');
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          if (data.isNotEmpty) {
            final location = data[0];
            return {
              'lat': location['lat'] ?? 0.0,
              'lon': location['lon'] ?? 0.0,
              'name': location['name'] ?? 'Unknown',
              'country': location['country'] ?? '',
              'state': location['state']?.toString() ?? '', 
            };
          }
          return null;
        } else if (response.statusCode == 401 || response.statusCode == 429) {
           throw Exception('${response.statusCode} Error'); // Trigger retry
        } else {
           debugPrint('Geocoding API Error: ${response.statusCode}');
           return null;
        }
      });
    } catch (e) {
      debugPrint('Geocoding Error: $e');
      return null;
    }
  }

  /// Fetch current weather for a given location
  Future<Weather?> getCurrentWeather(String location, {String? language}) async {
    try {
      // First, get coordinates from location
      final coords = await getCoordinates(location, language: language);
      if (coords == null) return null;

      return await getWeatherByCoordinates(
        coords['lat'], 
        coords['lon'],
        language: language,
        locationName: coords['name'],
        country: coords['country'],
      );
    } catch (e) {
      debugPrint('Get Current Weather Error: $e');
      return null;
    }
  }

  /// Get weather by coordinates (Using Standard 2.5/weather API)
  Future<Weather?> getWeatherByCoordinates(
    double lat, 
    double lon, 
    {String? language, String? locationName, String? country}
  ) async {
    final lang = language ?? 'en';
    
    return await _keyManager.executeWithRetry((apiKey) async {
        // 1. Try One Call API 3.0 (Best precision, requires subscription)
        try {
          final url = Uri.parse(
            '$_baseUrl/data/3.0/onecall?lat=$lat&lon=$lon&exclude=minutely,hourly,daily,alerts&units=metric&lang=$lang&appid=$apiKey'
          );
          
          final response = await http.get(url);
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            return Weather.fromOpenWeatherMap(
              data, 
              locationName: locationName ?? 'Unknown',
              country: country ?? '',
            );
          } else if (response.statusCode == 401 && response.body.contains("subscription")) {
             // Special case: valid key but no subscription. 
             // This is NOT an auth failure to rotate, just feature unavailable.
             // Fall through to 2.5
             debugPrint('OneCall 3.0 requires subscription. Falling back to Standard 2.5...');
          } else if (response.statusCode == 401 || response.statusCode == 429) {
             throw Exception('${response.statusCode}'); // Key failure
          }
        } catch (e) {
           if (e.toString().contains('401') || e.toString().contains('429')) rethrow;
           debugPrint('OneCall 3.0 Error: $e');
        }

        // 2. Fallback: Standard 2.5/weather API (Free, no card required)
        final url = Uri.parse(
            '$_baseUrl/data/2.5/weather?lat=$lat&lon=$lon&units=metric&lang=$lang&appid=$apiKey'
        );
        
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
            final data = json.decode(response.body);
            return Weather.fromOpenWeatherMap(
            data, 
            locationName: locationName ?? 'Unknown',
            country: country ?? '',
            );
        } else if (response.statusCode == 401 || response.statusCode == 429) {
             throw Exception('${response.statusCode}');
        } else {
            debugPrint('Weather API Error: ${response.statusCode}');
            return null;
        }
    });
  }

  /// Fetch 3-day weather forecast
  Future<List<Map<String, dynamic>>?> getForecast(String location, {String? language}) async {
    try {
      // First, get coordinates from location
      final coords = await getCoordinates(location, language: language);
      if (coords == null) return null;

      return await getForecastByCoordinates(
        coords['lat'], 
        coords['lon'],
        language: language,
      );
    } catch (e) {
      debugPrint('Get Forecast Error: $e');
      return null;
    }
  }

  /// Get forecast by coordinates (Using Standard 2.5/forecast API)
  Future<List<Map<String, dynamic>>?> getForecastByCoordinates(
    double lat, 
    double lon, 
    {String? language}
  ) async {
    final lang = language ?? 'en';

    return await _keyManager.executeWithRetry((apiKey) async {
        // 1. Try One Call API 3.0 (Returns 8 days daily forecast)
        try {
          final url = Uri.parse(
            '$_baseUrl/data/3.0/onecall?lat=$lat&lon=$lon&exclude=current,minutely,hourly,alerts&units=metric&lang=$lang&appid=$apiKey'
          );
          
          final response = await http.get(url);
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final dailyForecasts = data['daily'] as List;
            
            // Return 5 days (skipping today is handled by start index if needed)
            return dailyForecasts.skip(1).take(5).map((day) {
              return {
                'date': DateTime.fromMillisecondsSinceEpoch(day['dt'] * 1000).toIso8601String().split('T')[0],
                'maxTemp': (day['temp']['max'] as num).toDouble(),
                'minTemp': (day['temp']['min'] as num).toDouble(),
                'condition': day['weather'][0]['description'] as String,
                'icon': 'https://openweathermap.org/img/wn/${day['weather'][0]['icon']}@2x.png',
              };
            }).toList();
          } else if (response.statusCode == 401 && response.body.contains("subscription")) {
             debugPrint('OneCall 3.0 requires subscription. Falling back to Standard 2.5...');
          } else if (response.statusCode == 401 || response.statusCode == 429) {
             throw Exception('${response.statusCode}'); // Key failure
          }
        } catch (e) {
           if (e.toString().contains('401') || e.toString().contains('429')) rethrow;
           debugPrint('OneCall 3.0 Forecast Error: $e');
        }

        // 2. Fallback: Standard 2.5/forecast API (5 days / 3 hour)
        try {
          final url = Uri.parse(
            '$_baseUrl/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&lang=$lang&appid=$apiKey'
          );
          
          final response = await http.get(url);
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final list = data['list'] as List;
            
            // Group by day to simulate daily forecast from 3-hourly data
            final Map<String, List<dynamic>> dailyGroups = {};
            
            for (var item in list) {
              final dateStr = item['dt_txt'].toString().split(' ')[0];
              // Skip today
              if (dateStr == DateTime.now().toString().split(' ')[0]) continue;
              
              if (!dailyGroups.containsKey(dateStr)) {
                dailyGroups[dateStr] = [];
              }
              dailyGroups[dateStr]!.add(item);
            }
            
            // Take next 5 days
            return dailyGroups.entries.take(5).map((entry) {
              final items = entry.value;
              
              // Calculate min/max temp
              double minTemp = 1000;
              double maxTemp = -1000;
              String icon = items[0]['weather'][0]['icon'];
              String description = items[0]['weather'][0]['description'];
              
              for (var item in items) {
                final double tempMin = (item['main']['temp_min'] as num).toDouble();
                final double tempMax = (item['main']['temp_max'] as num).toDouble();
                if (tempMin < minTemp) minTemp = tempMin;
                if (tempMax > maxTemp) maxTemp = tempMax;
                
                // Pick icon from midday (closest to 12:00)
                if (item['dt_txt'].toString().contains('12:00:00')) {
                    icon = item['weather'][0]['icon'];
                    description = item['weather'][0]['description'];
                }
              }

              return {
                'date': entry.key,
                'maxTemp': maxTemp,
                'minTemp': minTemp,
                'condition': description,
                'icon': 'https://openweathermap.org/img/wn/$icon@2x.png',
              };
            }).toList();
          } else if (response.statusCode == 401 || response.statusCode == 429) {
             throw Exception('${response.statusCode}');
          } else {
            debugPrint('Forecast API Error: ${response.statusCode}');
            return null;
          }
        } catch (e) {
          if (e.toString().contains('401') || e.toString().contains('429')) rethrow;
          debugPrint('Forecast Service Error: $e');
          return null;
        }
    });
  }

  /// Get hourly forecast (Next 24 hours)
  Future<List<Map<String, dynamic>>?> getHourlyForecast(
    double lat, 
    double lon, 
    {String? language}
  ) async {
    final lang = language ?? 'en';

    return await _keyManager.executeWithRetry((apiKey) async {
        // 1. Try One Call API 3.0 (Hourly)
        try {
          final url = Uri.parse(
            '$_baseUrl/data/3.0/onecall?lat=$lat&lon=$lon&exclude=current,minutely,daily,alerts&units=metric&lang=$lang&appid=$apiKey'
          );
          
          final response = await http.get(url);
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final hourly = data['hourly'] as List;
            
            // Take next 24 hours
            return hourly.take(24).map((hour) {
              final dt = DateTime.fromMillisecondsSinceEpoch(hour['dt'] * 1000);
              return {
                'time': '${dt.hour.toString().padLeft(2, '0')}:00',
                'temp': (hour['temp'] as num).toDouble(),
                'condition': hour['weather'][0]['description'] as String,
                'icon': 'https://openweathermap.org/img/wn/${hour['weather'][0]['icon']}@2x.png',
                'dt': dt.toIso8601String(),
              };
            }).toList();
          } else if (response.statusCode == 401 && response.body.contains("subscription")) {
             debugPrint('OneCall 3.0 requires subscription. Falling back to Standard 2.5...');
          } else if (response.statusCode == 401 || response.statusCode == 429) {
             throw Exception('${response.statusCode}');
          }
        } catch (e) {
           if (e.toString().contains('401') || e.toString().contains('429')) rethrow;
           debugPrint('OneCall 3.0 Hourly Error: $e');
        }

        // 2. Fallback: Standard 2.5/forecast API (3-hourly)
        try {
          final url = Uri.parse(
            '$_baseUrl/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&lang=$lang&appid=$apiKey'
          );
          
          final response = await http.get(url);
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final list = data['list'] as List;
            
            // Take next 8 items (8 * 3 = 24 hours)
            return list.take(8).map((item) {
              final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
              return {
                'time': '${dt.hour.toString().padLeft(2, '0')}:00',
                'temp': (item['main']['temp'] as num).toDouble(),
                'condition': item['weather'][0]['description'] as String,
                'icon': 'https://openweathermap.org/img/wn/${item['weather'][0]['icon']}@2x.png',
                'dt': dt.toIso8601String(),
              };
            }).toList();
          } else if (response.statusCode == 401 || response.statusCode == 429) {
             throw Exception('${response.statusCode}');
          } else {
            return null;
          }
        } catch (e) {
          if (e.toString().contains('401') || e.toString().contains('429')) rethrow;
          debugPrint('Hourly Forecast Error: $e');
          return null;
        }
    });
  }

  /// Get location details from coordinates (Reverse Geocoding)
  /// Returns state/province information for given coordinates
  Future<Map<String, String>?> _reverseGeocode(double lat, double lon, String apiKey, {String? language}) async {
    try {
      final url = Uri.parse('$_baseUrl/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=$apiKey');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final location = data[0];
          final name = location['name'] as String? ?? '';
          final state = location['state']?.toString() ?? '';
          final country = location['country'] as String? ?? '';
          
          // Get localized name if available
          String localizedName = name;
          if (location['local_names'] != null) {
            final localNames = location['local_names'] as Map<String, dynamic>;
            if (language == 'tr' && localNames['tr'] != null) {
              localizedName = localNames['tr'];
            } else if (language == 'en' && localNames['en'] != null) {
              localizedName = localNames['en'];
            }
          }
          
          return {
            'name': localizedName,
            'state': state,
            'country': country,
          };
        }
      } else if (response.statusCode == 401 || response.statusCode == 429) {
          throw Exception('${response.statusCode}');
      }
      return null;
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('429')) rethrow;
      debugPrint('Reverse Geocoding Error: $e');
      return null;
    }
  }

  /// Search for locations with hierarchy support
  /// Supports: "İlçe, İl" (TR), "City, State" (US), "City, Country"
  /// Enhanced: Uses reverse geocoding to get province/district info when missing
  Future<List<Map<String, String>>> searchLocations(String query, {String? language, int limit = 5}) async {
    if (query.isEmpty) return [];
    
    try {
      final lang = language ?? 'en';
      final encodedQuery = Uri.encodeComponent(query);
      
      return await _keyManager.executeWithRetry((apiKey) async {
          final url = Uri.parse('$_baseUrl/geo/1.0/direct?q=$encodedQuery&limit=$limit&appid=$apiKey');
          
          final response = await http.get(url);
          
          if (response.statusCode == 200) {
            final List<dynamic> data = json.decode(response.body);
            
            // Process results and enrich with reverse geocoding if needed
            final List<Map<String, String>> results = [];
            
            for (var location in data) {
              // Extract all available fields safely
              final name = location['name'] as String? ?? '';
              String state = location['state']?.toString() ?? '';
              final country = location['country'] as String? ?? '';
              final lat = (location['lat'] as num?)?.toDouble() ?? 0.0;
              final lon = (location['lon'] as num?)?.toDouble() ?? 0.0;
              
              // Get localized name if available
              String localizedName = name;
              if (location['local_names'] != null) {
                final localNames = location['local_names'] as Map<String, dynamic>;
                // Try to get name in requested language
                if (lang == 'tr' && localNames['tr'] != null) {
                  localizedName = localNames['tr'];
                } else if (lang == 'en' && localNames['en'] != null) {
                  localizedName = localNames['en'];
                }
              }
              
              // District (ilçe) - from reverse geocoding
              String district = '';
              
              // If state is empty or we need district info, try reverse geocoding
              if (lat != 0.0 && lon != 0.0) {
                try {
                    final reverseData = await _reverseGeocode(lat, lon, apiKey, language: lang);
                    if (reverseData != null) {
                      final reverseName = reverseData['name'] ?? '';
                      final reverseState = reverseData['state'] ?? '';
                      
                      // If reverse name is different from searched name, it's likely the district
                      if (reverseName.isNotEmpty && reverseName != localizedName && reverseName != name) {
                        district = reverseName;
                      }
                      
                      // Use reverse state if we don't have it
                      if (state.isEmpty && reverseState.isNotEmpty) {
                        state = reverseState;
                      }
                    }
                } catch (e) {
                   // Ignore reverse geocode error inside loop, proceed with basic info
                   // Unless it is a key error, in which case executeWithRetry would catch it if rethrown.
                   // _reverseGeocode rethrows 401/429, so we should allow it to bubble up to trigger retry.
                   if (e.toString().contains('401') || e.toString().contains('429')) rethrow;
                }
              }
              
              // Build display name smartly with district
              // Format: Name, District, State, Country (avoiding duplicates)
              final List<String> parts = [localizedName];
              
              // Add district if different from name and state
              if (district.isNotEmpty && district != localizedName && district != name && district != state) {
                parts.add(district);
              }
              
              if (state.isNotEmpty && state != localizedName && state != name) {
                // Some countries don't use state in address conventionally, but OWM provides it
                // Only add if it's distinct enough
                 parts.add(state);
              }
              
              if (country.isNotEmpty) {
                 parts.add(country);
              }
              
              final displayName = parts.join(', ');
              
              results.add({
                'name': localizedName,
                'displayName': displayName,
                'district': district,
                'state': state,
                'country': country,
                'lat': lat.toString(),
                'lon': lon.toString(),
              });
            }
            
            return results;
          } else if (response.statusCode == 401 || response.statusCode == 429) {
             throw Exception('${response.statusCode}');
          } else {
            debugPrint('Search API Error: ${response.statusCode}');
            return [];
          }
      });
    } catch (e) {
      debugPrint('Search Service Error: $e');
      return [];
    }
  }

  /// Search for cities (backward compatibility wrapper)
  Future<List<Map<String, String>>> searchCities(String query, {String? language}) async {
    return await searchLocations(query, language: language);
  }
}
