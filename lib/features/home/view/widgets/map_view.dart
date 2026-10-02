import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/utils/constants/map_constants.dart';
import '../../../location/models/geo_position.dart';
import 'user_location_marker.dart';

class MapView extends StatelessWidget {
  const MapView({super.key, this.mapController, this.userPosition});

  final MapController? mapController;
  final GeoPosition? userPosition;

  @override
  Widget build(BuildContext context) {
    final user = userPosition;

    return FlutterMap(
      mapController: mapController,
      options: const MapOptions(
        initialCenter: MapConstants.defaultCenter,
        initialZoom: MapConstants.defaultZoom,
        minZoom: MapConstants.minZoom,
        maxZoom: MapConstants.maxZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: MapConstants.osmTileUrl,
          userAgentPackageName: MapConstants.userAgentPackageName,
          maxZoom: MapConstants.maxZoom,
        ),
        if (user != null) ...[
          CircleLayer(
            circles: [
              CircleMarker(
                point: user.latLng,
                radius: user.accuracy,
                useRadiusInMeter: true,
                color: UserLocationMarker.color.withValues(alpha: 0.12),
                borderColor: UserLocationMarker.color.withValues(alpha: 0.3),
                borderStrokeWidth: 1,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: user.latLng,
                width: UserLocationMarker.size,
                height: UserLocationMarker.size,
                child: const UserLocationMarker(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
