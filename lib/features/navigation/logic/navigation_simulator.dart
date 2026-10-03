import 'dart:math' as math;

import '../../../core/geo/geo_math.dart';
import 'route_animator.dart';

enum NavigationState { idle, running, paused, finished }

class NavigationSimulator {
  NavigationSimulator(
    this.animator, {
    required this.baseSpeedMps,
    this.maxFrameStep = const Duration(milliseconds: 100),
    this.turnRate = 8,
  }) : assert(baseSpeedMps > 0) {
    _sample = animator.sampleAt(0);
    _bearing = _sample.bearing;
  }

  static const multipliers = [1, 2, 5];

  final RouteAnimator animator;

  final double baseSpeedMps;

  final Duration maxFrameStep;

  final double turnRate;

  NavigationState _state = NavigationState.idle;
  int _multiplier = 1;
  double _travelled = 0;
  double _bearing = 0;
  late RouteSample _sample;

  NavigationState get state => _state;
  int get multiplier => _multiplier;
  double get travelledMeters => _travelled;
  double get totalMeters => animator.totalMeters;
  double get remainingMeters => math.max(0, totalMeters - _travelled);
  double get progress => totalMeters > 0 ? _travelled / totalMeters : 0;

  double get remainingSeconds => remainingMeters / baseSpeedMps;

  RouteSample get sample => _sample;
  double get bearing => _bearing;
  bool get isActive => _state == NavigationState.running || _state == NavigationState.paused;

  void start() {
    if (!animator.isValid) return;
    if (_state == NavigationState.finished) reset();
    _state = NavigationState.running;
  }

  void pause() {
    if (_state == NavigationState.running) _state = NavigationState.paused;
  }

  void resume() {
    if (_state == NavigationState.paused) _state = NavigationState.running;
  }

  void reset() {
    _state = NavigationState.idle;
    _travelled = 0;
    _sample = animator.sampleAt(0);
    _bearing = _sample.bearing;
  }

  void setMultiplier(int value) {
    if (multipliers.contains(value)) _multiplier = value;
  }

  void tick(Duration elapsed) {
    if (_state != NavigationState.running) return;

    // Cap the step so a long frame (or coming back from background) never makes the car jump.
    final step = elapsed > maxFrameStep ? maxFrameStep : elapsed;
    final dt = step.inMicroseconds / Duration.microsecondsPerSecond;
    if (dt <= 0) return;

    _travelled = math.min(totalMeters, _travelled + baseSpeedMps * _multiplier * dt);
    _sample = animator.sampleAt(_travelled);

    final ease = 1 - math.exp(-turnRate * dt);
    _bearing = GeoMath.normalizeDegrees(
      _bearing + GeoMath.shortestAngleDelta(_bearing, _sample.bearing) * ease,
    );

    if (_travelled >= totalMeters) _state = NavigationState.finished;
  }
}
