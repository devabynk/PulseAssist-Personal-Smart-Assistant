import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../core/utils/key_manager.dart';
import '../models/event.dart';
import '../services/database_service.dart';

/// Result returned by [EventsService.getNearbyEvents].
/// Carries both the events list and the resolved location used for display.
class EventsResult {
  final List<Event> events;
  final String city;
  final String district;

  const EventsResult({
    required this.events,
    required this.city,
    required this.district,
  });

  bool get isEmpty => events.isEmpty;

  /// Display label: "District, City" or just "City".
  String get displayLocation =>
      district.isNotEmpty && district != city ? '$district, $city' : city;
}

class EventsService {
  final KeyManager _keyManager = KeyManager(
    ApiConfig.eventApiKeys,
    serviceName: 'Events',
  );
  final DatabaseService _db = DatabaseService.instance;

  static const String _baseUrl =
      'https://app.ticketmaster.com/discovery/v2/events.json';

  /// Fetch nearby events.
  ///
  /// [city] and [district] are optional. When omitted (or empty) the service
  /// reads the user's saved weather/dashboard location from the database and
  /// resolves them automatically:
  ///   - Turkey (country_code == 'TR'): province/il (`state` field) → Ticketmaster city.
  ///   - Other countries: `city_name` (what the user selected) → Ticketmaster city.
  ///
  /// [countryCode] is also auto-resolved from the DB when not supplied.
  Future<EventsResult> getNearbyEvents({
    String? city,
    String? district,
    int days = 30,
    String lang = 'tr',
    String? countryCode,
  }) async {
    var resolvedCity = (city ?? '').trim();
    var resolvedDistrict = (district ?? '').trim();
    var resolvedCountryCode = countryCode;

    // Always read DB: resolves country_code, and city/district when not provided.
    try {
      final locData = await _db.getUserLocation();
      if (locData != null) {
        // country_code from DB takes precedence when not explicitly supplied
        resolvedCountryCode ??= locData['country_code']?.toString();

        if (resolvedCity.isEmpty) {
          final savedState = (locData['state']?.toString() ?? '').trim();
          final savedCityName = (locData['city_name']?.toString() ?? '').trim();
          final savedDistrict = (locData['district']?.toString() ?? '').trim();

          // Turkey: Ticketmaster recognises the province (il/state) as city.
          // Other countries: city_name is the actual city the user selected
          // (e.g. "Los Angeles", not "California").
          if (resolvedCountryCode == 'TR') {
            resolvedCity = savedState.isNotEmpty ? savedState : savedCityName;
            // Don't use district as keyword for TR — Ticketmaster's keyword filter
            // is too narrow for district names and returns no results.
          } else {
            resolvedCity = savedCityName.isNotEmpty ? savedCityName : savedState;
            if (resolvedDistrict.isEmpty) {
              if (savedDistrict.isNotEmpty && savedDistrict != resolvedCity) {
                resolvedDistrict = savedDistrict;
              } else if (savedCityName.isNotEmpty && savedCityName != resolvedCity) {
                resolvedDistrict = savedCityName;
              }
            }
          }
        }
      }
    } catch (_) {}

    if (resolvedCity.isEmpty) {
      return const EventsResult(events: [], city: '', district: '');
    }

    try {
      final events = await _keyManager.executeWithRetry((apiKey) async {
        final now = DateTime.now();
        final endDate = now.add(Duration(days: days));

        // Ticketmaster expects YYYY-MM-DDTHH:mm:ssZ
        final startDateTime = '${now.toIso8601String().split('.').first}Z';
        final endDateTime = '${endDate.toIso8601String().split('.').first}Z';

        final normalizedCity = _normalize(resolvedCity);
        final normalizedDistrict = resolvedDistrict.isNotEmpty
            ? _normalize(resolvedDistrict)
            : null;

        final params = <String, String>{
          'apikey': apiKey,
          'city': normalizedCity,
          'sort': 'date,asc',
          'size': '20',
          'locale': '*',
          'startDateTime': startDateTime,
          'endDateTime': endDateTime,
        };

        // Scope to country only when known — omitting enables global search
        if (resolvedCountryCode != null && resolvedCountryCode.isNotEmpty) {
          params['countryCode'] = resolvedCountryCode;
        }

        // District as keyword filter (Ticketmaster has no native district field)
        final useDistrictKeyword = normalizedDistrict != null &&
            normalizedDistrict.isNotEmpty &&
            normalizedDistrict != normalizedCity;

        if (useDistrictKeyword) {
          params['keyword'] = normalizedDistrict;
        }

        var results = await _fetchEvents(params);

        // If district keyword returned nothing, retry city-only
        if (results.isEmpty && useDistrictKeyword) {
          params.remove('keyword');
          results = await _fetchEvents(params);
        }

        // If still empty and we had a countryCode, retry without it — some
        // Ticketmaster markets index events without a strict country tag.
        if (results.isEmpty && params.containsKey('countryCode')) {
          params.remove('countryCode');
          results = await _fetchEvents(params);
        }

        return results;
      });

      return EventsResult(
        events: events,
        city: resolvedCity,
        district: resolvedDistrict,
      );
    } catch (_) {
      return EventsResult(
        events: const [],
        city: resolvedCity,
        district: resolvedDistrict,
      );
    }
  }

  Future<List<Event>> _fetchEvents(Map<String, String> params) async {
    final url = Uri.parse(_baseUrl).replace(queryParameters: params);
    final response = await http.get(url).timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['_embedded']?['events'] is List) {
        final List<dynamic> events = data['_embedded']['events'];
        return events.map((e) => Event.fromTicketmaster(e)).toList();
      }
      // 200 OK but no events — legitimate empty result
      return [];
    }

    // Any non-200 response throws so KeyManager can rotate to the next key
    throw Exception('${response.statusCode}');
  }

  /// Converts Turkish characters to their ASCII equivalents for Ticketmaster.
  String _normalize(String text) {
    const map = {
      'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
      'Ç': 'C', 'Ğ': 'G', 'İ': 'I', 'Ö': 'O', 'Ş': 'S', 'Ü': 'U',
    };
    var result = text;
    map.forEach((k, v) => result = result.replaceAll(k, v));
    return result;
  }
}
