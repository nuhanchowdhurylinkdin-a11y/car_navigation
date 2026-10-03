import 'dart:convert';
import 'dart:io';

import 'package:car_navigation/features/directions/model/route_exception.dart';
import 'package:car_navigation/features/directions/service/osrm_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

const start = LatLng(23.8103, 90.4125);
const end = LatLng(23.7461, 90.3742);

OsrmApiService serviceWith(Future<http.Response> Function(http.Request) handler) =>
    OsrmApiService(baseUrl: 'https://osrm.test', client: MockClient(handler));

void main() {
  test('builds a lng,lat URL with the user agent and parses the route', () async {
    late http.Request sent;
    final service = serviceWith((request) async {
      sent = request;
      return http.Response(
        jsonEncode({
          'code': 'Ok',
          'routes': [
            {'geometry': '_p~iF~ps|U_ulLnnqC', 'distance': 11995.4, 'duration': 943.6},
          ],
          'waypoints': [],
        }),
        200,
      );
    });

    final model = await service.fetchRoute(start: start, end: end);

    expect(sent.url.path, '/route/v1/driving/90.4125,23.8103;90.3742,23.7461');
    expect(sent.url.queryParameters, {'overview': 'full', 'geometries': 'polyline'});
    expect(sent.headers['User-Agent'], contains('NavTest'));
    expect(model.routes.first.distance, 11995.4);
  });

  test('NoRoute response becomes NoRouteException', () async {
    final service = serviceWith(
      (_) async => http.Response(jsonEncode({'code': 'NoRoute', 'message': 'Impossible route'}), 400),
    );

    await expectLater(
      service.fetchRoute(start: start, end: end),
      throwsA(isA<NoRouteException>()),
    );
  });

  test('network failure becomes RouteNetworkException', () async {
    final service = serviceWith((_) async => throw const SocketException('offline'));

    await expectLater(
      service.fetchRoute(start: start, end: end),
      throwsA(isA<RouteNetworkException>()),
    );
  });

  test('non-JSON error page becomes RouteServerException', () async {
    final service = serviceWith((_) async => http.Response('<html>502</html>', 502));

    await expectLater(
      service.fetchRoute(start: start, end: end),
      throwsA(isA<RouteServerException>()),
    );
  });
}
