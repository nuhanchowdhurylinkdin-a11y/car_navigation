import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/constants/colors.dart';
import '../../../directions/controller/route_controller.dart';
import '../../../location/controller/location_controller.dart';
import '../../../navigation/logic/navigation_simulator.dart';
import '../../../navigation/view/car_marker.dart';
import '../../controller/home_controller.dart';
import '../widgets/location_status_card.dart';
import '../widgets/manual_start_sheet.dart';
import '../widgets/map_controls.dart';
import '../widgets/map_hint.dart';
import '../widgets/map_view.dart';
import '../widgets/navigation_sheet.dart';
import '../widgets/osm_attribution.dart';
import '../widgets/recenter_button.dart';
import '../widgets/route_sheet.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final location = controller.location;
    final route = controller.route;
    final navigation = controller.navigation;

    return Scaffold(
      body: Stack(
        children: [
          Obx(
            () => MapView(
              mapController: controller.mapController,
              tileProvider: controller.tileProvider,
              tileReset: controller.tileReset,
              userPosition: location.position.value,
              destination: route.destination.value,
              manualStart: route.manualStart.value,
              routePoints: route.path.value?.points ?? const [],
              showPendingLine: route.status.value == RouteStatus.loading,
              onLongPress: navigation.isActive ? null : route.onMapLongPress,
              onUserGesture: controller.onMapGesture,
              routeOverlay: Obx(_travelledLayer),
              topOverlay: Obx(_carLayer),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Obx(() {
                final hint = _hintText();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.tilesUnavailable.value)
                      const MapHint(
                        text: 'Map tiles unavailable — check your internet connection',
                        icon: Icons.wifi_off_rounded,
                        color: AppColors.warning,
                      ),
                    if (hint != null) MapHint(text: hint),
                  ],
                );
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
                Obx(
                  () => navigation.isActive &&
                          navigation.state.value != NavigationState.finished &&
                          !controller.isFollowingCar.value
                      ? Center(child: RecenterButton(onPressed: controller.recenterOnCar))
                      : const SizedBox.shrink(),
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

  Widget _travelledLayer() {
    final points = controller.navigation.travelledPoints.value;
    if (points.length < 2) return const SizedBox.shrink();
    return PolylineLayer(
      polylines: [
        Polyline(
          points: points,
          strokeWidth: 6,
          color: const Color.fromARGB(255, 73, 74, 78),
          borderStrokeWidth: 2,
          borderColor: AppColors.white,
        ),
      ],
    );
  }

  Widget _carLayer() {
    final car = controller.navigation.carPosition.value;
    final bearing = controller.navigation.carBearing.value;
    if (car == null) return const SizedBox.shrink();
    return MarkerLayer(
      markers: [
        Marker(
          point: car,
          width: CarMarker.size,
          height: CarMarker.size,
          child: CarMarker(bearing: bearing),
        ),
      ],
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
    final navigation = controller.navigation;
    final status = route.status.value;
    final hasRouteSheet =
        status == RouteStatus.loading || status == RouteStatus.success || status == RouteStatus.error;

    if (navigation.isActive) {
      return NavigationSheet(
        state: navigation.state.value,
        remainingMeters: navigation.remainingMeters.value,
        remainingSeconds: navigation.remainingSeconds.value,
        totalMeters: navigation.totalMeters.value,
        routeSeconds: route.path.value?.durationSeconds ?? 0,
        progress: navigation.progress.value,
        multiplier: navigation.multiplier.value,
        onTogglePause: navigation.togglePause,
        onReset: navigation.reset,
        onMultiplierChanged: navigation.setMultiplier,
        onDriveAgain: controller.driveAgain,
        onNewDestination: controller.chooseNewDestination,
      );
    }

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
    final navigation = controller.navigation;
    return RouteSheet(
      status: route.status.value,
      destination: route.destination.value,
      path: route.path.value,
      error: route.error.value,
      isSlow: route.isSlow.value,
      onRetry: route.retry,
      onClear: route.clearDestination,
      onStart: navigation.canStart ? controller.startNavigation : null,
      start: start,
      onChangeStart: onChangeStart,
    );
  }
}
