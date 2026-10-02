import '../models/geo_position.dart';
import '../models/location_permission_status.dart';

/// The only way the app talks to device location.
/// All methods throw [LocationException] subtypes on failure.
abstract class LocationService {
  Future<LocationPermissionStatus> checkPermission();

  /// Shows the system permission dialog if needed.
  Future<LocationPermissionStatus> requestPermission();

  Future<bool> isServiceEnabled();

  Future<GeoPosition> getCurrentLocation({
    Duration timeout = const Duration(seconds: 15),
  });

  /// Live updates. Native updates run only while this stream is listened to.
  Stream<GeoPosition> positionStream();

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}
