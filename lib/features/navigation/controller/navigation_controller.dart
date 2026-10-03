import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../directions/controller/route_controller.dart';
import '../../directions/model/route_path.dart';
import '../logic/navigation_simulator.dart';
import '../logic/route_animator.dart';

class NavigationController extends GetxController {
  NavigationController(this._route);

  static const double fallbackSpeedMps = 13.9;

  final RouteController _route;

  final state = NavigationState.idle.obs;
  final carPosition = Rxn<LatLng>();
  final carBearing = 0.0.obs;
  final travelledPoints = Rx<List<LatLng>>(const []);
  final remainingMeters = 0.0.obs;
  final remainingSeconds = 0.0.obs;
  final totalMeters = 0.0.obs;
  final progress = 0.0.obs;
  final multiplier = 1.obs;

  NavigationSimulator? _simulator;
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  Worker? _pathWorker;
  AppLifecycleListener? _lifecycle;

  bool get isActive => state.value != NavigationState.idle;
  bool get canStart => _simulator?.animator.isValid ?? false;

  @override
  void onInit() {
    super.onInit();
    _ticker = Ticker(_onTick);
    _pathWorker = ever<RoutePath?>(_route.path, _load);
    _lifecycle = AppLifecycleListener(onHide: pause);
    _load(_route.path.value);
  }

  @override
  void onClose() {
    _pathWorker?.dispose();
    _lifecycle?.dispose();
    _ticker?.dispose();
    _ticker = null;
    super.onClose();
  }

  void start() {
    final simulator = _simulator;
    if (simulator == null) return;
    simulator.start();
    _startTicker();
    _publish();
  }

  void pause() {
    final simulator = _simulator;
    if (simulator == null || simulator.state != NavigationState.running) return;
    simulator.pause();
    _stopTicker();
    _publish();
  }

  void resume() {
    final simulator = _simulator;
    if (simulator == null || simulator.state != NavigationState.paused) return;
    simulator.resume();
    _startTicker();
    _publish();
  }

  void togglePause() => state.value == NavigationState.running ? pause() : resume();

  void reset() {
    _simulator?.reset();
    _stopTicker();
    _publish();
  }

  void restart() {
    reset();
    start();
  }

  void setMultiplier(int value) {
    _simulator?.setMultiplier(value);
    multiplier.value = _simulator?.multiplier ?? value;
  }

  void _load(RoutePath? path) {
    _stopTicker();
    if (path == null) {
      _simulator = null;
    } else {
      _simulator = NavigationSimulator(
        RouteAnimator(path.points),
        baseSpeedMps: _speedFor(path),
      )..setMultiplier(multiplier.value);
    }
    _publish();
  }

  double _speedFor(RoutePath path) {
    final speed = path.distanceMeters / path.durationSeconds;
    return speed.isFinite && speed > 0 ? speed.clamp(1.0, 60.0) : fallbackSpeedMps;
  }

  void _startTicker() {
    final ticker = _ticker;
    if (ticker == null || ticker.isActive) return;
    _lastElapsed = Duration.zero;
    ticker.start();
  }

  void _stopTicker() {
    final ticker = _ticker;
    if (ticker != null && ticker.isActive) ticker.stop();
  }

  void _onTick(Duration elapsed) {
    final simulator = _simulator;
    if (simulator == null || isClosed) return;
    final dt = elapsed - _lastElapsed;
    _lastElapsed = elapsed;
    simulator.tick(dt);
    if (simulator.state != NavigationState.running) _stopTicker();
    _publish();
  }

  void _publish() {
    if (isClosed) return;
    final simulator = _simulator;
    if (simulator == null) {
      state.value = NavigationState.idle;
      carPosition.value = null;
      travelledPoints.value = const [];
      remainingMeters.value = 0;
      remainingSeconds.value = 0;
      totalMeters.value = 0;
      progress.value = 0;
      return;
    }
    final sample = simulator.sample;
    state.value = simulator.state;
    carPosition.value = sample.position;
    carBearing.value = simulator.bearing;
    travelledPoints.value =
        simulator.travelledMeters > 0 ? simulator.animator.travelledPoints(sample) : const [];
    remainingMeters.value = simulator.remainingMeters;
    remainingSeconds.value = simulator.remainingSeconds;
    totalMeters.value = simulator.totalMeters;
    progress.value = simulator.progress;
  }
}
