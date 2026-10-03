import 'package:latlong2/latlong.dart';

import '../utils/polyline_decoder.dart';
import '../utils/route_format.dart';
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

  String get distanceLabel => RouteFormat.distance(distanceMeters);

  String get durationLabel => RouteFormat.duration(durationSeconds);
}
