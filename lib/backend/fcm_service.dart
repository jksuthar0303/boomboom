import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'registerservice.dart';
import 'secure_storage.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize FCM, request notification permissions, and store token
  Future<void> initialize() async {
    try {
      // 1. Request Notification Permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        '[FCMService] Notification authorization status: ${settings.authorizationStatus}',
      );

      // 2. Fetch FCM Token
      String? token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('[FCMService] Device FCM Token: $token');
        await SecureStorage().saveFcmToken(token);

        // If user is already logged in, update on server right away
        final String? email = await SecureStorage().getUserEmail();
        if (email != null && email.isNotEmpty) {
          await updateFCMTokenOnServer(email: email, fcmToken: token);
        }
      }

      // 3. Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('[FCMService] FCM Token Refreshed: $newToken');
        await SecureStorage().saveFcmToken(newToken);
        final String? email = await SecureStorage().getUserEmail();
        if (email != null && email.isNotEmpty) {
          await updateFCMTokenOnServer(email: email, fcmToken: newToken);
        }
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
}
