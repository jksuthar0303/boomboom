import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'backend/fcm_service.dart';
import 'authentication/internet/networkwrapper.dart';
import 'authentication/internet/nointernetcontroller.dart';
import 'authentication/splash.dart';
import 'bindings.dart';
import 'controller/appsetting.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint(
      "🔔 [FCM Background Handler] Message: ${message.notification?.title ?? message.data}",
    );
    // If message does NOT have standard notification payload (data-only), show heads-up manually.
    // Standard notification messages are already displayed by Android system to avoid duplicates.
    if (message.notification == null) {
      await FCMService.showHeadsUpNotification(message);
    }
  } catch (e) {
    debugPrint("[FCM Background Handler Error]: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FCMService().initialize();
  } catch (e) {
    debugPrint("[Firebase Init Error]: $e");
  }

  Get.put(NetworkController());
  Get.put(AppSettingsController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Boom Boom',
          debugShowCheckedModeBanner: false,
          initialBinding: InitialBinding(),

          // 🔥 YAHI MAGIC HAI (GLOBAL WRAP)
          builder: (context, child) {
            return NetworkWrapper(child: child!);
          },

          home: const SplashScreen(),
        );
      },
    );
  }
}
