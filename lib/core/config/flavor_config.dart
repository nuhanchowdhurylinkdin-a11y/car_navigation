import 'package:flutter/services.dart';

class FlavorConfig {
  final String name;
  final String routingBaseUrl;
  final bool isDev;

  const FlavorConfig._({
    required this.name,
    required this.routingBaseUrl,
    required this.isDev,
  });

  static const dev = FlavorConfig._(
    name: 'dev',
    routingBaseUrl: 'https://router.project-osrm.org',
    isDev: true,
  );

  static const prod = FlavorConfig._(
    name: 'prod',
    routingBaseUrl: 'https://router.project-osrm.org',
    isDev: false,
  );

  static FlavorConfig fromAppFlavor() => switch (appFlavor) {
        'dev' => dev,
        'prod' => prod,
        _ => throw StateError(
            'Unknown flavor "$appFlavor". Run with --flavor dev or --flavor prod.',
          ),
      };
}
