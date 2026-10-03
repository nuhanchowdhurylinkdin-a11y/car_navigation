import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../core/network/reporting_http_client.dart';
import '../../../core/utils/constants/map_constants.dart';
import '../../directions/controller/route_controller.dart';
import '../../directions/model/route_path.dart';
import '../../location/controller/location_controller.dart';
import '../../location/models/geo_position.dart';
import '../../navigation/controller/navigation_controller.dart';
import '../../navigation/logic/navigation_simulator.dart';

class HomeController extends GetxController {
  HomeController(this.location, this.route, this.navigation);

  static const double userZoom = 16;
  static const double carZoom = 17;
  static const EdgeInsets routePadding = EdgeInsets.fromLTRB(48, 96, 48, 340);

  final LocationController location;
  final RouteController route;
  final NavigationController navigation;
  final mapController = MapController();
  final isFollowingCar = true.obs;

  final tilesUnavailable = false.obs;

  late final http.Client _tileHttpClient = ReportingHttpClient(
    http.Client(),
    onReachable: _onTilesReachable,
    onUnreachable: _onTilesUnreachable,
  );
  late final TileProvider tileProvider = NetworkTileProvider(
    httpClient: _tileHttpClient,
    silenceExceptions: true,
  );
  final _tileReset = StreamController<void>.broadcast();

  Stream<void> get tileReset => _tileReset.stream;

  Worker? _firstFixWorker;
  Worker? _routeWorker;
  Worker? _carWorker;
  Worker? _navStateWorker;
  bool _centeredOnUser = false;
  NavigationState _lastNavState = NavigationState.idle;

  @override
  void onInit() {
    super.onInit();
    // Only jump to the user on the first fix, so later updates don't fight the user panning.
    _firstFixWorker = ever<GeoPosition?>(location.position, (fix) {
      if (fix == null || _centeredOnUser || isClosed) return;
      _centeredOnUser = true;
      mapController.move(fix.latLng, userZoom);
    });
    _routeWorker = ever<RoutePath?>(route.path, (path) {
      if (path == null || isClosed) return;
      fitRoute(path);
    });
    _carWorker = ever<LatLng?>(navigation.carPosition, (car) {
      if (car == null || !navigation.isActive || !isFollowingCar.value || isClosed) return;
      mapController.move(car, mapController.camera.zoom);
    });
    _navStateWorker = ever<NavigationState>(navigation.state, _onNavigationState);
  }

  @override
  void onClose() {
    _firstFixWorker?.dispose();
    _firstFixWorker = null;
    _routeWorker?.dispose();
    _routeWorker = null;
    _carWorker?.dispose();
    _carWorker = null;
    _navStateWorker?.dispose();
    _navStateWorker = null;
    mapController.dispose();
    _tileHttpClient.close();
    _tileReset.close();
    super.onClose();
  }

  void recenterOnUser() {
    final fix = location.position.value;
    if (fix != null) mapController.move(fix.latLng, userZoom);
  }

  void _onTilesUnreachable() {
    if (!isClosed) tilesUnavailable.value = true;
  }

  void _onTilesReachable() {
    if (isClosed || !tilesUnavailable.value) return;
    tilesUnavailable.value = false;
    _tileReset.add(null);
  }

  void onMapGesture() {
    if (navigation.isActive) isFollowingCar.value = false;
  }

  void recenterOnCar() {
    final car = navigation.carPosition.value;
    if (car == null) return;
    isFollowingCar.value = true;
    mapController.move(car, carZoom);
  }

  void startNavigation() => navigation.start();

  void driveAgain() => navigation.restart();

  void chooseNewDestination() {
    navigation.reset();
    route.clearDestination();
  }

  void _onNavigationState(NavigationState state) {
    if (isClosed) return;
    final previous = _lastNavState;
    _lastNavState = state;
    if (previous == NavigationState.idle && state == NavigationState.running) {
      recenterOnCar();
    } else if (state == NavigationState.idle && previous != NavigationState.idle) {
      isFollowingCar.value = true;
      final path = route.path.value;
      if (path != null) fitRoute(path);
    }
  }

  void zoomIn() => _zoomBy(1);

  void zoomOut() => _zoomBy(-1);

  void onMyLocationPressed() {
    if (location.hasLocation) {
      recenterOnUser();
    } else {
      useMyLocationInstead();
    }
  }

  void useMyLocationInstead() {
    route.exitManualMode();
    location.useMyLocation();
  }

  void _zoomBy(double delta) {
    final camera = mapController.camera;
    final zoom = (camera.zoom + delta).clamp(MapConstants.minZoom, MapConstants.maxZoom);
    mapController.move(camera.center, zoom.toDouble());
  }

  void fitRoute(RoutePath path) {
    if (path.points.length < 2) return;
    mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: path.points,
        padding: routePadding,
        maxZoom: 17,
      ),
    );
  }
}
