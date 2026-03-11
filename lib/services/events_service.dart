import 'dart:convert';

import 'package:flutter/foundation.dart'; // For debugPrint
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

  Future<List<Event>> getNearbyEvents(
    String location, {
    int days = 7,
    String lang = 'tr',
  }) async {
    try {
      return await _keyManager.executeWithRetry((apiKey) async {
        final now = DateTime.now();
        final endDate = now.add(Duration(days: days));
        
        // Ticketmaster expects YYYY-MM-DDTHH:mm:ssZ
        final endDateTime = '${endDate.toIso8601String().split('.').first}Z';

        // Ticketmaster searches by city name directly
        final url = Uri.parse(_baseUrl).replace(
          queryParameters: {
            'apikey': apiKey,
            'city': _normalize(location),
            'sort': 'date,asc',
            'size': '15',
            'locale': lang == 'tr' ? 'tr-tr' : 'en-us',
            'endDateTime': endDateTime,
          },
        );

        debugPrint('EventsService: Fetching Ticketmaster for $location (normalized: ${_normalize(location)})');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['_embedded'] != null &&
              data['_embedded']['events'] != null) {
            final List<dynamic> events = data['_embedded']['events'];

            return events.map((json) {
              return Event.fromTicketmaster(json);
            }).toList();
          }
          return [];
        } else if (response.statusCode == 401 || response.statusCode == 429) {
          throw Exception('${response.statusCode}'); // Retry
        }

        debugPrint(
          'Events API Error: ${response.statusCode} - ${response.body}',
        );
        return [];
      });
    } catch (e) {
      debugPrint('Events Service Error: $e');
      return [];
    }
  }

  String _normalize(String text) {
    final map = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
      'Ç': 'C',
      'Ğ': 'G',
      'İ': 'I',
      'Ö': 'O',
      'Ş': 'S',
      'Ü': 'U',
    };
    var result = text;
    map.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }
}
