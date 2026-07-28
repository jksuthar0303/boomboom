// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:video_player/video_player.dart';
//
// import '../constant/appsize.dart';
// import 'onboarding.dart';
//
//
//
//
//
// class SplashController extends GetxController {
//   var isLoaded = false.obs;
// }
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   late VideoPlayerController controller;
//   final splashController = Get.find<SplashController>();
//
//   bool isNavigated = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     controller = VideoPlayerController.asset("assets/boomlogo.mp4")
//       ..initialize().then((_) {
//         setState(() {});
//         controller.play();
//       });
//
//     controller.addListener(() {
//       if (!isNavigated &&
//           controller.value.isInitialized &&
//           controller.value.position >= controller.value.duration) {
//
//         isNavigated = true;
//
//         /// 🔥 Direct navigation (NO ROUTES)
//         Get.to(
//               () => const OnboardingScreen(),
//           transition: Transition.fadeIn, // 🔥 smooth
//           duration: const Duration(milliseconds: 800),
//         );
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: controller.value.isInitialized
//             ? Container(
//           width: AppSize.w(400),
//           height: AppSize.h(200),
//           child: VideoPlayer(controller),
//         )
//             : const CircularProgressIndicator(color: Colors.white),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import 'onboarding.dart';
import 'welcomscreens.dart';
import '../backend/secure_storage.dart';
import '../backend/registerservice.dart';
import '../screens/bottombar.dart';
import '../controller/auth_controller.dart';

// class SplashController extends GetxController {
//   var isLoaded = false.obs;
// }
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   late VideoPlayerController controller;
//   bool isNavigated = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     controller = VideoPlayerController.asset("assets/boomlogo.mp4")
//       ..initialize().then((_) {
//         setState(() {});
//
//         // 🔥 IMPORTANT SETTINGS
//         controller.setVolume(0);
//         controller.setLooping(false);
//
//         controller.play();
//       });
//
//     controller.addListener(() {
//       if (!isNavigated &&
//           controller.value.isInitialized &&
//           controller.value.position >= controller.value.duration) {
//
//         isNavigated = true;
//
//         Get.off(
//               () => const OnboardingScreen(),
//           transition: Transition.fadeIn,
//           duration: const Duration(milliseconds: 600),
//         );
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: controller.value.isInitialized
//             ? AspectRatio(
//           aspectRatio: controller.value.aspectRatio,
//           child: FittedBox(
//             fit: BoxFit.contain, // 🔥 FIX BLUR + STRETCH
//             child: SizedBox(
//               width: controller.value.size.width,
//               height: controller.value.size.height,
//               child: VideoPlayer(controller),
//             ),
//           ),
//         )
//             : const CircularProgressIndicator(
//           color: Colors.white,
//         ),
//       ),
//     );
//   }
// }

class SplashController extends GetxController {
  var isLoaded = false.obs;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? controller;
  Timer? videoSafetyTimer;

  bool isNavigated = false;

  @override
  void initState() {
    super.initState();
    startSplashVideo();
  }

  Future<void> startSplashVideo() async {
    try {
      final videoController = VideoPlayerController.asset(
        "assets/boomlogo.mp4",
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        // New converted video use karoge to:
        // "assets/boomlogo_fixed.mp4",
      );

      controller = videoController;

      // Video 7 seconds mein initialize na ho to app stuck nahi hogi.
      await videoController.initialize().timeout(const Duration(seconds: 7));

      if (!mounted || isNavigated) return;

      await videoController.setVolume(0);
      await videoController.setLooping(false);

      videoController.addListener(checkVideoStatus);

      setState(() {});

      await videoController.play();

      // Video freeze ho jaye to duration ke 2 sec baad onboarding open hogi.
      final duration = videoController.value.duration;

      if (duration != Duration.zero) {
        videoSafetyTimer = Timer(
          duration + const Duration(seconds: 2),
          goToOnboarding,
        );
      } else {
        videoSafetyTimer = Timer(const Duration(seconds: 8), goToOnboarding);
      }
    } catch (e) {
      debugPrint("Splash video error: $e");

      // Video fail ho to black screen par stuck nahi hogi.
      Future.delayed(const Duration(milliseconds: 500), () {
        goToOnboarding();
      });
    }
  }

  void checkVideoStatus() {
    final videoController = controller;

    if (videoController == null || isNavigated) return;

    final value = videoController.value;

    // Codec/video error aaya to next screen khul jayegi.
    if (value.hasError) {
      debugPrint("Video playback error: ${value.errorDescription}");
      goToOnboarding();
      return;
    }

    // Video complete hone par normal navigation.
    if (value.isInitialized &&
        value.duration != Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 150)) {
      goToOnboarding();
    }
  }

  void goToOnboarding() async {
    if (isNavigated || !mounted) return;

    isNavigated = true;
    videoSafetyTimer?.cancel();

    final storedEmail = await SecureStorage().getUserEmail();

    if (storedEmail != null && storedEmail.isNotEmpty) {
      bool hasLocation = false;
      Position? position;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 3),
            );
            hasLocation = true;
          }
        }
      } catch (e) {
        debugPrint("[Splash] Location check failed on startup: $e");
      }

      bool hasCachedLocation = false;
      try {
        final profileJsonStr = await SecureStorage().getProfileJson();
        if (profileJsonStr != null && profileJsonStr.isNotEmpty) {
          final decoded = jsonDecode(profileJsonStr);
          final List? dataList = decoded["Data"];
          if (dataList != null && dataList.isNotEmpty) {
            final data = dataList.first;
            final lat = data["Lat"]?.toString() ?? "";
            final lon = data["Lon"]?.toString() ?? "";
            if (lat.isNotEmpty &&
                lat != "0" &&
                lat != "0.0" &&
                lon.isNotEmpty &&
                lon != "0" &&
                lon != "0.0") {
              hasCachedLocation = true;
            }
          }
        }
      } catch (e) {
        debugPrint("[Splash] Cached location check failed: $e");
      }

      if (!hasLocation && !hasCachedLocation) {
        debugPrint(
          "[Splash] Lat/Lng is not there and no cached location, sending user back.",
        );
        Get.offAll(
          () => WelcomeScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 600),
        );
        return;
      }

      // Lat/Lng is present, call UpdateLatLon API if we got a new position
      if (position != null) {
        try {
          await RegisterService().updateLatLon(
            email: storedEmail,
            lat: position.latitude.toString(),
            lon: position.longitude.toString(),
          );
          debugPrint("[Splash] Location auto-updated via API successfully.");
        } catch (e) {
          debugPrint("[Splash] Location auto-update API call failed: $e");
        }
      }

      try {
        await AuthController().fetchAndStoreFullProfile(email: storedEmail);
        debugPrint(
          "[Splash] Pre-fetched and stored complete profile successfully.",
        );
      } catch (e) {
        debugPrint("[Splash] Pre-fetch profile error: $e");
      }

      Get.offAll(
        () => const MainScreen(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 600),
      );
    } else {
      Get.offAll(
        () => const OnboardingScreen(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 600),
      );
    }
  }

  @override
  void dispose() {
    videoSafetyTimer?.cancel();

    controller?.removeListener(checkVideoStatus);
    controller?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideoReady = controller?.value.isInitialized ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: isVideoReady
            ? AspectRatio(
                aspectRatio: controller!.value.aspectRatio,
                child: VideoPlayer(controller!),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
