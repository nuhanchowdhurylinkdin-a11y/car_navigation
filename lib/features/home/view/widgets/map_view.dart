import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/constants/map_constants.dart';

class MapView extends StatelessWidget {
  const MapView({super.key, this.mapController});

  final MapController? mapController;

  @override
  Widget build(BuildContext context) {
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
        SimpleAttributionWidget(
          source: const Text('OpenStreetMap contributors'),
          onTap: () => launchUrl(Uri.parse(MapConstants.osmCopyrightUrl)),
        ),
      ],
    );
  }
}
