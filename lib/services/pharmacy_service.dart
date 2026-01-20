import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pharmacy.dart';
import '../config/api_config.dart';

class PharmacyService {
  // CollectAPI Health Service
  // Free Tier: 100 requests/month
  // URL: https://collectapi.com/tr/api/health/nobetci-eczane-api
  static const String _baseUrl = 'https://api.collectapi.com/health/dutyPharmacy';

  Future<List<Pharmacy>> getDutyPharmacies(String city, String district) async {
    if (city.isEmpty || district.isEmpty) return [];

    final keys = ApiConfig.pharmacyApiKeys;
    if (keys.isEmpty) {
      print('PharmacyService: No API keys defined in ApiConfig.');
      return [];
    }

    // Try each key until success
    for (int i = 0; i < keys.length; i++) {
      final apiKey = keys[i];
      
      try {
        final result = await _fetchWithKey(apiKey, city, district);
        if (result != null) {
           return result; // Success!
        }
        // If result is null, it failed (likely auth/limit), so continue to next key
        print('PharmacyService: Key index $i failed. Trying next key...');
      } catch (e) {
        print('PharmacyService Exception with key $i: $e');
        // Continue to next key on exception
      }
    }

    print('PharmacyService: All keys exhausted or failed.');
    return [];
  }

  Future<List<Pharmacy>?> _fetchWithKey(String apiKey, String city, String district) async {
     try {
      // CollectAPI expects query params: il, ilce
      final url = Uri.parse('$_baseUrl?il=${_normalize(city)}&ilce=${_normalize(district)}');
      
      print('PharmacyService: Fetching $url with key ending in ...${apiKey.substring(apiKey.length - 5)}');
      final response = await http.get(
        url,
        headers: {
          'authorization': apiKey,
          'content-type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['result'] != null) {
           final List<dynamic> results = data['result'];
           return results.map((json) {
             // CollectAPI returns: name, dist, address, phone, loc (lat, lng)
             String loc = json['loc'] ?? '';
             double lat = 0.0;
             double lng = 0.0;
             if (loc.isNotEmpty) {
               final parts = loc.split(',');
               if (parts.length == 2) {
                 lat = double.tryParse(parts[0]) ?? 0.0;
                 lng = double.tryParse(parts[1]) ?? 0.0;
               }
             }

             return Pharmacy(
               name: json['name'] ?? '',
               address: json['address'] ?? '',
               phone: json['phone'] ?? '',
               latitude: lat,
               longitude: lng,
               district: district,
             );
           }).toList();
        } else {
           // API returned 200 but success: false (check message)
           print('Pharmacy API Logical Error: ${data['message']}');
           return null; // Treat as failure to try next key (maybe?)
        }
      } else {
        // 401 Unauthorized, 429 Too Many Requests, etc.
        print('Pharmacy API Error: ${response.statusCode} - ${response.body}');
        return null; // Return null to trigger fallback
      }
    } catch (e) {
      print('Pharmacy Service Inner Exception: $e');
      return null;
    }
  }
  
  String _normalize(String text) {
    var map = {
      'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
      'Ç': 'c', 'Ğ': 'g', 'İ': 'i', 'Ö': 'o', 'Ş': 's', 'Ü': 'u'
    };
    String result = text.toLowerCase();
    map.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }
}
