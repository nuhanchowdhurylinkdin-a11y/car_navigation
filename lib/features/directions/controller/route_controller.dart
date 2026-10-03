import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../location/controller/location_controller.dart';
import '../../location/models/geo_position.dart';
import '../model/route_exception.dart';
import '../model/route_path.dart';
import '../service/osrm_api_service.dart';

enum RouteStatus { idle, loading, success, noLocation, error }

class RouteController extends GetxController {
  RouteController(
    this._api,
    this._location, {
    this.debounceTime = const Duration(milliseconds: 600),
    this.minRequestGap = const Duration(seconds: 1),
    this.slowAfter = const Duration(seconds: 3),
  });

  final OsrmApiService _api;
  final LocationController _location;
  final Duration debounceTime;
  final Duration minRequestGap;
  final Duration slowAfter;

  final destination = Rxn<LatLng>();
  final manualMode = false.obs;
  final manualStart = Rxn<LatLng>();
  final path = Rxn<RoutePath>();
  final status = RouteStatus.idle.obs;
  final error = Rxn<RouteException>();
  final isSlow = false.obs;

  Worker? _destinationWorker;
  Worker? _locationWorker;
  Timer? _slowTimer;
  int _requestId = 0;
  DateTime? _lastRequestAt;

  @override
  void onInit() {
    super.onInit();
    _destinationWorker = debounce<LatLng?>(
      destination,
      (_) => fetchRoute(),
      time: debounceTime,
    );
    _locationWorker = ever<GeoPosition?>(_location.position, (fix) {
      if (fix != null && !manualMode.value && status.value == RouteStatus.noLocation) {
        fetchRoute();
      }
    });
  }

  @override
  void onClose() {
    _destinationWorker?.dispose();
    _locationWorker?.dispose();
    _slowTimer?.cancel();
    _api.dispose();
    super.onClose();
  }

  LatLng? get startPoint =>
      manualMode.value ? manualStart.value : _location.position.value?.latLng;

  bool get needsManualStart => manualMode.value && manualStart.value == null;

  void onMapLongPress(LatLng point) {
    if (needsManualStart) {
      setManualStart(point);
    } else {
      setDestination(point);
    }
  }

  void setDestination(LatLng point) {
    HapticFeedback.mediumImpact();
    _requestId++;
    destination.value = point;
    path.value = null;
    error.value = null;
    status.value = startPoint != null ? RouteStatus.loading : RouteStatus.noLocation;
  }

  void enterManualMode() {
    _resetRoute();
    manualMode.value = true;
    manualStart.value = null;
    destination.value = null;
  }

  void setManualStart(LatLng point) {
    HapticFeedback.mediumImpact();
    _resetRoute();
    manualStart.value = point;
    if (destination.value != null) fetchRoute();
  }

  void changeManualStart() {
    _resetRoute();
    manualStart.value = null;
  }

  void exitManualMode() {
    _resetRoute();
    manualMode.value = false;
    manualStart.value = null;
    destination.value = null;
  }

  void clearDestination() {
    _resetRoute();
    destination.value = null;
  }

  Future<void> retry() => fetchRoute();

  Future<void> fetchRoute() async {
    final end = destination.value;
    if (end == null || isClosed) return;

    final start = startPoint;
    if (start == null) {
      status.value = manualMode.value ? RouteStatus.idle : RouteStatus.noLocation;
      return;
    }

    final requestId = ++_requestId;
    status.value = RouteStatus.loading;
    error.value = null;

    final last = _lastRequestAt;
    if (last != null) {
      final wait = minRequestGap - DateTime.now().difference(last);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    if (!_isCurrent(requestId)) return;
    _lastRequestAt = DateTime.now();

    _stopSlowTimer();
    _slowTimer = Timer(slowAfter, () {
      if (_isCurrent(requestId)) isSlow.value = true;
    });

    try {
      final model = await _api.fetchRoute(start: start, end: end);
      if (!_isCurrent(requestId)) return;
      final result = RoutePath.fromOsrm(model.routes.first);
      if (result.points.length < 2) throw const NoRouteException();
      path.value = result;
      status.value = RouteStatus.success;
    } on RouteException catch (e) {
      if (!_isCurrent(requestId)) return;
      error.value = e;
      status.value = RouteStatus.error;
    } finally {
      if (_isCurrent(requestId)) _stopSlowTimer();
    }
  }

  void _resetRoute() {
    _requestId++;
    _stopSlowTimer();
    path.value = null;
    error.value = null;
    status.value = RouteStatus.idle;
  }

  bool _isCurrent(int requestId) => requestId == _requestId && !isClosed;

  void _stopSlowTimer() {
    _slowTimer?.cancel();
    _slowTimer = null;
    if (!isClosed) isSlow.value = false;
  }
}
