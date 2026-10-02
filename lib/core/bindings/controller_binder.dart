import 'package:get/get.dart';

import '../config/flavor_config.dart';

class ControllerBinder extends Bindings {
  @override
  void dependencies() {
    Get.put<FlavorConfig>(FlavorConfig.fromAppFlavor(), permanent: true);
  }
}
