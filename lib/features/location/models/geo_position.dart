import 'package:latlong2/latlong.dart';

/// A single location fix received from the native layer.
class GeoPosition {
  const GeoPosition({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.bearing,
    required this.speed,
    required this.timestamp,
    required this.isPrecise,
  });

  final double latitude;
  final double longitude;

  /// Horizontal accuracy radius in metres.
  final double accuracy;

  /// Direction of travel in degrees (0 = north), 0 when unknown.
  final double bearing;

  /// Speed in metres per second, 0 when unknown.
  final double speed;
  final DateTime timestamp;

  /// False when the user granted only approximate location.
  final bool isPrecise;

  LatLng get latLng => LatLng(latitude, longitude);

  factory GeoPosition.fromMap(Map<dynamic, dynamic> map) => GeoPosition(
        latitude: (map['lat'] as num).toDouble(),
        longitude: (map['lng'] as num).toDouble(),
        accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0,
        bearing: (map['bearing'] as num?)?.toDouble() ?? 0,
        speed: (map['speed'] as num?)?.toDouble() ?? 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          (map['timestamp'] as num?)?.toInt() ?? 0,
        ),
        isPrecise: map['isPrecise'] as bool? ?? true,
      );

  @override
  String toString() =>
      'GeoPosition($latitude, $longitude, ±${accuracy.toStringAsFixed(0)}m)';
}
