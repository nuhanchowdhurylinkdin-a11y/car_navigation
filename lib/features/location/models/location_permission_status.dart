enum LocationPermissionStatus {
  granted,
  denied,

  /// The system will no longer show the permission dialog;
  /// the user must enable it from the app's Settings page.
  deniedForever;

  static LocationPermissionStatus fromWire(String? value) => switch (value) {
        'granted' => granted,
        'deniedForever' => deniedForever,
        _ => denied,
      };
}
