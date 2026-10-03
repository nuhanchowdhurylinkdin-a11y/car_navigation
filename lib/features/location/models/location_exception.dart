sealed class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class PermissionDeniedException extends LocationException {
  const PermissionDeniedException([super.message = 'Location permission denied']);
}

class PermissionDeniedForeverException extends LocationException {
  const PermissionDeniedForeverException(
      [super.message = 'Location permission permanently denied']);
}

class LocationServiceDisabledException extends LocationException {
  const LocationServiceDisabledException(
      [super.message = 'Location services are turned off']);
}

class LocationTimeoutException extends LocationException {
  const LocationTimeoutException([super.message = 'Timed out waiting for a location fix']);
}

class LocationUnsupportedException extends LocationException {
  const LocationUnsupportedException(
      [super.message = 'Location is not supported on this platform']);
}

class LocationUnknownException extends LocationException {
  const LocationUnknownException([super.message = 'Unknown location error']);
}
