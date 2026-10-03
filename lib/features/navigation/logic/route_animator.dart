import 'package:latlong2/latlong.dart';

import '../../../core/geo/geo_math.dart';

class RouteSample {
  const RouteSample({
    required this.position,
    required this.bearing,
    required this.segmentIndex,
    required this.distance,
  });

  final LatLng position;

  final double bearing;

  final int segmentIndex;

  final double distance;
}

class RouteAnimator {
  RouteAnimator(List<LatLng> rawPoints, {this.minSegmentMeters = 0.5}) {
    final cleaned = <LatLng>[];
    for (final point in rawPoints) {
      if (!point.latitude.isFinite || !point.longitude.isFinite) continue;
      // Drop repeated / near-identical points, zero-length segments would give NaN.
      if (cleaned.isNotEmpty && GeoMath.distanceMeters(cleaned.last, point) < minSegmentMeters) {
        continue;
      }
      cleaned.add(point);
    }

    final cumulative = <double>[0];
    final bearings = <double>[];
    for (var i = 1; i < cleaned.length; i++) {
      cumulative.add(cumulative.last + GeoMath.distanceMeters(cleaned[i - 1], cleaned[i]));
      bearings.add(GeoMath.bearingDegrees(cleaned[i - 1], cleaned[i]));
    }

    points = List.unmodifiable(cleaned);
    _cumulative = cumulative;
    _bearings = bearings;
  }

  final double minSegmentMeters;
  late final List<LatLng> points;
  late final List<double> _cumulative;
  late final List<double> _bearings;

  double get totalMeters => _cumulative.last;

  bool get isValid => points.length >= 2 && totalMeters > 0;

  RouteSample sampleAt(double distance) {
    if (!isValid) {
      return RouteSample(
        position: points.isEmpty ? const LatLng(0, 0) : points.first,
        bearing: 0,
        segmentIndex: 0,
        distance: 0,
      );
    }

    final d = distance.isFinite ? distance.clamp(0.0, totalMeters) : 0.0;
    final i = _segmentIndexFor(d);
    final segmentLength = _cumulative[i + 1] - _cumulative[i];
    final t = segmentLength > 0 ? ((d - _cumulative[i]) / segmentLength).clamp(0.0, 1.0) : 0.0;

    return RouteSample(
      position: GeoMath.lerp(points[i], points[i + 1], t),
      bearing: _bearings[i],
      segmentIndex: i,
      distance: d,
    );
  }

  List<LatLng> travelledPoints(RouteSample sample) =>
      [...points.sublist(0, sample.segmentIndex + 1), sample.position];

  int _segmentIndexFor(double d) {
    var low = 0;
    var high = _cumulative.length - 2;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (_cumulative[mid] <= d) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }
}
