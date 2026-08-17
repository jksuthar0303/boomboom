import 'package:get/get.dart';

import 'authentication/splash.dart';
import 'controller/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SplashController());
    Get.put(AuthController(), permanent: true);
  }
}