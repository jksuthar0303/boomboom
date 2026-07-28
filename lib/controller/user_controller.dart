import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xml/xml.dart' as xml;
import '../backend/registerservice.dart';
import '../backend/secure_storage.dart';
import '../authentication/welcomscreens.dart';
import '../widget/snakbar.dart';

import 'auth_controller.dart';

class UserController extends GetxController {
  final RegisterService _registerService = RegisterService();

  final RxBool isLoading = false.obs;

  // Profile Update Fields
  final RxString fullName = "".obs;
  final RxString emailAddress = "".obs;
  final RxString dob = "".obs;
  final RxString gender = "".obs;
  final RxString lookingFor = "".obs;
  final RxString orientation = "".obs;
  final RxString bio = "".obs;
  final RxString occupation = "".obs;
  final RxString height = "".obs;
  final RxString bodyType = "".obs;
  final RxString drinkingHabits = "".obs;
  final RxString workout = "".obs;

  Future<void> initializeProfileFields() async {
    try {
      final jsonStr = await SecureStorage().getProfileJson();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        final List? dataList = decoded["Data"];
        if (dataList != null && dataList.isNotEmpty) {
          final data = dataList.first;
          fullName.value = data["FullName"] ?? "";
          emailAddress.value = data["EmailAddress"] ?? "";
          dob.value = data["Dob"] ?? "";
          gender.value = data["Gender"] ?? "";
          lookingFor.value = data["Lookingfor"] ?? "";
          orientation.value = data["Orientation"] ?? "";
          bio.value = data["BIO"] ?? "";
          occupation.value = data["Occupation"] ?? "";
          height.value = data["Height"] ?? "";
          bodyType.value = data["BodyType"] ?? "";
          drinkingHabits.value = data["DrinkingHabits"] ?? "";
          workout.value = data["Workout"] ?? "";
        }
      }
    } catch (e) {
      debugPrint("Error loading profile fields in UserController: $e");
    }
  }

  Future<bool> saveProfile() async {
    isLoading.value = true;
    try {
      final email = await SecureStorage().getUserEmail() ?? "";
      if (email.isEmpty) {
        NeuSnackbar.error("Session expired. Please log in again.");
        return false;
      }

      final response = await _registerService.updateProfile(
        email: email,
        fullName: fullName.value.trim(),
        dob: dob.value.trim(),
        gender: gender.value.trim(),
        lookingFor: lookingFor.value.trim(),
        orientation: orientation.value.trim(),
        bio: bio.value.trim(),
        occupation: occupation.value.trim(),
        height: height.value.trim(),
        bodyType: bodyType.value.trim(),
        drinkingHabits: drinkingHabits.value.trim(),
        workout: workout.value.trim(),
      );

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final resultElements = document.findAllElements('UpdateProfileResult');

        if (resultElements.isNotEmpty) {
          final String jsonResultStr = resultElements.first.innerText;
          final Map<String, dynamic> resultJson = jsonDecode(jsonResultStr);
          final int status = resultJson["Status"] ?? 0;
          final String message = resultJson["Message"] ?? "An error occurred.";

          if (status == 1) {
            // 🚀 Update the local SecureStorage cache IMMEDIATELY so the UI refreshes without delay
            try {
              final jsonStr = await SecureStorage().getProfileJson();
              if (jsonStr != null && jsonStr.isNotEmpty) {
                final decoded = jsonDecode(jsonStr);
                final List? dataList = decoded["Data"];
                if (dataList != null && dataList.isNotEmpty) {
                  final Map<String, dynamic> data = Map<String, dynamic>.from(
                    dataList.first,
                  );
                  data["FullName"] = fullName.value.trim();
                  data["Dob"] = dob.value.trim();
                  data["Gender"] = gender.value.trim();
                  data["Lookingfor"] = lookingFor.value.trim();
                  data["Orientation"] = orientation.value.trim();
                  data["BIO"] = bio.value.trim();
                  data["Occupation"] = occupation.value.trim();
                  data["Height"] = height.value.trim();
                  data["BodyType"] = bodyType.value.trim();
                  data["DrinkingHabits"] = drinkingHabits.value.trim();
                  data["Workout"] = workout.value.trim();

                  decoded["Data"] = [data];
                  await SecureStorage().saveProfileJson(jsonEncode(decoded));
                }
              }
            } catch (cacheErr) {
              debugPrint(
                "Error updating local cache in saveProfile: $cacheErr",
              );
            }

            // 🚀 Trigger complete profile sync from server in the background
            final authCtrl = Get.put(AuthController());
            authCtrl.fetchAndStoreFullProfile(email: email).catchError((e) {
              debugPrint("Background profile sync error: $e");
            });

            NeuSnackbar.success("Profile updated successfully!");
            return true;
          } else {
            NeuSnackbar.error(message);
          }
        } else {
          NeuSnackbar.error("Invalid server response format.");
        }
      } else {
        NeuSnackbar.error("Server returned error: HTTP ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("UpdateProfile API Error: $e");
      NeuSnackbar.error("Failed to update profile: $e");
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  /// 1. DELETE ACCOUNT API
  Future<void> deleteAccount(BuildContext context) async {
    // Show progress loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.red)),
    );

    isLoading.value = true;

    try {
      final email = await SecureStorage().getUserEmail() ?? "";
      final password = await SecureStorage().getUserPassword() ?? "";

      if (email.isEmpty || password.isEmpty) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // close loader
        NeuSnackbar.error(
          "Session credentials not found. Please log out and try again.",
        );
        return;
      }

      final response = await _registerService.deleteAccount(
        email: email,
        password: password,
      );

      // ignore: use_build_context_synchronously
      Navigator.pop(context); // close loader

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final resultElements = document.findAllElements('DeleteAccountResult');

        if (resultElements.isNotEmpty) {
          final String jsonResultStr = resultElements.first.innerText;
          final Map<String, dynamic> resultJson = jsonDecode(jsonResultStr);
          final int status = resultJson["Status"] ?? 0;
          final String message = resultJson["Message"] ?? "An error occurred.";

          if (status == 1) {
            await SecureStorage().clearAll();
            NeuSnackbar.success("Account deleted successfully.");
            Get.offAll(() => WelcomeScreen());
          } else {
            NeuSnackbar.error(message);
          }
        } else {
          NeuSnackbar.error("Invalid server response format.");
        }
      } else {
        NeuSnackbar.error("Server returned error: HTTP ${response.statusCode}");
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context); // close loader
      debugPrint("DeleteAccount API Error: $e");
      NeuSnackbar.error("Failed to delete account: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
