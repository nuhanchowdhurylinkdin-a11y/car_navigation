import 'package:latlong2/latlong.dart';

import '../utils/polyline_decoder.dart';
import 'osrm_model.dart';

class RoutePath {
  const RoutePath({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  factory RoutePath.fromOsrm(OsrmRoute route) => RoutePath(
        points: PolylineDecoder.decode(route.geometry),
        distanceMeters: route.distance,
        durationSeconds: route.duration,
      );

  String get distanceLabel => distanceMeters < 1000
      ? '${distanceMeters.round()} m'
      : '${(distanceMeters / 1000).toStringAsFixed(1)} km';

  String get durationLabel {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 1) return '< 1 min';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }
}
