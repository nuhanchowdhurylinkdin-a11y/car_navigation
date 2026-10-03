import 'package:car_navigation/features/directions/controller/route_controller.dart';
import 'package:car_navigation/features/directions/model/route_path.dart';
import 'package:car_navigation/features/directions/service/osrm_api_service.dart';
import 'package:car_navigation/features/location/controller/location_controller.dart';
import 'package:car_navigation/features/location/services/location_service.dart';
import 'package:car_navigation/features/navigation/controller/navigation_controller.dart';
import 'package:car_navigation/features/navigation/logic/navigation_simulator.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

class _UnusedLocationService implements LocationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const path = RoutePath(
  points: [LatLng(23.8, 90.40), LatLng(23.8, 90.41)],
  distanceMeters: 1018,
  durationSeconds: 100,
);

void main() {
  late RouteController route;
  late NavigationController navigation;

  setUp(() {
    route = RouteController(
      OsrmApiService(
        baseUrl: 'https://osrm.test',
        client: MockClient((_) async => http.Response('{}', 500)),
      ),
      LocationController(_UnusedLocationService()),
    );
    navigation = NavigationController(route);
  });

  testWidgets('drives on real frames, stops when the route is cleared, cleans up on close',
      (tester) async {
    await tester.pumpWidget(const SizedBox());
    navigation.onInit();
    route.path.value = path;
    await tester.pump();

    expect(navigation.canStart, isTrue);
    final startPosition = navigation.carPosition.value;

    navigation.start();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(navigation.state.value, NavigationState.running);
    expect(navigation.carPosition.value, isNot(startPosition));
    expect(navigation.remainingMeters.value, lessThan(path.distanceMeters));

    navigation.pause();
    final paused = navigation.carPosition.value;
    await tester.pump(const Duration(seconds: 1));
    expect(navigation.carPosition.value, paused);

    navigation.resume();
    await tester.pump(const Duration(milliseconds: 16));
    route.path.value = null;
    await tester.pump(const Duration(milliseconds: 16));
    expect(navigation.state.value, NavigationState.idle);
    expect(navigation.carPosition.value, isNull);

    navigation.onClose();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('going to background pauses the drive', (tester) async {
    await tester.pumpWidget(const SizedBox());
    navigation.onInit();
    route.path.value = path;
    await tester.pump();
    navigation.start();
    await tester.pump(const Duration(milliseconds: 16));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    expect(navigation.state.value, NavigationState.paused);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 16));
    expect(navigation.state.value, NavigationState.paused);

    navigation.onClose();
  });
}
