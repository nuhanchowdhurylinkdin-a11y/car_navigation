
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/constants/map_constants.dart';
import '../../../location/models/geo_position.dart';
import 'destination_marker.dart';
import 'user_location_marker.dart';

class MapView extends StatelessWidget {
  const MapView({
    super.key,
    this.mapController,
    this.userPosition,
    this.destination,
    this.routePoints = const [],
    this.onLongPress,
  });

  final MapController? mapController;
  final GeoPosition? userPosition;
  final LatLng? destination;
  final List<LatLng> routePoints;
  final void Function(LatLng point)? onLongPress;

  @override
  Widget build(BuildContext context) {
    final user = userPosition;
    final target = destination;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: MapConstants.defaultCenter,
        initialZoom: MapConstants.defaultZoom,
        minZoom: MapConstants.minZoom,
        maxZoom: MapConstants.maxZoom,
        onLongPress: (_, point) => onLongPress?.call(point),
      ),
      children: [
        TileLayer(
          urlTemplate: MapConstants.osmTileUrl,
          userAgentPackageName: MapConstants.userAgentPackageName,
          maxZoom: MapConstants.maxZoom,
        ),
        if (routePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 6,
                color: AppColors.primary,
                borderStrokeWidth: 2,
                borderColor: AppColors.white,
              ),
            ],
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
        if (target != null)
          MarkerLayer(
            markers: [
              Marker(
                point: target,
                width: DestinationMarker.size,
                height: DestinationMarker.size,
                alignment: Alignment.topCenter,
                child: const DestinationMarker(),
              ),
            ],
          ),
      ],
    );
  }
}
