class RouteFormat {
  RouteFormat._();

  static String distance(double meters) {
    if (!meters.isFinite || meters < 0) return '0 m';
    return meters < 1000 ? '${meters.round()} m' : '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static String duration(double seconds) {
    if (!seconds.isFinite || seconds < 0) return '0 min';
    final minutes = (seconds / 60).round();
    if (minutes < 1) return '< 1 min';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }
}
