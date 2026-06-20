/// Represents a city or geographic location for weather queries.
class City {
  final String name;
  final double latitude;
  final double longitude;
  final String? country;
  final String? adminArea; // State / province / region

  const City({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country,
    this.adminArea,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
        name: json['name'] as String? ?? '',
        latitude: (json['lat'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['lon'] as num?)?.toDouble() ?? 0.0,
        country: json['country'] as String?,
        adminArea: json['admin_area'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'lat': latitude,
        'lon': longitude,
        'country': country,
        'admin_area': adminArea,
      };

  @override
  String toString() => 'City($name, $latitude, $longitude)';
}
