import 'package:get/get.dart';

/// 🔥 YE CONTROLLER DONO SCREENS KO CONNECT KARTA HAI
/// NotificationSettings → HomeScreen
/// Jab toggle ON ho → HomeScreen pe chatted users hide ho jaate hain

class AppSettingsController extends GetxController {
  static AppSettingsController get to => Get.find();

  /// true = hide users who have been messaged
  final RxBool hideChatUsers = false.obs;

  final ghostMode = false.obs;

}