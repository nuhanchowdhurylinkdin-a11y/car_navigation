import 'dart:async';
import 'dart:convert';

import 'package:car_navigation/features/directions/controller/route_controller.dart';
import 'package:car_navigation/features/directions/model/route_exception.dart';
import 'package:car_navigation/features/directions/service/osrm_api_service.dart';
import 'package:car_navigation/features/location/controller/location_controller.dart';
import 'package:car_navigation/features/location/models/geo_position.dart';
import 'package:car_navigation/features/location/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

class _UnusedLocationService implements LocationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

http.Response okRoute(double distance) => http.Response(
      jsonEncode({
        'code': 'Ok',
        'routes': [
          {'geometry': '_p~iF~ps|U_ulLnnqC', 'distance': distance, 'duration': 60},
        ],
      }),
      200,
    );

void main() {
  late LocationController location;
  late Map<String, Completer<http.Response>> pending;
  late RouteController controller;

  setUp(() {
    location = LocationController(_UnusedLocationService());
    location.position.value = GeoPosition(
      latitude: 23.81,
      longitude: 90.41,
      accuracy: 5,
      bearing: 0,
      speed: 0,
      timestamp: DateTime(2026),
      isPrecise: true,
    );
    pending = {};
    final api = OsrmApiService(
      baseUrl: 'https://osrm.test',
      client: MockClient((request) {
        final completer = Completer<http.Response>();
        pending[request.url.path] = completer;
        return completer.future;
      }),
    );
    controller = RouteController(api, location, minRequestGap: Duration.zero);
  });

  tearDown(() => controller.onClose());

  String pathFor(LatLng end) => '/route/v1/driving/90.41,23.81;${end.longitude},${end.latitude}';

  test('a slow older response does not overwrite a newer one', () async {
    const first = LatLng(23.70, 90.30);
    const second = LatLng(23.75, 90.35);

    controller.destination.value = first;
    final firstRequest = controller.fetchRoute();
    await Future<void>.delayed(Duration.zero);

    controller.destination.value = second;
    final secondRequest = controller.fetchRoute();
    await Future<void>.delayed(Duration.zero);

    pending[pathFor(second)]!.complete(okRoute(2000));
    await secondRequest;
    pending[pathFor(first)]!.complete(okRoute(9999));
    await firstRequest;

    expect(controller.status.value, RouteStatus.success);
    expect(controller.path.value!.distanceMeters, 2000);
  });

  test('no location → noLocation, no request sent', () async {
    location.position.value = null;
    controller.destination.value = const LatLng(23.7, 90.3);

    await controller.fetchRoute();

    expect(controller.status.value, RouteStatus.noLocation);
    expect(pending, isEmpty);
  });

  test('typed error is exposed for the UI', () async {
    const target = LatLng(23.7, 90.3);
    controller.destination.value = target;
    final request = controller.fetchRoute();
    await Future<void>.delayed(Duration.zero);

    pending[pathFor(target)]!.complete(http.Response(jsonEncode({'code': 'NoRoute'}), 400));
    await request;

    expect(controller.status.value, RouteStatus.error);
    expect(controller.error.value, isA<NoRouteException>());
  });

  test('clearing the destination ignores an in-flight response', () async {
    const target = LatLng(23.7, 90.3);
    controller.destination.value = target;
    final request = controller.fetchRoute();
    await Future<void>.delayed(Duration.zero);

    controller.clearDestination();
    pending[pathFor(target)]!.complete(okRoute(1000));
    await request;

    expect(controller.status.value, RouteStatus.idle);
    expect(controller.path.value, isNull);
  });
}
