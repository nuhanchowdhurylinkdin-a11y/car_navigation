import 'package:get/get.dart';

import '../../features/home/controller/home_controller.dart';
import '../../features/location/controller/location_controller.dart';
import '../../features/location/services/location_service.dart';
import '../../features/location/services/native_location_service.dart';
import '../config/flavor_config.dart';

class ControllerBinder extends Bindings {
  @override
  void dependencies() {
    Get.put<FlavorConfig>(FlavorConfig.fromAppFlavor(), permanent: true);

    Get.lazyPut<LocationService>(() => NativeLocationService(), fenix: true);
    Get.lazyPut<LocationController>(
      () => LocationController(Get.find<LocationService>()),
      fenix: true,
    );
    Get.lazyPut<HomeController>(
      () => HomeController(Get.find<LocationController>()),
      fenix: true,
    );
  }
}
