import 'package:car_navigation/core/geo/geo_math.dart';
import 'package:car_navigation/features/navigation/logic/route_animator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void expectFinite(RouteSample sample) {
  expect(sample.position.latitude.isFinite, isTrue);
  expect(sample.position.longitude.isFinite, isTrue);
  expect(sample.bearing.isFinite, isTrue);
}

void main() {
  const a = LatLng(23.8000, 90.4000);
  const b = LatLng(23.8000, 90.4100);
  const c = LatLng(23.8100, 90.4100);

  test('total length is the sum of the segments', () {
    final animator = RouteAnimator([a, b, c]);
    final expected = GeoMath.distanceMeters(a, b) + GeoMath.distanceMeters(b, c);
    expect(animator.totalMeters, closeTo(expected, 1e-6));
  });

  test('halfway along a segment lands on its midpoint and faces along it', () {
    final animator = RouteAnimator([a, b]);
    final sample = animator.sampleAt(animator.totalMeters / 2);

    expect(sample.position.latitude, closeTo(23.8, 1e-9));
    expect(sample.position.longitude, closeTo(90.405, 1e-6));
    expect(sample.bearing, closeTo(90, 0.01));
  });

  test('repeated and nearly identical points are dropped and never produce NaN', () {
    const nearlyB = LatLng(23.8000001, 90.4100001);
    final animator = RouteAnimator([a, a, a, b, b, nearlyB, c, c]);

    expect(animator.points, [a, b, c]);
    for (var d = -10.0; d <= animator.totalMeters + 10; d += 7.3) {
      expectFinite(animator.sampleAt(d));
    }
  });

  test('distance outside the route is clamped to its ends', () {
    final animator = RouteAnimator([a, b, c]);
    expect(animator.sampleAt(-50).position, a);
    expect(animator.sampleAt(animator.totalMeters + 50).position, c);
    expectFinite(animator.sampleAt(double.nan));
  });

  test('empty, single-point and all-duplicate routes are invalid but safe', () {
    for (final points in [<LatLng>[], [a], [a, a, a]]) {
      final animator = RouteAnimator(points);
      expect(animator.isValid, isFalse);
      expectFinite(animator.sampleAt(100));
    }
  });

  test('equal distance steps move equally far on dense and sparse parts', () {
    final dense = [for (var i = 0; i <= 100; i++) LatLng(23.8, 90.40 + i * 0.0001)];
    final route = [...dense, const LatLng(23.8, 90.42)];
    final animator = RouteAnimator(route);

    final denseStep = GeoMath.distanceMeters(
      animator.sampleAt(100).position,
      animator.sampleAt(150).position,
    );
    final sparseStep = GeoMath.distanceMeters(
      animator.sampleAt(1500).position,
      animator.sampleAt(1550).position,
    );
    expect(denseStep, closeTo(50, 0.5));
    expect(sparseStep, closeTo(50, 0.5));
  });

  test('travelled points end exactly at the car', () {
    final animator = RouteAnimator([a, b, c]);
    final sample = animator.sampleAt(animator.totalMeters * 0.75);
    final travelled = animator.travelledPoints(sample);

    expect(travelled.first, a);
    expect(travelled.last, sample.position);
    expect(travelled, contains(b));
  });
}
