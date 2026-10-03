import 'package:car_navigation/core/geo/geo_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('distanceMeters', () {
    test('one degree of latitude is about 111 km', () {
      expect(GeoMath.distanceMeters(const LatLng(0, 0), const LatLng(1, 0)), closeTo(111195, 50));
    });

    test('same point is zero', () {
      expect(GeoMath.distanceMeters(const LatLng(23.8, 90.4), const LatLng(23.8, 90.4)), 0);
    });
  });

  group('bearingDegrees', () {
    test('compass directions', () {
      const origin = LatLng(0, 0);
      expect(GeoMath.bearingDegrees(origin, const LatLng(1, 0)), closeTo(0, 1e-9));
      expect(GeoMath.bearingDegrees(origin, const LatLng(0, 1)), closeTo(90, 1e-9));
      expect(GeoMath.bearingDegrees(origin, const LatLng(-1, 0)), closeTo(180, 1e-9));
      expect(GeoMath.bearingDegrees(origin, const LatLng(0, -1)), closeTo(270, 1e-9));
    });
  });

  group('shortestAngleDelta', () {
    test('wraps through north instead of spinning the long way', () {
      expect(GeoMath.shortestAngleDelta(359, 1), closeTo(2, 1e-9));
      expect(GeoMath.shortestAngleDelta(1, 359), closeTo(-2, 1e-9));
      expect(GeoMath.shortestAngleDelta(350, 10), closeTo(20, 1e-9));
    });

    test('ordinary turns and the 180° tie', () {
      expect(GeoMath.shortestAngleDelta(90, 45), closeTo(-45, 1e-9));
      expect(GeoMath.shortestAngleDelta(0, 180), 180);
    });
  });

  test('normalizeDegrees keeps values in [0, 360)', () {
    expect(GeoMath.normalizeDegrees(-90), 270);
    expect(GeoMath.normalizeDegrees(720), 0);
  });
}
