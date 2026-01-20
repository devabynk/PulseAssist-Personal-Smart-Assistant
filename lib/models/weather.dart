class Weather {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String icon;
  final String cityName;
  final String country;
  final DateTime lastUpdated;
  
  // New fields from OpenWeatherMap
  final int pressure;
  final double uvIndex;
  final int cloudiness;
  final int visibility;
  final double lat;
  final double lon;

  Weather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
    required this.cityName,
    required this.country,
    required this.lastUpdated,
    this.pressure = 0,
    this.uvIndex = 0,
    this.cloudiness = 0,
    this.visibility = 0,
    this.lat = 0,
    this.lon = 0,
  });

  /// Create Weather from OpenWeatherMap response (Supports both OneCall 3.0 and Standard 2.5)
  factory Weather.fromOpenWeatherMap(
    Map<String, dynamic> json, {
    required String locationName,
    required String country,
  }) {
    // Check if it's OneCall API (has 'current' field)
    if (json.containsKey('current')) {
      final current = json['current'];
      return Weather(
        temperature: (current['temp'] as num).toDouble(),
        feelsLike: (current['feels_like'] as num).toDouble(),
        humidity: current['humidity'] as int,
        windSpeed: (current['wind_speed'] as num).toDouble(),
        description: current['weather'][0]['description'] as String,
        icon: 'https://openweathermap.org/img/wn/${current['weather'][0]['icon']}@2x.png',
        cityName: locationName,
        country: country,
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(current['dt'] * 1000),
        pressure: current['pressure'] as int,
        uvIndex: (current['uvi'] as num?)?.toDouble() ?? 0,
        cloudiness: current['clouds'] as int,
        visibility: current['visibility'] as int,
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
      );
    } 
    // Otherwise assume Standard 2.5 API (Current Weather)
    else {
      final main = json['main'];
      final weather = json['weather'][0];
      final wind = json['wind'];
      final sys = json['sys'];
      final coord = json['coord'];
      
      return Weather(
        temperature: (main['temp'] as num).toDouble(),
        feelsLike: (main['feels_like'] as num).toDouble(),
        humidity: main['humidity'] as int,
        windSpeed: (wind['speed'] as num).toDouble(),
        description: weather['description'] as String,
        icon: 'https://openweathermap.org/img/wn/${weather['icon']}@2x.png',
        cityName: locationName, // Use provided name as API name might be English only
        country: country,
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
        pressure: main['pressure'] as int,
        uvIndex: 0, // Not available in standard weather API
        cloudiness: (json['clouds'] != null) ? (json['clouds']['all'] as int) : 0,
        visibility: (json['visibility'] as num?)?.toInt() ?? 10000,
        lat: (coord != null) ? (coord['lat'] as num).toDouble() : 0,
        lon: (coord != null) ? (coord['lon'] as num).toDouble() : 0,
      );
    }
  }

  /// Legacy fromJson for backward compatibility (WeatherAPI format)
  factory Weather.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final current = json['current'];
    
    return Weather(
      temperature: (current['temp_c'] as num).toDouble(),
      feelsLike: (current['feelslike_c'] as num).toDouble(),
      humidity: current['humidity'] as int,
      windSpeed: (current['wind_kph'] as num).toDouble(),
      description: current['condition']['text'] as String,
      icon: current['condition']['icon'] as String,
      cityName: location['name'] as String,
      country: location['country'] as String,
      lastUpdated: DateTime.parse(current['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'description': description,
      'icon': icon,
      'cityName': cityName,
      'country': country,
      'lastUpdated': lastUpdated.toIso8601String(),
      'pressure': pressure,
      'uvIndex': uvIndex,
      'cloudiness': cloudiness,
      'visibility': visibility,
      'lat': lat,
      'lon': lon,
    };
  }

  factory Weather.fromCache(Map<String, dynamic> json) {
    return Weather(
      temperature: (json['temperature'] as num).toDouble(),
      feelsLike: (json['feelsLike'] as num).toDouble(),
      humidity: json['humidity'] as int,
      windSpeed: (json['windSpeed'] as num).toDouble(),
      description: json['description'] as String,
      icon: json['icon'] as String,
      cityName: json['cityName'] as String,
      country: json['country'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      pressure: (json['pressure'] as num?)?.toInt() ?? 0,
      uvIndex: (json['uvIndex'] as num?)?.toDouble() ?? 0,
      cloudiness: (json['cloudiness'] as num?)?.toInt() ?? 0,
      visibility: (json['visibility'] as num?)?.toInt() ?? 0,
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0,
    );
  }
  
  /// Format weather data for AI consumption
  String toAiContext({bool isTurkish = false}) {
    if (isTurkish) {
      return '''
Güncel Hava Durumu Bilgisi:
- Konum: $cityName, $country
- Sıcaklık: ${temperature.toStringAsFixed(1)}°C (Hissedilen: ${feelsLike.toStringAsFixed(1)}°C)
- Durum: $description
- Nem: $humidity%
- Rüzgar: ${windSpeed.toStringAsFixed(1)} km/s
- Basınç: $pressure hPa
- UV İndeksi: ${uvIndex.toStringAsFixed(1)}
- Bulutluluk: $cloudiness%
- Görüş Mesafesi: ${(visibility / 1000).toStringAsFixed(1)} km
''';
    } else {
      return '''
Current Weather Information:
- Location: $cityName, $country
- Temperature: ${temperature.toStringAsFixed(1)}°C (Feels like: ${feelsLike.toStringAsFixed(1)}°C)
- Conditions: $description
- Humidity: $humidity%
- Wind: ${windSpeed.toStringAsFixed(1)} km/h
- Pressure: $pressure hPa
- UV Index: ${uvIndex.toStringAsFixed(1)}
- Cloudiness: $cloudiness%
- Visibility: ${(visibility / 1000).toStringAsFixed(1)} km
''';
    }
  }
}
