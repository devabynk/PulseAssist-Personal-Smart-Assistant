import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../core/utils/key_manager.dart';
import '../models/event.dart';

class EventsService {
  final KeyManager _keyManager = KeyManager(
    ApiConfig.eventApiKeys,
    serviceName: 'Events',
  );
  static const String _baseUrl =
      'https://app.ticketmaster.com/discovery/v2/events.json';

  /// Fetch events for a Turkish location.
  ///
  /// [city]     — İl (province/city) name, e.g. "Istanbul", "Ankara"
  /// [district] — İlçe (district) name, e.g. "Kadikoy", "Besiktas" (optional)
  ///              Used as a keyword to narrow results. If district returns 0
  ///              events, automatically retries with city only.
  /// [countryCode] — ISO 3166-1 alpha-2, defaults to 'TR' for Turkey
  Future<List<Event>> getNearbyEvents(
    String city, {
    String? district,
    int days = 30,
    String lang = 'tr',
    String countryCode = 'TR',
  }) async {
    try {
      return await _keyManager.executeWithRetry((apiKey) async {
        final now = DateTime.now();
        final endDate = now.add(Duration(days: days));

        // Ticketmaster expects YYYY-MM-DDTHH:mm:ssZ
        final startDateTime = '${now.toIso8601String().split('.').first}Z';
        final endDateTime = '${endDate.toIso8601String().split('.').first}Z';

        final normalizedCity = _normalize(city.trim());
        final normalizedDistrict =
            district != null ? _normalize(district.trim()) : null;

        final params = <String, String>{
          'apikey': apiKey,
          'city': normalizedCity,
          'countryCode': countryCode,
          'sort': 'date,asc',
          'size': '20',
          // Accept both locale variants so Turkish event names are returned
          'locale': lang == 'tr' ? 'tr-tr,en-us' : 'en-us,tr-tr',
          'startDateTime': startDateTime,
          'endDateTime': endDateTime,
        };

        // İlçe → keyword filter (Ticketmaster has no native district field)
        final useDistrictKeyword = normalizedDistrict != null &&
            normalizedDistrict.isNotEmpty &&
            normalizedDistrict != normalizedCity;

        if (useDistrictKeyword) {
          params['keyword'] = normalizedDistrict;
        }

        debugPrint(
          'EventsService: city="$normalizedCity" '
          'district="${normalizedDistrict ?? "-"}" '
          'countryCode=$countryCode days=$days',
        );

        final results = await _fetchEvents(params);

        // If district keyword returned nothing, retry city-only
        if (results.isEmpty && useDistrictKeyword) {
          debugPrint(
            'EventsService: No events for district "$normalizedDistrict", '
            'retrying city-only...',
          );
          params.remove('keyword');
          return await _fetchEvents(params);
        }

        return results;
      });
    } catch (e) {
      debugPrint('Events Service Error: $e');
      return [];
    }
  }

  Future<List<Event>> _fetchEvents(Map<String, String> params) async {
    final url = Uri.parse(_baseUrl).replace(queryParameters: params);
    final response =
        await http.get(url).timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['_embedded']?['events'] is List) {
        final List<dynamic> events = data['_embedded']['events'];
        return events.map((e) => Event.fromTicketmaster(e)).toList();
      }
      return [];
    } else if (response.statusCode == 401 || response.statusCode == 429) {
      throw Exception('${response.statusCode}');
    }

    debugPrint(
      'Events API Error: ${response.statusCode} - ${response.body}',
    );
    return [];
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
