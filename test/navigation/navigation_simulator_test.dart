import 'package:car_navigation/features/navigation/logic/navigation_simulator.dart';
import 'package:car_navigation/features/navigation/logic/route_animator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

const frame = Duration(milliseconds: 16);

void main() {
  late NavigationSimulator sim;

  setUp(() {
    final animator = RouteAnimator(const [LatLng(23.8, 90.40), LatLng(23.8, 90.41), LatLng(23.81, 90.41)]);
    sim = NavigationSimulator(animator, baseSpeedMps: 10);
  });

  void run(Duration total, {Duration step = frame}) {
    var elapsed = Duration.zero;
    while (elapsed < total) {
      sim.tick(step);
      elapsed += step;
    }
  }

  test('does not move until started', () {
    run(const Duration(seconds: 1));
    expect(sim.travelledMeters, 0);
    expect(sim.state, NavigationState.idle);
  });

  test('moves at base speed × multiplier, independent of frame rate', () {
    sim.start();
    run(const Duration(seconds: 2));
    expect(sim.travelledMeters, closeTo(20, 0.5));

    sim.setMultiplier(5);
    run(const Duration(seconds: 1), step: const Duration(milliseconds: 25));
    expect(sim.travelledMeters, closeTo(70, 1));
  });

  test('pause freezes the car and resume continues from the same place', () {
    sim.start();
    run(const Duration(seconds: 1));
    final before = sim.travelledMeters;

    sim.pause();
    run(const Duration(seconds: 5));
    expect(sim.travelledMeters, before);
    expect(sim.state, NavigationState.paused);

    sim.resume();
    run(const Duration(seconds: 1));
    expect(sim.travelledMeters, closeTo(before + 10, 0.5));
  });

  test('a long frame (e.g. back from background) is clamped, so the car never jumps', () {
    sim.start();
    sim.tick(const Duration(seconds: 30));
    expect(sim.travelledMeters, closeTo(1, 1e-6));
  });

  test('finishes exactly at the end and stays there', () {
    sim.start();
    sim.setMultiplier(5);
    run(const Duration(minutes: 5), step: const Duration(milliseconds: 100));

    expect(sim.state, NavigationState.finished);
    expect(sim.travelledMeters, sim.totalMeters);
    expect(sim.remainingMeters, 0);
    expect(sim.remainingSeconds, 0);
  });

  test('reset returns to the start and start() after finishing drives again', () {
    sim.start();
    run(const Duration(seconds: 3));
    sim.reset();
    expect(sim.state, NavigationState.idle);
    expect(sim.travelledMeters, 0);

    sim.setMultiplier(5);
    sim.start();
    run(const Duration(minutes: 5), step: const Duration(milliseconds: 100));
    sim.start();
    expect(sim.state, NavigationState.running);
    expect(sim.travelledMeters, 0);
  });

  test('heading turns the short way and stays finite through the corner', () {
    sim.start();
    sim.setMultiplier(5);
    final headings = <double>[];
    while (sim.state == NavigationState.running) {
      sim.tick(frame);
      headings.add(sim.bearing);
    }

    expect(headings.every((h) => h.isFinite && h >= 0 && h < 360), isTrue);
    expect(headings.first, closeTo(90, 1));
    expect(headings.last, closeTo(0, 5));
    for (var i = 1; i < headings.length; i++) {
      final step = (headings[i] - headings[i - 1]).abs();
      expect(step < 20 || step > 340, isTrue, reason: 'no sudden spin at frame $i');
    }
  });

  test('invalid route cannot start', () {
    final empty = NavigationSimulator(RouteAnimator(const []), baseSpeedMps: 10)..start();
    expect(empty.state, NavigationState.idle);
  });
}
