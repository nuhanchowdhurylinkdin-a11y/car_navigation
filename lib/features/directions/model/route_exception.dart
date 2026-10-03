sealed class RouteException implements Exception {
  const RouteException(this.message);
  final String message;
}

class NoRouteException extends RouteException {
  const NoRouteException([super.message = 'No drivable route to this point']);
}

class RouteNetworkException extends RouteException {
  const RouteNetworkException([super.message = 'No internet connection']);
}

class RouteTimeoutException extends RouteException {
  const RouteTimeoutException([super.message = 'The routing server did not respond']);
}

class RouteServerException extends RouteException {
  const RouteServerException([super.message = 'Routing server error']);
}
