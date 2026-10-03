import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/constants/map_constants.dart';
import '../../../location/models/geo_position.dart';
import 'destination_marker.dart';
import 'start_marker.dart';
import 'user_location_marker.dart';

class MapView extends StatelessWidget {
  const MapView({
    super.key,
    this.mapController,
    this.tileProvider,
    this.tileReset,
    this.userPosition,
    this.destination,
    this.manualStart,
    this.routePoints = const [],
    this.showPendingLine = false,
    this.onLongPress,
    this.onUserGesture,
    this.routeOverlay,
    this.topOverlay,
  });

  final MapController? mapController;
  final TileProvider? tileProvider;

  /// Each event reloads the visible tiles (e.g. after the connection returns).
  final Stream<void>? tileReset;
  final GeoPosition? userPosition;
  final LatLng? destination;
  final LatLng? manualStart;
  final List<LatLng> routePoints;
  final bool showPendingLine;
  final void Function(LatLng point)? onLongPress;

  /// Called when the user pans, zooms or rotates the map by hand.
  final VoidCallback? onUserGesture;

  /// Drawn just above the route line (e.g. the travelled part).
  final Widget? routeOverlay;

  /// Drawn above every other layer (e.g. the car).
  final Widget? topOverlay;

  @override
  Widget build(BuildContext context) {
    final user = userPosition;
    final target = destination;
    final startPin = manualStart;
    final routeStart = startPin ?? user?.latLng;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: MapConstants.defaultCenter,
        initialZoom: MapConstants.defaultZoom,
        minZoom: MapConstants.minZoom,
        maxZoom: MapConstants.maxZoom,
        onLongPress: (_, point) => onLongPress?.call(point),
        onPositionChanged: (_, hasGesture) {
          if (hasGesture) onUserGesture?.call();
        },
      ),
      children: [
        TileLayer(
          urlTemplate: MapConstants.osmTileUrl,
          userAgentPackageName: MapConstants.userAgentPackageName,
          maxZoom: MapConstants.maxZoom,
          tileProvider: tileProvider,
          reset: tileReset,
          evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
        ),
        if (showPendingLine && routeStart != null && target != null && routePoints.isEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [routeStart, target],
                strokeWidth: 3,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                pattern: StrokePattern.dashed(segments: const [10, 8]),
              ),
            ],
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
        ?routeOverlay,
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
        if (startPin != null)
          MarkerLayer(
            markers: [
              Marker(
                point: startPin,
                width: StartMarker.size,
                height: StartMarker.size,
                child: const StartMarker(),
              ),
            ],
          ),
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
        ?topOverlay,
      ],
    );
  }
}
