import 'package:get/get.dart';

import 'authentication/splash.dart';


class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SplashController()); // 🔥 controller inject
  }
}