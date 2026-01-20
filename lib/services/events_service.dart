import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import '../config/api_config.dart';

class EventsService {
  // Ticketmaster Discovery API
  // Free Tier: 5000 requests/day
  // Key Required: User must get this from developer.ticketmaster.com
  static const String _baseUrl = 'https://app.ticketmaster.com/discovery/v2/events.json';
  // Key provided by user
  static const String _apiKey = ApiConfig.eventApiKey;

  Future<List<Event>> getNearbyEvents(String location, {int days = 7, String lang = 'tr'}) async {
    if (_apiKey.isEmpty) {
      print('EventsService: API KEY MISSING. Please get a free key from developer.ticketmaster.com');
      return [];
    }

    try {
      // Ticketmaster searches by city name directly
      final url = Uri.parse(_baseUrl).replace(queryParameters: {
        'apikey': _apiKey,
        'city': location,
        'sort': 'date,asc',
        'size': '10',
        // 'locale': lang // Ticketmaster locale format is different (e.g., en-us), avoiding for now
      });

      print('EventsService: Fetching Ticketmaster for $location');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['_embedded'] != null && data['_embedded']['events'] != null) {
          final List<dynamic> events = data['_embedded']['events'];
          
          return events.map((json) {
            // Map Ticketmaster JSON to our Event model
            String title = json['name'] ?? 'Etkinlik';
            String date = json['dates']['start']['localDate'] ?? '';
            String venue = 'Adres yok';
            
            if (json['_embedded'] != null && json['_embedded']['venues'] != null) {
               venue = json['_embedded']['venues'][0]['name'] ?? '';
            }
            
            String imageUrl = '';
            if (json['images'] != null && (json['images'] as List).isNotEmpty) {
               imageUrl = json['images'][0]['url'];
            }

            // Description is often in 'info' or missing
            String description = json['info'] ?? (json['pleaseNote'] ?? '');

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
      } 
      
      print('Events API Error: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      print('Events Service Error: $e');
      return [];
    }
  }
}
