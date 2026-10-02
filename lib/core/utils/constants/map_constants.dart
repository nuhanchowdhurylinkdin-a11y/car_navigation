import 'package:latlong2/latlong.dart';

class MapConstants {
  MapConstants._();

  /// OpenStreetMap standard tile server.
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Sent as the User-Agent with every tile request (OSM tile usage policy).
  static const String userAgentPackageName = 'com.nuhan.navtest';

  static const String osmCopyrightUrl =
      'https://www.openstreetmap.org/copyright';

  /// Shown before the user's location is known (Dhaka).
  static const LatLng defaultCenter = LatLng(23.8103, 90.4125);
  static const double defaultZoom = 13;
  static const double minZoom = 3;
  static const double maxZoom = 19;
}
