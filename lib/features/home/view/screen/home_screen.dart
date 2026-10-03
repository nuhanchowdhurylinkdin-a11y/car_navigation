import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../directions/controller/route_controller.dart';
import '../../../location/controller/location_controller.dart';
import '../../controller/home_controller.dart';
import '../widgets/location_status_card.dart';
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
              routePoints: route.path.value?.points ?? const [],
              showPendingLine: route.status.value == RouteStatus.loading,
              onLongPress: route.setDestination,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Obx(
                () => route.status.value == RouteStatus.idle
                    ? const MapHint(text: 'Long-press the map to pick a destination')
                    : const SizedBox.shrink(),
              ),
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

  Widget _bottomSheet() {
    final location = controller.location;
    final route = controller.route;

    if (location.status.value != LocationStatus.ready) {
      return LocationStatusCard(
        status: location.status.value,
        onUseMyLocation: location.useMyLocation,
        onOpenAppSettings: location.openAppSettings,
        onOpenLocationSettings: location.openLocationSettings,
      );
    }

    return switch (route.status.value) {
      RouteStatus.loading || RouteStatus.success || RouteStatus.error => RouteSheet(
          status: route.status.value,
          destination: route.destination.value,
          path: route.path.value,
          error: route.error.value,
          isSlow: route.isSlow.value,
          onRetry: route.retry,
          onClear: route.clearDestination,
        ),
      RouteStatus.idle || RouteStatus.noLocation =>
        const SafeArea(top: false, child: SizedBox(width: double.infinity)),
    };
  }
}
