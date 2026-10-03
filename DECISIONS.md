# Decisions

## Architecture and state management

The code is split by feature:

- `location`: native bridge, `LocationService` interface, `LocationController`
- `directions`: OSRM call, polyline decoding, `RouteController`
- `navigation`: car animation (`RouteAnimator`, `NavigationSimulator`, `NavigationController`)
- `home`: the single screen and its widgets

I used GetX because the project template already had it and it's what I'm fastest with. I kept it to state and DI only. The logic that matters (route math, the simulator, the OSRM service, the location service) is plain Dart with no GetX inside, so it can be tested on its own. Controllers get their dependencies through the constructor in `ControllerBinder` instead of calling `Get.find` internally, so tests can pass fakes.

Downside: GetX hides a lot (global locator, lifecycle magic). On a bigger team I'd probably pick Riverpod or Bloc.

## Native location bridge

Two channels:

- `MethodChannel` `com.nuhan.navtest/location` for one-off calls: `checkPermission`, `requestPermission`, `isLocationServiceEnabled`, `getCurrentLocation` (with `timeoutMs`), `openAppSettings`, `openLocationSettings`.
- `EventChannel` `com.nuhan.navtest/location_stream` for live updates.

I used an EventChannel for the stream because `onCancel` tells the native side exactly when Dart stops listening. There it calls `removeLocationUpdates`, so nothing keeps running. The stream is cancelled when the controller closes and when the app is hidden, and the plugin cleans up when the Flutter engine is torn down.

Errors go over the channel as fixed codes (`PERMISSION_DENIED`, `PERMISSION_DENIED_FOREVER`, `SERVICE_DISABLED`, `TIMEOUT`, `UNAVAILABLE`). `NativeLocationService` maps them to a sealed `LocationException`, so the UI switches on types and never parses strings. Only that class touches the channels.

A few details:

- The timeout is on the native side, so a timed-out request also cancels the GPS request instead of just giving up in Dart.
- The fix and the timeout can race. A `replied` flag makes sure the result is answered once.
- Android has no direct "permanently denied" flag. I treat it as denied forever when the user has answered the dialog before and `shouldShowRequestPermissionRationale` is false.
- Approximate-only permission counts as granted and uses balanced accuracy.
- The channel contract has nothing Android-specific in it. iOS isn't implemented, so the call throws `MissingPluginException`, which becomes `LocationUnsupportedException`. Adding a Swift side later needs no Dart changes.

Permission is only asked after the user taps "Use my location", not on launch.

## When there's no location

I didn't want to block routing. Every location error sheet has "Pick start point on map". In that mode the first long-press sets the start (A) and the second sets the destination (B). `RouteController` reads the start through one `startPoint` getter, so the rest of the routing code is the same. If GPS shows up later it doesn't replace a start the user picked. They go back with "Try using my location again".

## Routing

- Requests are debounced (600 ms) and spaced at least 1 s apart, because the public OSRM server is rate limited.
- Each request gets an id. A response whose id isn't the latest is dropped, so an old slow response can't overwrite a newer route.
- 10 s timeout. After 3 s the sheet says the server is slow.
- OSRM snaps a point to the nearest road even if that's far away (sea, islands). If the destination had to move more than 500 m, I show "No drivable route" instead of a route that stops short.

## Interpolation and bearing

`RouteAnimator` works on distance, not on point index:

1. Drop repeated points and points closer than 0.5 m to the previous one (avoids zero-length segments and NaN).
2. Build a cumulative distance list with haversine.
3. For a travelled distance, binary-search the segment, then lerp between its two points.

Each frame the simulator adds `speed × multiplier × dt`. Because it moves by metres, the car's speed stays the same whether points are dense or sparse. `dt` is capped at 100 ms so a slow frame or returning from background can't make the car jump. 1x is the average speed from OSRM (distance / duration), so "time left" matches OSRM's estimate.

Bearing is the segment direction from `atan2`. The displayed heading eases toward it with `1 - e^(-8·dt)`, using the shortest signed difference `((to - from + 540) % 360) - 180`, so 359° to 1° turns +2° instead of spinning around.

`NavigationController` owns a `Ticker` that only runs while driving. The drive pauses when the app is hidden and waits for the user to press Resume.

## Flavors

Android `productFlavors` `dev` and `prod`. Dev has `applicationIdSuffix ".dev"` and its own `app_name` through `resValue`, so both install side by side. In Dart, `FlavorConfig` reads Flutter's `appFlavor` and holds the routing base URL, so switching servers is a config change. Dev shows a red DEV banner. Running without `--flavor` fails on purpose.

## Before production

- **Routing server:** the public OSRM demo isn't meant for real traffic. I'd self-host OSRM (or use a paid provider, with the key kept on our backend) and put a small cache in front of it.
- **Map tiles:** the OSM tile policy doesn't allow heavy app use either. I'd use a tile provider or our own tiles, plus an offline cache.
- **Battery:** use a longer interval and balanced accuracy when not navigating, and only go high accuracy during a drive.
- **Background location:** real navigation needs a foreground service with a notification and background permission, which also means dealing with Play Store policy.
- **Cost at scale:** route requests grow with users. Caching common routes and rate limiting per user would matter.

## Left out

- iOS (Swift + CoreLocation) and iOS flavors
- Live GPS mode, snap-to-route, off-route rerouting
- Navigation camera that rotates with the car
- Widget/integration tests for the full screen. Tests cover the logic, the services and the controllers.
