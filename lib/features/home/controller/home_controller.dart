import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../../core/utils/constants/map_constants.dart';
import '../../directions/controller/route_controller.dart';
import '../../directions/model/route_path.dart';
import '../../location/controller/location_controller.dart';
import '../../location/models/geo_position.dart';

/// Owns the map camera for the home screen.
class HomeController extends GetxController {
  HomeController(this.location, this.route);

  static const double userZoom = 16;
  static const EdgeInsets routePadding = EdgeInsets.fromLTRB(48, 96, 48, 340);

  final LocationController location;
  final RouteController route;
  final mapController = MapController();

  Worker? _firstFixWorker;
  Worker? _routeWorker;
  bool _centeredOnUser = false;

  @override
  void onInit() {
    super.onInit();
    // Center on the user once, when the first fix arrives. Later updates only
    // move the dot, so the user can pan freely.
    _firstFixWorker = ever<GeoPosition?>(location.position, (fix) {
      if (fix == null || _centeredOnUser || isClosed) return;
      _centeredOnUser = true;
      mapController.move(fix.latLng, userZoom);
    });
    _routeWorker = ever<RoutePath?>(route.path, (path) {
      if (path == null || isClosed) return;
      fitRoute(path);
    });
  }

  @override
  void onClose() {
    _firstFixWorker?.dispose();
    _firstFixWorker = null;
    _routeWorker?.dispose();
    _routeWorker = null;
    mapController.dispose();
    super.onClose();
  }

  void recenterOnUser() {
    final fix = location.position.value;
    if (fix != null) mapController.move(fix.latLng, userZoom);
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
