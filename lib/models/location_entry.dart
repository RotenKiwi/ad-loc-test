import 'dart:convert';

class LocationEntry {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final String source;

  const LocationEntry({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    required this.timestamp,
    this.source = 'foreground',
  });

  factory LocationEntry.fromJson(Map<String, dynamic> json) {
    return LocationEntry(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: json['accuracy'] != null
          ? (json['accuracy'] as num).toDouble()
          : null,
      altitude: json['altitude'] != null
          ? (json['altitude'] as num).toDouble()
          : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      heading:
          json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: json['source'] as String? ?? 'foreground',
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'timestamp': timestamp.toIso8601String(),
        'source': source,
      };

  static String encodeList(List<LocationEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  static List<LocationEntry> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => LocationEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  String toString() => 'LocationEntry(lat: $latitude, lng: $longitude, '
      'src: $source, ts: $timestamp)';
}
