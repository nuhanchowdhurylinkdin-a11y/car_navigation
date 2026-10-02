import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../models/geo_position.dart';
import '../models/location_exception.dart';
import '../models/location_permission_status.dart';
import '../services/location_service.dart';

enum LocationStatus {
  /// Nothing requested yet; the UI explains why location is needed.
  idle,
  requestingPermission,

  /// Waiting for the first fix.
  locating,
  ready,
  denied,
  deniedForever,
  serviceDisabled,
  timeout,
  unsupported,
  error,
}

class LocationController extends GetxController {
  LocationController(this._service);

  static const fixTimeout = Duration(seconds: 15);

  final LocationService _service;

  final status = LocationStatus.idle.obs;
  final position = Rxn<GeoPosition>();
  final errorMessage = RxnString();

  StreamSubscription<GeoPosition>? _positionSub;
  AppLifecycleListener? _lifecycle;
  bool _busy = false;

  /// Set when we send the user to a Settings page, so we re-check on return.
  bool _awaitingSettings = false;

  bool get hasLocation => position.value != null;

  @override
  void onInit() {
    super.onInit();
    _lifecycle = AppLifecycleListener(
      onHide: _stopTracking,
      onShow: _onAppShown,
    );
  }

  @override
  void onClose() {
    _lifecycle?.dispose();
    _lifecycle = null;
    _stopTracking();
    super.onClose();
  }

  /// Full flow: service check → permission → first fix → live tracking.
  Future<void> useMyLocation() async {
    if (_busy) return;
    _busy = true;
    errorMessage.value = null;
    try {
      if (!await _service.isServiceEnabled()) {
        throw const LocationServiceDisabledException();
      }

      var permission = await _service.checkPermission();
      if (permission != LocationPermissionStatus.granted) {
        _setStatus(LocationStatus.requestingPermission);
        permission = await _service.requestPermission();
      }
      if (permission == LocationPermissionStatus.denied) {
        throw const PermissionDeniedException();
      }
      if (permission == LocationPermissionStatus.deniedForever) {
        throw const PermissionDeniedForeverException();
      }

      _setStatus(LocationStatus.locating);
      final fix = await _service.getCurrentLocation(timeout: fixTimeout);
      if (isClosed) return;
      position.value = fix;
      _setStatus(LocationStatus.ready);
      _startTracking();
    } on LocationException catch (e) {
      _handleError(e);
    } finally {
      _busy = false;
    }
  }

  Future<void> openAppSettings() async {
    _awaitingSettings = true;
    await _safe(_service.openAppSettings);
  }

  Future<void> openLocationSettings() async {
    _awaitingSettings = true;
    await _safe(_service.openLocationSettings);
  }

  void _startTracking() {
    _positionSub?.cancel();
    _positionSub = _service.positionStream().listen(
      (fix) {
        if (isClosed) return;
        position.value = fix;
        if (status.value != LocationStatus.ready) _setStatus(LocationStatus.ready);
      },
      onError: (Object e) {
        _stopTracking();
        if (e is LocationException) _handleError(e);
      },
      cancelOnError: true,
    );
  }

  /// Cancelling the subscription makes the native side remove its location request.
  void _stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  void _onAppShown() {
    if (isClosed) return;
    if (_awaitingSettings) {
      _awaitingSettings = false;
      useMyLocation();
    } else if (status.value == LocationStatus.ready && _positionSub == null) {
      _startTracking();
    }
  }

  void _handleError(LocationException e) {
    if (isClosed) return;
    errorMessage.value = e.message;
    _setStatus(switch (e) {
      PermissionDeniedException() => LocationStatus.denied,
      PermissionDeniedForeverException() => LocationStatus.deniedForever,
      LocationServiceDisabledException() => LocationStatus.serviceDisabled,
      LocationTimeoutException() => LocationStatus.timeout,
      LocationUnsupportedException() => LocationStatus.unsupported,
      LocationUnknownException() => LocationStatus.error,
    });
  }

  Future<void> _safe(Future<bool> Function() call) async {
    try {
      await call();
    } on LocationException catch (e) {
      _handleError(e);
    }
  }

  void _setStatus(LocationStatus value) {
    if (!isClosed) status.value = value;
  }
}
