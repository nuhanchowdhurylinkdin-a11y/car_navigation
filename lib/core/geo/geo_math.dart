import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

class GeoMath {
  GeoMath._();

  static const double earthRadiusMeters = 6371008.8;

  /// Great-circle distance between two points (haversine).
  static double distanceMeters(LatLng a, LatLng b) {
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final dLat = lat2 - lat1;
    final dLng = _rad(b.longitude - a.longitude);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadiusMeters * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
  }

  /// Initial compass bearing from [a] to [b]: 0° = north, 90° = east.
  static double bearingDegrees(LatLng a, LatLng b) {
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return normalizeDegrees(_deg(math.atan2(y, x)));
  }

  /// Signed smallest rotation from [from] to [to], always in (-180°, 180°].
  /// 359° → 1° gives +2°, not -358°.
  static double shortestAngleDelta(double from, double to) {
    final delta = ((to - from + 540) % 360) - 180;
    return delta == -180 ? 180 : delta;
  }

  static double normalizeDegrees(double degrees) {
    final value = degrees % 360;
    return value < 0 ? value + 360 : value;
  }

  static LatLng lerp(LatLng a, LatLng b, double t) => LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );

  static double _rad(double degrees) => degrees * math.pi / 180;

  static double _deg(double radians) => radians * 180 / math.pi;
}
