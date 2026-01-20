import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';
import '../services/database_service.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final DatabaseService _db = DatabaseService.instance;
  Weather? _currentWeather;
  List<Map<String, dynamic>>? _forecast;
  List<Map<String, dynamic>>? _hourlyForecast; // NEW: Hourly support
  String? _selectedLocation;
  String? _selectedState; // Province/State info
  String? _selectedDistrict; // District/İlçe info
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdate;
  bool _isExpanded = false;
  Timer? _refreshTimer;

  Weather? get currentWeather => _currentWeather;
  List<Map<String, dynamic>>? get forecast => _forecast;
  List<Map<String, dynamic>>? get hourlyForecast => _hourlyForecast; // NEW getter
  String? get selectedLocation => _selectedLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdate => _lastUpdate;
  bool get isExpanded => _isExpanded;

  static const String _locationKey = 'weather_location';
  static const String _weatherKey = 'weather_data';
  static const String _lastUpdateKey = 'weather_last_update';

  /// Initialize provider and load cached data
  Future<void> initialize({String? language}) async {
    await _loadFromDatabase();
    
    // If we have a location, check if refresh is needed
    if (_selectedLocation != null) {
      if (needsRefresh()) {
        // Use provided language or default to 'tr' for Turkish
        await fetchWeather(
          _selectedLocation!, 
          language: language ?? 'tr',
          state: _selectedState,
          district: _selectedDistrict,
        );
      }
    }
    
    // Start auto-refresh timer (6 hours)
    startAutoRefresh();
  }

  /// Load weather data from database
  Future<void> _loadFromDatabase() async {
    try {
      // Load location from database
      final locationData = await _db.getUserLocation();
      if (locationData != null) {
        _selectedLocation = locationData['city_name'] as String;
        _selectedState = locationData['state'] as String?;
        _selectedDistrict = locationData['district'] as String?;
      }
      
      // Load weather from SharedPreferences (temporary cache)
      final prefs = await SharedPreferences.getInstance();
      final weatherJson = prefs.getString(_weatherKey);
      if (weatherJson != null) {
        final data = json.decode(weatherJson);
        _currentWeather = Weather.fromCache(data);
      }
      
      final forecastJson = prefs.getString('weather_forecast');
      if (forecastJson != null) {
        _forecast = List<Map<String, dynamic>>.from(json.decode(forecastJson));
      }

      final hourlyJson = prefs.getString('weather_hourly_forecast');
      if (hourlyJson != null) {
        _hourlyForecast = List<Map<String, dynamic>>.from(json.decode(hourlyJson));
      }

      final lastUpdateStr = prefs.getString(_lastUpdateKey);
      if (lastUpdateStr != null) {
        _lastUpdate = DateTime.parse(lastUpdateStr);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading weather from database: $e');
    }
  }

  /// Save weather data to database and cache
  Future<void> _saveToDatabase() async {
    try {
      // Save location to database
      if (_selectedLocation != null && _currentWeather != null) {
        await _db.saveUserLocation({
          'city_name': _currentWeather!.cityName,
          'country': _currentWeather!.country,
          'state': _selectedState ?? '',
          'district': _selectedDistrict ?? '',
          'latitude': _currentWeather!.lat,
          'longitude': _currentWeather!.lon,
          'last_updated': DateTime.now().toIso8601String(),
        });
      }
      
      // Save weather to SharedPreferences (temporary cache)
      final prefs = await SharedPreferences.getInstance();
      if (_selectedLocation != null) {
        await prefs.setString(_locationKey, _selectedLocation!);
      }
      
      if (_currentWeather != null) {
        await prefs.setString(_weatherKey, json.encode(_currentWeather!.toJson()));
      }
      
      if (_forecast != null) {
        await prefs.setString('weather_forecast', json.encode(_forecast));
      }
      
      if (_hourlyForecast != null) {
        await prefs.setString('weather_hourly_forecast', json.encode(_hourlyForecast));
      }

      if (_lastUpdate != null) {
        await prefs.setString(_lastUpdateKey, _lastUpdate!.toIso8601String());
      }
    } catch (e) {
      print('Error saving weather to database: $e');
    }
  }

  /// Fetch weather for a location
  Future<void> fetchWeather(String location, {String? language, String? displayLabel, String? state, String? district}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Get coordinates first (1 API call)
      final coords = await _weatherService.getCoordinates(location, language: language);
      if (coords == null) {
        _error = 'Location not found';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      final lat = coords['lat'];
      final lon = coords['lon'];
      
      // Determine the name to display
      // 1. Use explicitly provided label (from search selection)
      // 2. Use official name from API (for raw searches)
      // 3. Fallback to query
      final finalName = displayLabel ?? coords['name'] ?? location;

      // 2. Fetch everything using coordinates (Parallel calls)
      final results = await Future.wait([
        _weatherService.getWeatherByCoordinates(lat, lon, language: language, locationName: finalName),
        _weatherService.getForecastByCoordinates(lat, lon, language: language),
        _weatherService.getHourlyForecast(lat, lon, language: language),
      ]);
      
      final weather = results[0] as Weather?;
      final forecast = results[1] as List<Map<String, dynamic>>?;
      final hourly = results[2] as List<Map<String, dynamic>>?;
      
      if (weather != null) {
        _currentWeather = weather;
        _forecast = forecast;
        _hourlyForecast = hourly; // NEW
        _selectedLocation = finalName;
        _selectedState = state ?? coords['state']; // Use provided state or from API
        _selectedDistrict = district; // Save district info
        _lastUpdate = DateTime.now();
        _error = null;
        await _saveToDatabase();
      } else {
        _error = 'Failed to fetch weather data';
      }
    } catch (e) {
      _error = 'Error: $e';
      print('Error fetching weather: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle expand/collapse state
  void toggleExpand() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  /// Search for cities
  Future<List<Map<String, String>>> searchCities(String query, {String? language}) async {
    return await _weatherService.searchCities(query, language: language);
  }

  /// Set location and fetch weather
  Future<void> setLocation(String location, {String? language, String? displayLabel, String? state, String? district}) async {
    await fetchWeather(location, language: language, displayLabel: displayLabel, state: state, district: district);
  }

  /// Clear weather data
  Future<void> clearWeather() async {
    _currentWeather = null;
    _selectedLocation = null;
    _lastUpdate = null;
    _error = null;
    
    // Clear from database
    await _db.deleteUserLocation();
    
    // Clear from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_locationKey);
    await prefs.remove(_weatherKey);
    await prefs.remove('weather_forecast');
    await prefs.remove('weather_hourly_forecast');
    await prefs.remove(_lastUpdateKey);
    
    notifyListeners();
  }

  /// Check if weather data needs refresh (older than 6 hours)
  bool needsRefresh() {
    if (_lastUpdate == null) return true;
    final diff = DateTime.now().difference(_lastUpdate!);
    return diff.inHours >= 6;
  }

  /// Refresh weather if needed
  Future<void> refreshIfNeeded() async {
    if (_selectedLocation != null && needsRefresh()) {
      await fetchWeather(_selectedLocation!);
    }
  }

  /// Start auto-refresh timer (6 hours)
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(hours: 6), (_) {
      if (_selectedLocation != null) {
        fetchWeather(
          _selectedLocation!,
          state: _selectedState,
          district: _selectedDistrict,
        );
      }
    });
  }

  /// Stop auto-refresh timer
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
