enum LocationPermissionStatus {
  granted,
  denied,

  deniedForever;

  static LocationPermissionStatus fromWire(String? value) => switch (value) {
        'granted' => granted,
        'deniedForever' => deniedForever,
        _ => denied,
      };
}
