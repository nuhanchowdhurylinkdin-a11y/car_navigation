import 'package:car_navigation/features/location/models/location_exception.dart';
import 'package:car_navigation/features/location/models/location_permission_status.dart';
import 'package:car_navigation/features/location/services/native_location_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/location');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final service = NativeLocationService(methodChannel: channel);

  void mockNative(Future<Object?> Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, handler);
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('parses a location fix', () async {
    MethodCall? received;
    mockNative((call) async {
      received = call;
      return {
        'lat': 23.81,
        'lng': 90.41,
        'accuracy': 8.0,
        'bearing': 0.0,
        'speed': 0.0,
        'timestamp': 1700000000000,
        'isPrecise': true,
      };
    });

    final fix = await service.getCurrentLocation(timeout: const Duration(seconds: 5));

    expect(fix.latitude, 23.81);
    expect(fix.longitude, 90.41);
    expect(received?.arguments, {'timeoutMs': 5000});
  });

  test('parses permission status strings', () async {
    mockNative((_) async => 'deniedForever');
    expect(await service.checkPermission(), LocationPermissionStatus.deniedForever);
  });

  final errorCases = <String, Matcher>{
    'PERMISSION_DENIED': isA<PermissionDeniedException>(),
    'PERMISSION_DENIED_FOREVER': isA<PermissionDeniedForeverException>(),
    'SERVICE_DISABLED': isA<LocationServiceDisabledException>(),
    'TIMEOUT': isA<LocationTimeoutException>(),
    'SOMETHING_ELSE': isA<LocationUnknownException>(),
  };

  errorCases.forEach((code, matcher) {
    test('maps native error $code to a typed exception', () async {
      mockNative((_) async => throw PlatformException(code: code, message: 'x'));
      await expectLater(service.getCurrentLocation(), throwsA(matcher));
    });
  });

  test('reports unsupported when no native handler exists', () async {
    await expectLater(service.checkPermission(), throwsA(isA<LocationUnsupportedException>()));
  });
}
