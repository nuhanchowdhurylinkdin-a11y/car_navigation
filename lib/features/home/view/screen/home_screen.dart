import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../location/controller/location_controller.dart';
import '../../controller/home_controller.dart';
import '../widgets/location_status_card.dart';
import '../widgets/map_view.dart';
import '../widgets/osm_attribution.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Obx(
            () => MapView(
              mapController: controller.mapController,
              userPosition: controller.location.position.value,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Obx(
                  () => controller.location.hasLocation
                      ? Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: FloatingActionButton.small(
                            onPressed: controller.recenterOnUser,
                            tooltip: 'My location',
                            child: const Icon(Icons.my_location),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                // Kept outside the map so the sheet never covers the required credit.
                const OsmAttribution(),
                Obx(
                  () => controller.location.status.value == LocationStatus.ready
                      ? const SafeArea(top: false, child: SizedBox(width: double.infinity))
                      : LocationStatusCard(
                          status: controller.location.status.value,
                          onUseMyLocation: controller.location.useMyLocation,
                          onOpenAppSettings: controller.location.openAppSettings,
                          onOpenLocationSettings: controller.location.openLocationSettings,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
