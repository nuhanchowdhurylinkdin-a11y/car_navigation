import 'dart:async';

import 'package:flutter/services.dart';

import '../models/geo_position.dart';
import '../models/location_exception.dart';
import '../models/location_permission_status.dart';
import 'location_service.dart';

/// [LocationService] backed by our own platform channels
/// (Kotlin on Android). This is the only class that touches the channels.
///
/// Platforms without a native implementation (e.g. iOS for now) surface as
/// [MissingPluginException], which is reported as [LocationUnsupportedException].
class NativeLocationService implements LocationService {
  NativeLocationService({
    MethodChannel methodChannel = const MethodChannel('com.nuhan.navtest/location'),
    EventChannel eventChannel = const EventChannel('com.nuhan.navtest/location_stream'),
  })  : _methods = methodChannel,
        _events = eventChannel;

  final MethodChannel _methods;
  final EventChannel _events;

  @override
  Future<LocationPermissionStatus> checkPermission() => _guard(() async {
        final value = await _methods.invokeMethod<String>('checkPermission');
        return LocationPermissionStatus.fromWire(value);
      });

  @override
  Future<LocationPermissionStatus> requestPermission() => _guard(() async {
        final value = await _methods.invokeMethod<String>('requestPermission');
        return LocationPermissionStatus.fromWire(value);
      });

  @override
  Future<bool> isServiceEnabled() => _guard(() async {
        return await _methods.invokeMethod<bool>('isLocationServiceEnabled') ?? false;
      });

  @override
  Future<GeoPosition> getCurrentLocation({
    Duration timeout = const Duration(seconds: 15),
  }) =>
      _guard(() async {
        final map = await _methods.invokeMapMethod<String, dynamic>(
          'getCurrentLocation',
          {'timeoutMs': timeout.inMilliseconds},
        );
        if (map == null) throw const LocationUnknownException('Empty location result');
        return GeoPosition.fromMap(map);
      });

  @override
  Stream<GeoPosition> positionStream() async* {
    // An EventChannel without a native handler fails silently, so probe the
    // method channel first to surface "unsupported platform" as an error.
    await isServiceEnabled();
    yield* _events
        .receiveBroadcastStream()
        .map((event) => GeoPosition.fromMap(event as Map))
        .handleError(
          (Object error) => throw mapError(error),
          test: (error) => error is! LocationException,
        );
  }

  @override
  Future<bool> openAppSettings() => _guard(() async {
        return await _methods.invokeMethod<bool>('openAppSettings') ?? false;
      });

  @override
  Future<bool> openLocationSettings() => _guard(() async {
        return await _methods.invokeMethod<bool>('openLocationSettings') ?? false;
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (error) {
      throw mapError(error);
    }
  }

  /// Maps native error codes (see LocationErrors.kt) to typed exceptions.
  static LocationException mapError(Object error) => switch (error) {
        LocationException() => error,
        MissingPluginException() => const LocationUnsupportedException(),
        PlatformException(code: 'PERMISSION_DENIED') => const PermissionDeniedException(),
        PlatformException(code: 'PERMISSION_DENIED_FOREVER') =>
          const PermissionDeniedForeverException(),
        PlatformException(code: 'SERVICE_DISABLED') => const LocationServiceDisabledException(),
        PlatformException(code: 'TIMEOUT') => const LocationTimeoutException(),
        PlatformException(:final message) =>
          LocationUnknownException(message ?? 'Unknown native error'),
        _ => LocationUnknownException(error.toString()),
      };
}
