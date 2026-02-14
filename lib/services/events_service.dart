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
        // Ticketmaster searches by city name directly
        final url = Uri.parse(_baseUrl).replace(
          queryParameters: {
            'apikey': apiKey,
            'city': location,
            'sort': 'date,asc',
            'size': '10',
            // 'locale': lang
          },
        );

        debugPrint('EventsService: Fetching Ticketmaster for $location');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['_embedded'] != null &&
              data['_embedded']['events'] != null) {
            final List<dynamic> events = data['_embedded']['events'];

            return events.map((json) {
              // Map Ticketmaster JSON to our Event model
              final String title = json['name'] ?? 'Etkinlik';
              final String date = json['dates']['start']['localDate'] ?? '';
              var venue = 'Adres yok';

              if (json['_embedded'] != null &&
                  json['_embedded']['venues'] != null) {
                venue = json['_embedded']['venues'][0]['name'] ?? '';
              }

              var imageUrl = '';
              if (json['images'] != null &&
                  (json['images'] as List).isNotEmpty) {
                imageUrl = json['images'][0]['url'];
              }

              // Description is often in 'info' or missing
              final String description =
                  json['info'] ?? (json['pleaseNote'] ?? '');

              return Event(
                title: title,
                date: date,
                location: venue,
                description: description,
                imageUrl: imageUrl,
                link: json['url'] ?? '',
              );
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
}
