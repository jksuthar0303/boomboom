import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'registerservice.dart';
import 'secure_storage.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'boomboom_channel',
    'BoomBoom Notifications',
    description: 'Notifications for matches, messages, and events',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static const MethodChannel _soundChannel =
      MethodChannel('com.boomboom.dating/sound');

  static Future<void> playDeviceNotificationSound() async {
    try {
      await _soundChannel.invokeMethod('playNotificationSound');
    } catch (e) {
      debugPrint('[FCMService] playDeviceNotificationSound fallback: $e');
      SystemSound.play(SystemSoundType.alert);
    }
  }

  /// Initialize FCM & Local Notifications
  Future<void> initialize() async {
    try {
      // 1. Initialize FlutterLocalNotifications for Heads-Up Popups
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('🔔 [LocalNotification] Clicked: ${response.payload}');
        },
      );

      // Create High-Priority Notification Channel
      await localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 2. Request Notification Permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        '[FCMService] Notification authorization status: ${settings.authorizationStatus}',
      );

      // 2. Set presentation options for foreground
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Fetch FCM Token
      String? token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('🔥 [FCMService] Device FCM Token: $token');
        await SecureStorage().saveFcmToken(token);

        // If user is already logged in, update on server right away
        final String? email = await SecureStorage().getUserEmail();
        if (email != null && email.isNotEmpty) {
          await updateFCMTokenOnServer(email: email, fcmToken: token);
        }
      }

      // 4. Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('🔥 [FCMService] FCM Token Refreshed: $newToken');
        await SecureStorage().saveFcmToken(newToken);
        final String? email = await SecureStorage().getUserEmail();
        if (email != null && email.isNotEmpty) {
          await updateFCMTokenOnServer(email: email, fcmToken: newToken);
        }
      });

      // 5. Handle Foreground Notifications (When app is OPEN)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('🔔 [FCMService] Foreground message received: ${message.notification?.title} - ${message.notification?.body}');

        // 🔊 Play Real Device Notification Ringtone & Haptic
        try {
          await playDeviceNotificationSound();
          HapticFeedback.heavyImpact();
        } catch (_) {}

        final title = message.notification?.title ?? message.data['title'] ?? 'BoomBoom';
        final body = message.notification?.body ?? message.data['body'] ?? 'New notification received';
        final imageUrl = message.notification?.android?.imageUrl ?? message.data['image'] ?? message.data['imageUrl'];

        // Show ONLY ONE single elegant In-App Banner
        Get.snackbar(
          title,
          body,
          backgroundColor: const Color(0xFF161626),
          colorText: Colors.white,
          titleText: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          messageText: Text(
            body,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.white70,
            ),
          ),
          icon: Container(
            margin: EdgeInsets.only(left: 8.w),
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(
                color: const Color(0xFF00E5FF),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipOval(
              child: imageUrl != null && imageUrl.toString().isNotEmpty
                  ? Image.network(
                      imageUrl.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Padding(
                        padding: EdgeInsets.all(6.w),
                        child: Image.asset("assets/logos.png", fit: BoxFit.contain),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.all(6.w),
                      child: Image.asset(
                        "assets/logos.png",
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
          ),
          duration: const Duration(seconds: 5),
          snackPosition: SnackPosition.TOP,
          margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          borderRadius: 16.r,
          borderWidth: 1.2,
          borderColor: const Color(0xFF00E5FF).withValues(alpha: 0.3),
          boxShadows: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        );
      });

      // 6. Handle notification click when app opens from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 [FCMService] Notification opened from background: ${message.data}');
      });
    } catch (e) {
      debugPrint('[FCMService] Error initializing FCM: $e');
    }
  }

  /// Update FCM Token on server via SOAP API
  Future<void> updateFCMTokenOnServer({
    required String email,
    String? fcmToken,
  }) async {
    try {
      final token = fcmToken ?? await SecureStorage().getFcmToken();
      if (token != null && token.isNotEmpty && email.isNotEmpty) {
        final response = await RegisterService().updateFCMToken(
          email: email.trim(),
          fcmToken: token.trim(),
        );
        debugPrint(
          '[FCMService] UpdateFCMToken on server status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[FCMService] Error updating FCM token on server: $e');
    }
  }

  /// Show Heads-Up System Dropdown Notification (Background & Foreground)
  static Future<void> showHeadsUpNotification(RemoteMessage message) async {
    try {
      final title = message.notification?.title ?? message.data['title'] ?? 'BoomBoom';
      final body = message.notification?.body ?? message.data['body'] ?? 'New notification received';

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'boomboom_channel',
        'BoomBoom Notifications',
        channelDescription: 'Notifications for matches, messages, and events',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        playSound: true,
        enableVibration: true,
        fullScreenIntent: false,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await localNotifications.show(
        message.hashCode,
        title,
        body,
        notificationDetails,
        payload: message.data.toString(),
      );
    } catch (e) {
      debugPrint('[FCMService] Error showing Heads-Up notification: $e');
    }
  }
}
