import 'package:hive_ce/hive.dart';

part 'user_location.g.dart';

@HiveType(typeId: 8)
class UserLocation {
  @HiveField(0)
  final String cityName;

  @HiveField(1)
  final String country;

  @HiveField(2)
  final String? state;

  @HiveField(3)
  final String? district;

  @HiveField(4)
  final double latitude;

  @HiveField(5)
  final double longitude;

  @HiveField(6)
  final DateTime lastUpdated;

  @HiveField(7)
  final String countryCode; // 'TR' or 'US'

  UserLocation({
    required this.cityName,
    required this.country,
    this.state,
    this.district,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
    this.countryCode = 'TR', // Default to Turkey for backward compatibility
  });
}
