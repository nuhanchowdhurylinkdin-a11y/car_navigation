import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../location/controller/location_controller.dart';
import '../../location/models/geo_position.dart';

/// Owns the map camera for the home screen.
class HomeController extends GetxController {
  HomeController(this.location);

  static const double userZoom = 16;

  final LocationController location;
  final mapController = MapController();

  Worker? _firstFixWorker;
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
  }

  @override
  void onClose() {
    _firstFixWorker?.dispose();
    _firstFixWorker = null;
    mapController.dispose();
    super.onClose();
  }

  void recenterOnUser() {
    final fix = location.position.value;
    if (fix != null) mapController.move(fix.latLng, userZoom);
  }
}
