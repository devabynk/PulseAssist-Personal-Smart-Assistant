import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../core/utils/key_manager.dart';
import '../models/pharmacy.dart';

class PharmacyService {
  final KeyManager _keyManager = KeyManager(
    ApiConfig.pharmacyApiKeys,
    serviceName: 'Pharmacy',
  );
  static const String _baseUrl =
      'https://api.collectapi.com/health/dutyPharmacy';

  Future<List<Pharmacy>> getDutyPharmacies(String city, String district) async {
    if (city.isEmpty || district.isEmpty) return [];

    try {
      return await _keyManager.executeWithRetry((apiKey) async {
        // CollectAPI expects query params: il, ilce
        final url = Uri.parse(
          '$_baseUrl?il=${_normalize(city)}&ilce=${_normalize(district)}',
        );

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
              final String loc = json['loc'] ?? '';
              var lat = 0.0;
              var lng = 0.0;
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
            // API returned 200 but success: false
            // Usually logical error (invalid city), NOT auth error.
            // So we return empty list and do NOT throw to retry (unless we want to retry on logic error?)
            // Actually, if it's "invalid authorization" it might come as 401.
            // If success: false, it might be city mismatch.
            return <Pharmacy>[];
          }
        } else if (response.statusCode == 401 || response.statusCode == 429) {
          throw Exception('${response.statusCode}'); // Refund/Retry
        } else {
          throw Exception('Service Error');
        }
      });
    } catch (e) {
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
      'Ç': 'c',
      'Ğ': 'g',
      'İ': 'i',
      'Ö': 'o',
      'Ş': 's',
      'Ü': 'u',
    };
    var result = text.toLowerCase();
    map.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }
}
