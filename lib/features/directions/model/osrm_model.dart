class OsrmModel {
  const OsrmModel({
    required this.code,
    required this.routes,
    required this.waypoints,
  });

  final String code;
  final List<OsrmRoute> routes;
  final List<OsrmWaypoint> waypoints;

  factory OsrmModel.fromJson(Map<String, dynamic> json) {
    return OsrmModel(
      code: json['code'] as String? ?? '',
      routes: (json['routes'] as List<dynamic>? ?? const [])
          .map((e) => OsrmRoute.fromJson(e as Map<String, dynamic>))
          .toList(),
      waypoints: (json['waypoints'] as List<dynamic>? ?? const [])
          .map((e) => OsrmWaypoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      'routes': routes.map((e) => e.toJson()).toList(),
      'waypoints': waypoints.map((e) => e.toJson()).toList(),
    };
  }
}

class OsrmLeg {
  const OsrmLeg({
    required this.steps,
    required this.weight,
    required this.summary,
    required this.duration,
    required this.distance,
  });

  final List<dynamic> steps;
  final double weight;
  final String summary;
  final double duration;
  final double distance;

  factory OsrmLeg.fromJson(Map<String, dynamic> json) {
    return OsrmLeg(
      steps: json['steps'] as List<dynamic>? ?? const [],
      weight: (json['weight'] as num? ?? 0).toDouble(),
      summary: json['summary'] as String? ?? '',
      duration: (json['duration'] as num? ?? 0).toDouble(),
      distance: (json['distance'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'steps': steps,
      'weight': weight,
      'summary': summary,
      'duration': duration,
      'distance': distance,
    };
  }
}

class OsrmRoute {
  const OsrmRoute({
    required this.legs,
    required this.weightName,
    required this.geometry,
    required this.weight,
    required this.duration,
    required this.distance,
  });

  final List<OsrmLeg> legs;
  final String weightName;
  final String geometry;
  final double weight;
  final double duration;
  final double distance;

  factory OsrmRoute.fromJson(Map<String, dynamic> json) {
    return OsrmRoute(
      legs: (json['legs'] as List<dynamic>? ?? const [])
          .map((e) => OsrmLeg.fromJson(e as Map<String, dynamic>))
          .toList(),
      weightName: json['weight_name'] as String? ?? '',
      geometry: json['geometry'] as String? ?? '',
      weight: (json['weight'] as num? ?? 0).toDouble(),
      duration: (json['duration'] as num? ?? 0).toDouble(),
      distance: (json['distance'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'legs': legs.map((e) => e.toJson()).toList(),
      'weight_name': weightName,
      'geometry': geometry,
      'weight': weight,
      'duration': duration,
      'distance': distance,
    };
  }
}

class OsrmWaypoint {
  const OsrmWaypoint({
    required this.hint,
    required this.location,
    required this.name,
    required this.distance,
  });

  final String hint;
  final List<double> location;
  final String name;
  final double distance;

  factory OsrmWaypoint.fromJson(Map<String, dynamic> json) {
    return OsrmWaypoint(
      hint: json['hint'] as String? ?? '',
      location: (json['location'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toDouble())
          .toList(),
      name: json['name'] as String? ?? '',
      distance: (json['distance'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'hint': hint,
      'location': location,
      'name': name,
      'distance': distance,
    };
  }
}
