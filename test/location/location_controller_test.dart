import 'dart:async';

import 'package:car_navigation/features/location/controller/location_controller.dart';
import 'package:car_navigation/features/location/models/geo_position.dart';
import 'package:car_navigation/features/location/models/location_exception.dart';
import 'package:car_navigation/features/location/models/location_permission_status.dart';
import 'package:car_navigation/features/location/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLocationService implements LocationService {
  bool serviceEnabled = true;
  LocationPermissionStatus permission = LocationPermissionStatus.granted;
  LocationPermissionStatus permissionAfterRequest = LocationPermissionStatus.granted;
  Object? fixError;
  int requestCount = 0;
  final streamController = StreamController<GeoPosition>.broadcast();

  static final fix = GeoPosition(
    latitude: 23.81,
    longitude: 90.41,
    accuracy: 5,
    bearing: 0,
    speed: 0,
    timestamp: DateTime(2026),
    isPrecise: true,
  );

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermissionStatus> checkPermission() async => permission;

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    requestCount++;
    return permissionAfterRequest;
  }

  @override
  Future<GeoPosition> getCurrentLocation({Duration timeout = const Duration(seconds: 15)}) async {
    if (fixError != null) throw fixError!;
    return fix;
  }

  @override
  Stream<GeoPosition> positionStream() => streamController.stream;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLocationService service;
  late LocationController controller;

  setUp(() {
    service = FakeLocationService();
    controller = LocationController(service)..onInit();
  });

  tearDown(() => controller.onClose());

  test('does not ask for permission until the user acts', () {
    expect(controller.status.value, LocationStatus.idle);
    expect(service.requestCount, 0);
  });

  test('granted → ready with a position and live tracking', () async {
    await controller.useMyLocation();

    expect(controller.status.value, LocationStatus.ready);
    expect(controller.position.value, FakeLocationService.fix);
    expect(service.streamController.hasListener, isTrue);
  });

  test('requests permission when not yet granted', () async {
    service.permission = LocationPermissionStatus.denied;
    service.permissionAfterRequest = LocationPermissionStatus.denied;

    await controller.useMyLocation();

    expect(service.requestCount, 1);
    expect(controller.status.value, LocationStatus.denied);
  });

  test('permanently denied', () async {
    service.permission = LocationPermissionStatus.deniedForever;
    service.permissionAfterRequest = LocationPermissionStatus.deniedForever;

    await controller.useMyLocation();

    expect(controller.status.value, LocationStatus.deniedForever);
  });

  test('location services off', () async {
    service.serviceEnabled = false;

    await controller.useMyLocation();

    expect(controller.status.value, LocationStatus.serviceDisabled);
  });

  test('no fix within the timeout', () async {
    service.fixError = const LocationTimeoutException();

    await controller.useMyLocation();

    expect(controller.status.value, LocationStatus.timeout);
    expect(controller.position.value, isNull);
  });

  test('closing the controller cancels the native stream', () async {
    await controller.useMyLocation();
    expect(service.streamController.hasListener, isTrue);

    controller.onClose();

    expect(service.streamController.hasListener, isFalse);
  });
}
