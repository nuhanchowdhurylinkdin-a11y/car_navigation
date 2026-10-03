import '../models/geo_position.dart';
import '../models/location_permission_status.dart';

abstract class LocationService {
  Future<LocationPermissionStatus> checkPermission();

  Future<LocationPermissionStatus> requestPermission();

  Future<bool> isServiceEnabled();

  Future<GeoPosition> getCurrentLocation({
    Duration timeout = const Duration(seconds: 15),
  });

  Stream<GeoPosition> positionStream();

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}
