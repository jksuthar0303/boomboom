import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constant/apptextstyle.dart';
import '../constant/colors.dart';

class PermissionService {
  static Future<bool> isNotificationGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }

  static Future<bool> isLocationGranted() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      debugPrint("[PermissionService] isLocationGranted error: $e");
      return false;
    }
  }

  static Future<PermissionStatus> requestNotificationPermission({
    bool showRationaleOnPermanentlyDenied = true,
  }) async {
    PermissionStatus status;
    try {
      status = await Permission.notification.status;
      debugPrint(
        "[PermissionService] Notification current status: ${status.name}",
      );

      if (status.isGranted || status.isLimited) {
        return status;
      }

      if (status.isPermanentlyDenied) {
        if (showRationaleOnPermanentlyDenied) {
          await _showPermissionSettingsDialog(
            title: "Enable Notifications",
            message:
                "You have permanently denied notification permission. Please enable it from app settings to receive match alerts, messages and event updates.",
          );
          status = await Permission.notification.status;
        }
        return status;
      }

      status = await Permission.notification.request();
      debugPrint(
        "[PermissionService] Notification after request: ${status.name}",
      );

      if (status.isPermanentlyDenied && showRationaleOnPermanentlyDenied) {
        await _showPermissionSettingsDialog(
          title: "Enable Notifications",
          message:
              "Notification permission is permanently denied. Open settings and allow notifications to stay updated.",
        );
      }
    } catch (e) {
      debugPrint("[PermissionService] Notification request error: $e");
      return PermissionStatus.denied;
    }
    return status;
  }

  static Future<LocationPermission> requestLocationPermission({
    bool showRationaleOnPermanentlyDenied = true,
  }) async {
    LocationPermission permission;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("[PermissionService] Location service DISABLED");
        final open = await _showLocationServiceDialog();
        if (open) {
          await Geolocator.openLocationSettings();
          await Future.delayed(const Duration(milliseconds: 800));
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            return LocationPermission.unableToDetermine;
          }
        } else {
          return LocationPermission.unableToDetermine;
        }
      }

      permission = await Geolocator.checkPermission();
      debugPrint(
        "[PermissionService] Location current permission: ${permission.name}",
      );

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return permission;
      }

      if (permission == LocationPermission.deniedForever) {
        if (showRationaleOnPermanentlyDenied) {
          await _showPermissionSettingsDialog(
            title: "Enable Location Access",
            message:
                "You have permanently denied location permission. Please enable it from app settings so we can show nearby people, events and matches on BoomBoom.",
          );
          permission = await Geolocator.checkPermission();
        }
        return permission;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint(
          "[PermissionService] Location after request: ${permission.name}",
        );
      }

      if (permission == LocationPermission.deniedForever &&
          showRationaleOnPermanentlyDenied) {
        await _showPermissionSettingsDialog(
          title: "Enable Location Access",
          message:
              "Location permission is permanently denied. Open app settings and allow location access to use the app properly.",
        );
      }
    } catch (e) {
      debugPrint("[PermissionService] Location request error: $e");
      return LocationPermission.unableToDetermine;
    }
    return permission;
  }

  static Future<void> _showPermissionSettingsDialog({
    required String title,
    required String message,
  }) async {
    return showDialog<void>(
      context: Get.context!,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.cardBorder),
          ),
          title: Text(
            title,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            message,
            style: AppTextStyles.small.copyWith(
              color: AppColors.grey,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                "Cancel",
                style: AppTextStyles.body.copyWith(color: AppColors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  await openAppSettings();
                } catch (e) {
                  debugPrint(
                    "[PermissionService] openAppSettings error: $e",
                  );
                }
              },
              child: Text(
                "Open Settings",
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFF9B59B6),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> _showLocationServiceDialog() async {
    final result = await showDialog<bool>(
      context: Get.context!,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.cardBorder),
          ),
          title: Text(
            "Turn On Location",
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            "Location services are disabled on your device. Please turn on GPS to find nearby matches and events.",
            style: AppTextStyles.small.copyWith(
              color: AppColors.grey,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                "Not Now",
                style: AppTextStyles.body.copyWith(color: AppColors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                "Turn On",
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFF9B59B6),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
