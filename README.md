# NavTest

Single-screen Flutter app: gets your location (own Kotlin code, no location plugins), fetches a driving route from OSRM when you long-press the map, and animates a car along it.

## Versions

- Flutter 3.47.1 (stable), Dart 3.13.1
- flutter_map 8.3.2, latlong2 0.10.1
- http 1.6.0, get 4.7.3, intl 0.20.3, url_launcher 6.3.2
- Android: play-services-location 21.3.0

## Run

```bash
flutter pub get

flutter run --flavor dev
flutter run --flavor prod
```

Build APKs:

```bash
flutter build apk --flavor dev
flutter build apk --flavor prod
```

Both can be installed on the same phone:

| Flavor | App name | Application ID |
|---|---|---|
| dev | NavTest Dev | com.nuhan.navtest.dev |
| prod | NavTest | com.nuhan.navtest |

The dev build shows a red DEV banner. The routing server URL for each flavor is in `lib/core/config/flavor_config.dart`.

Running without `--flavor` will stop with an error on purpose.

## Tests

```bash
flutter test
```

## How to use

1. Tap **Use my location** and allow the permission.
2. Long-press anywhere on the map to set a destination.
3. Tap **Start** to drive. Pause/Resume, Reset and 1x/2x/5x are in the bottom sheet.

No location? Use **Pick start point on map**, then long-press twice: start (A), then destination (B).

## Known limitations

- Android only. On iOS the location layer reports "not supported" instead of crashing.
- Uses the public OSRM demo server, which is rate limited and sometimes slow. Requests are debounced and limited to one per second.
- If the destination is more than 500 m from any road (sea, river, island without a road link) it's shown as "No drivable route".
- 1x is the real average speed from OSRM, so long routes take long. Use 5x or a short route for a demo.
- Map tiles aren't cached for offline use.
- Location updates only run while the app is in the foreground. No background tracking.

## Assumptions

- Location permission is asked only after the user taps "Use my location", not on launch.
- When the app goes to the background during a drive, the drive is paused and stays paused until the user taps Resume.
- Long-press is disabled while a drive is running so the route can't be replaced by accident.
