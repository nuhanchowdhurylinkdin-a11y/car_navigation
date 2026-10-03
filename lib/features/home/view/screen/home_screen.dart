import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../directions/controller/route_controller.dart';
import '../../../location/controller/location_controller.dart';
import '../../controller/home_controller.dart';
import '../widgets/location_status_card.dart';
import '../widgets/manual_start_sheet.dart';
import '../widgets/map_controls.dart';
import '../widgets/map_hint.dart';
import '../widgets/map_view.dart';
import '../widgets/osm_attribution.dart';
import '../widgets/route_sheet.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final location = controller.location;
    final route = controller.route;

    return Scaffold(
      body: Stack(
        children: [
          Obx(
            () => MapView(
              mapController: controller.mapController,
              userPosition: location.position.value,
              destination: route.destination.value,
              manualStart: route.manualStart.value,
              routePoints: route.path.value?.points ?? const [],
              showPendingLine: route.status.value == RouteStatus.loading,
              onLongPress: route.onMapLongPress,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Obx(() {
                final hint = _hintText();
                return hint == null ? const SizedBox.shrink() : MapHint(text: hint);
              }),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Obx(
                  () => MapControls(
                    onZoomIn: controller.zoomIn,
                    onZoomOut: controller.zoomOut,
                    onMyLocation: controller.onMyLocationPressed,
                    hasLocation: location.hasLocation,
                  ),
                ),
                // Kept outside the map so the sheet never covers the required credit.
                const OsmAttribution(),
                Obx(_bottomSheet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _hintText() {
    final route = controller.route;
    if (route.status.value != RouteStatus.idle) return null;
    if (route.needsManualStart) return 'Long-press the map to set your START point (A)';
    if (route.manualMode.value && route.destination.value == null) {
      return 'Now long-press to set the DESTINATION (B)';
    }
    return 'Long-press the map to pick a destination';
  }

  Widget _bottomSheet() {
    final location = controller.location;
    final route = controller.route;
    final status = route.status.value;
    final hasRouteSheet =
        status == RouteStatus.loading || status == RouteStatus.success || status == RouteStatus.error;

    if (route.manualMode.value) {
      return hasRouteSheet
          ? _routeSheet(start: route.manualStart.value, onChangeStart: route.changeManualStart)
          : ManualStartSheet(
              start: route.manualStart.value,
              onChangeStart: route.changeManualStart,
              onUseMyLocation: controller.useMyLocationInstead,
            );
    }

    if (location.status.value != LocationStatus.ready) {
      return LocationStatusCard(
        status: location.status.value,
        onUseMyLocation: location.useMyLocation,
        onOpenAppSettings: location.openAppSettings,
        onOpenLocationSettings: location.openLocationSettings,
        onPickStartOnMap: route.enterManualMode,
      );
    }

    return hasRouteSheet
        ? _routeSheet()
        : const SafeArea(top: false, child: SizedBox(width: double.infinity));
  }

  Widget _routeSheet({LatLng? start, VoidCallback? onChangeStart}) {
    final route = controller.route;
    return RouteSheet(
      status: route.status.value,
      destination: route.destination.value,
      path: route.path.value,
      error: route.error.value,
      isSlow: route.isSlow.value,
      onRetry: route.retry,
      onClear: route.clearDestination,
      start: start,
      onChangeStart: onChangeStart,
    );
  }
}
