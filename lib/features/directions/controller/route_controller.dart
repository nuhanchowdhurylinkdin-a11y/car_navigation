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
      if (fix != null && status.value == RouteStatus.noLocation) fetchRoute();
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

  void setDestination(LatLng point) {
    HapticFeedback.mediumImpact();
    _requestId++;
    destination.value = point;
    path.value = null;
    error.value = null;
    status.value = _location.hasLocation ? RouteStatus.loading : RouteStatus.noLocation;
  }

  void clearDestination() {
    _requestId++;
    _stopSlowTimer();
    destination.value = null;
    path.value = null;
    error.value = null;
    status.value = RouteStatus.idle;
  }

  Future<void> retry() => fetchRoute();

  Future<void> fetchRoute() async {
    final end = destination.value;
    if (end == null || isClosed) return;

    final start = _location.position.value?.latLng;
    if (start == null) {
      status.value = RouteStatus.noLocation;
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

  bool _isCurrent(int requestId) => requestId == _requestId && !isClosed;

  void _stopSlowTimer() {
    _slowTimer?.cancel();
    _slowTimer = null;
    if (!isClosed) isSlow.value = false;
  }
}
