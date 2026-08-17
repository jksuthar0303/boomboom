import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'backend/fcm_service.dart';
import 'authentication/internet/networkwrapper.dart';
import 'authentication/internet/nointernetcontroller.dart';
import 'authentication/splash.dart';
import 'bindings.dart';
import 'controller/appsetting.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
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
