import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:xml/xml.dart' as xml;
import '../backend/registerservice.dart';
import '../backend/secure_storage.dart';
import '../screens/bottombar.dart';
import '../widget/snakbar.dart';
import '../constant/appconstants.dart';

class AuthController extends GetxController {
  final RegisterService _registerService = RegisterService();

  final RxBool isLoading = false.obs;
  final RxString loadingMessage = "".obs;
  final RxDouble uploadProgress = 0.0.obs;

  /// 1. Unified method to fetch profile, interests, lifestyle, and media, and store the merged JSON
  Future<void> fetchAndStoreFullProfile({required String email}) async {
    try {
      final response = await _registerService.showCompleteProfile(email: email);
      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        final res = doc.findAllElements('ShowCompleteProfileResult');
        if (res.isNotEmpty) {
          final String jsonProfileStr = res.first.innerText;
          final Map<String, dynamic> profileJson = jsonDecode(jsonProfileStr);
          final int status = profileJson["Status"] ?? 0;

          if (status == 1 && profileJson["ResultSets"] is List) {
            final List resultSets = profileJson["ResultSets"];
            if (resultSets.length >= 5) {
              // ResultSet 1: Profile details
              final List profileList = resultSets[1];
              if (profileList.isNotEmpty) {
                final Map<String, dynamic> data = Map<String, dynamic>.from(
                  profileList.first,
                );

                // ResultSet 2: Media
                final List mediaList = resultSets[2];
                final List<Map<String, dynamic>> mediaItems = [];
                for (var item in mediaList) {
                  final url = item["Media"] ?? item["MediaName"];
                  final type = item["Type"] ?? "image";
                  if (url != null && url.toString().isNotEmpty) {
                    mediaItems.add({
                      "Url": url.toString(),
                      "Type": type.toString(),
                    });
                  }
                }
                if (mediaItems.isNotEmpty) {
                  data["Media"] = mediaItems;
                }

                // ResultSet 3: Interests
                final List interestsList = resultSets[3];
                final List<String> interests = [];
                final Map<String, int> interestMap = {};
                for (var item in interestsList) {
                  final String rawName = (item["Interest"] ?? "")
                      .toString()
                      .trim();
                  final String matchedName =
                      AppConstants.findMatchingInterest(rawName) ?? rawName;
                  final int? id = int.tryParse(
                    item["id"]?.toString() ?? item["Id"]?.toString() ?? "",
                  );
                  if (matchedName.isNotEmpty) {
                    interests.add(matchedName);
                    if (id != null) {
                      interestMap[matchedName] = id;
                    }
                  }
                }
                data["Interests"] = interests;
                await SecureStorage().saveInterestMap(jsonEncode(interestMap));

                // ResultSet 4: Lifestyle
                final List lifestyleList = resultSets[4];
                final List<String> lifestyle = [];
                for (var item in lifestyleList) {
                  final String val = (item["LifeStyle"] ?? "")
                      .toString()
                      .trim();
                  if (val.isNotEmpty) {
                    lifestyle.add(val);
                  }
                }
                data["Lifestyle"] = lifestyle;

                // Save the merged data JSON back to SecureStorage
                final Map<String, dynamic> combinedMap = {
                  "Data": [data],
                  "Status": 1,
                };
                final String combinedJsonStr = jsonEncode(combinedMap);
                await SecureStorage().saveProfileJson(combinedJsonStr);
                debugPrint(
                  "Persisted combined user profile details from ShowCompleteProfile: $combinedJsonStr",
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint(
        "Error fetching and storing full profile via ShowCompleteProfile: $e",
      );
    }
  }

  /// 2. LOGIN API
  Future<void> login({required String email, required String password}) async {
    if (email.trim().isEmpty) {
      NeuSnackbar.error("Please enter your email");
      return;
    }
    if (password.trim().isEmpty) {
      NeuSnackbar.error("Please enter password");
      return;
    }

    isLoading.value = true;

    try {
      final response = await _registerService.login(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final resultElements = document.findAllElements('LoginResult');

        if (resultElements.isNotEmpty) {
          final String jsonResultStr = resultElements.first.innerText;
          debugPrint("[Login XML Result parsed]: $jsonResultStr");

          try {
            final Map<String, dynamic> resultJson = jsonDecode(jsonResultStr);
            final int status = resultJson["Status"] ?? 0;
            final String message =
                resultJson["Message"] ?? "An error occurred during login.";

            if (status == 1) {
              // Save credentials to SecureStorage to persist login
              await SecureStorage().saveUserEmail(email.trim());
              await SecureStorage().saveUserPassword(password.trim());

              // Fetch and store complete profile JSON (with Interests, Lifestyle, Media)
              await fetchAndStoreFullProfile(email: email.trim());

              NeuSnackbar.success("Login Successfully");

              Get.offAll(
                () => const MainScreen(),
                transition: Transition.rightToLeftWithFade,
                duration: const Duration(milliseconds: 600),
              );
            } else {
              NeuSnackbar.error(message);
            }
          } catch (e) {
            debugPrint("[Login JSON Parse Error]: $e");
            NeuSnackbar.error("Invalid response format from server.");
          }
        } else {
          NeuSnackbar.error("No response payload from server.");
        }
      } else {
        debugPrint("[SOAP Login Error Response]: HTTP ${response.statusCode}");
        NeuSnackbar.error(
          "Failed to login. Server returned ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("[SOAP Login Connection Exception]: $e");
      NeuSnackbar.error(e.toString().replaceAll("Exception: ", ""));
    } finally {
      isLoading.value = false;
    }
  }

  /// 3. REGISTER WIZARD SUBMIT API
  Future<void> register({
    required String email,
    required String fullName,
    required String dob,
    required String password,
    required String bio,
    required String gender,
    required String lookingFor,
    required String orientation,
    required String occupation,
    required String height,
    required String bodyType,
    required String drinkingHabits,
    required String workout,
    required List<String> interests,
    required List<File> photos,
    required List<File> videos,
  }) async {
    isLoading.value = true;
    loadingMessage.value = "Registering your account...";
    uploadProgress.value = 0.0;

    // Fetch location coordinates best-effort
    String lat = "0.0";
    String lon = "0.0";
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 3),
      );
      lat = position.latitude.toString();
      lon = position.longitude.toString();
    } catch (e) {
      debugPrint("[API Location Request Error]: $e");
    }

    try {
      final response = await _registerService.registerInsert(
        email: email,
        fullName: fullName,
        dob: dob,
        password: password,
        bio: bio,
        gender: gender,
        lookingFor: lookingFor,
        orientation: orientation,
        occupation: occupation,
        lat: lat,
        lon: lon,
        height: height,
        bodyType: bodyType,
        drinkingHabits: drinkingHabits,
        workout: workout,
      );

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final resultElements = document.findAllElements('RegisterInsertResult');

        if (resultElements.isNotEmpty) {
          final String jsonResultStr = resultElements.first.innerText;
          debugPrint("[RegisterInsert XML Result parsed]: $jsonResultStr");

          try {
            final Map<String, dynamic> resultJson = jsonDecode(jsonResultStr);
            final int status = resultJson["Status"] ?? 0;
            final String message =
                resultJson["Message"] ??
                "An error occurred during registration.";

            if (status == 1) {
              // 1. Call InterestInsert API for each interest selected
              for (var interest in interests) {
                try {
                  await _registerService.interestInsert(
                    email: email,
                    interest: interest,
                  );
                  debugPrint("[InterestInsert] Inserted: $interest");
                } catch (e) {
                  debugPrint("[InterestInsert Error]: $e");
                }
              }

              // 2. Call LifestyleInsert API for each selected lifestyle item
              final List<String> lifestyleItems = [
                "Drinking: $drinkingHabits",
                "Workout: $workout",
                "BodyType: $bodyType",
                "Height: $height",
              ];
              for (var lifestyle in lifestyleItems) {
                try {
                  await _registerService.lifestyleInsert(
                    email: email,
                    lifestyle: lifestyle,
                  );
                  debugPrint("[LifestyleInsert] Inserted: $lifestyle");
                } catch (e) {
                  debugPrint("[LifestyleInsert Error]: $e");
                }
              }

              // 3. Sequential Media Upload (Photos/Videos)
              final int totalFiles = photos.length + videos.length;
              int currentFileIndex = 0;

              // Upload photos
              for (var file in photos) {
                currentFileIndex++;
                try {
                  final bytes = await file.readAsBytes();
                  final base64Str = base64Encode(bytes);

                  loadingMessage.value =
                      "Uploading photo $currentFileIndex of $totalFiles...";
                  uploadProgress.value = 0.0;

                  final mediaResponse = await _registerService.mediaInsert(
                    email: email,
                    mediaBase64: base64Str,
                    type: "image",
                    onSendProgress: (sent, total) {
                      if (total > 0) {
                        uploadProgress.value = sent / total;
                      }
                    },
                  );

                  debugPrint(
                    "[MediaInsert Photo Status]: ${mediaResponse.statusCode}",
                  );
                  if (mediaResponse.statusCode != 200) {
                    throw Exception("Status ${mediaResponse.statusCode}");
                  }

                  final doc = xml.XmlDocument.parse(mediaResponse.body);
                  final res = doc.findAllElements('MediaInsertResult');
                  if (res.isNotEmpty) {
                    final jsonStr = res.first.innerText;
                    final resJson = jsonDecode(jsonStr);
                    if ((resJson["Status"] ?? 0) != 1) {
                      throw Exception(resJson["Message"] ?? "Upload failed");
                    }
                  }
                } catch (e) {
                  debugPrint("[MediaInsert Photo Error]: $e");
                  NeuSnackbar.error(
                    "Photo $currentFileIndex upload failed: $e",
                  );
                }
              }

              // Upload videos
              for (var file in videos) {
                currentFileIndex++;
                try {
                  final bytes = await file.readAsBytes();
                  final base64Str = base64Encode(bytes);

                  loadingMessage.value =
                      "Uploading video $currentFileIndex of $totalFiles...";
                  uploadProgress.value = 0.0;

                  final mediaResponse = await _registerService.mediaInsert(
                    email: email,
                    mediaBase64: base64Str,
                    type: "video",
                    onSendProgress: (sent, total) {
                      if (total > 0) {
                        uploadProgress.value = sent / total;
                      }
                    },
                  );

                  debugPrint(
                    "[MediaInsert Video Status]: ${mediaResponse.statusCode}",
                  );
                  if (mediaResponse.statusCode != 200) {
                    throw Exception("Status ${mediaResponse.statusCode}");
                  }

                  final doc = xml.XmlDocument.parse(mediaResponse.body);
                  final res = doc.findAllElements('MediaInsertResult');
                  if (res.isNotEmpty) {
                    final jsonStr = res.first.innerText;
                    final resJson = jsonDecode(jsonStr);
                    if ((resJson["Status"] ?? 0) != 1) {
                      throw Exception(resJson["Message"] ?? "Upload failed");
                    }
                  }
                } catch (e) {
                  debugPrint("[MediaInsert Video Error]: $e");
                  NeuSnackbar.error("Video upload failed: $e");
                }
              }

              // Save credentials to keep logged in
              await SecureStorage().saveUserEmail(email);
              await SecureStorage().saveUserPassword(password);

              // Fetch and store complete profile JSON (with Interests, Lifestyle, Media)
              await fetchAndStoreFullProfile(email: email);

              NeuSnackbar.success(
                "Profile registration completed successfully!",
              );

              // Navigate to Main Screen (Bottom Bar) and clear flow
              Get.offAll(
                () => const MainScreen(),
                transition: Transition.rightToLeftWithFade,
                duration: const Duration(milliseconds: 600),
              );
            } else {
              NeuSnackbar.error(message);
            }
          } catch (e) {
            debugPrint("[RegisterInsert JSON Parse Error]: $e");
            NeuSnackbar.error("Invalid response format from server.");
          }
        } else {
          NeuSnackbar.error("No result payload returned from server.");
        }
      } else {
        debugPrint("[SOAP Error Response]: HTTP status ${response.statusCode}");
        NeuSnackbar.error(
          "Failed to register. Server returned code ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("[SOAP Connection Exception]: $e");
      NeuSnackbar.error(e.toString().replaceAll("Exception: ", ""));
    } finally {
      isLoading.value = false;
    }
  }

  /// 4. UPDATE PASSWORD API
  Future<void> updatePassword({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty) {
      NeuSnackbar.error("Please enter your email");
      return;
    }
    if (password.isEmpty) {
      NeuSnackbar.error("Please enter new password");
      return;
    }

    isLoading.value = true;

    try {
      final response = await _registerService.forgotPassword(
        email: email.trim(),
        newPassword: password.trim(),
      );

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final resultElements = document.findAllElements('ForgotPasswordResult');

        if (resultElements.isNotEmpty) {
          final String jsonResultStr = resultElements.first.innerText;
          debugPrint("[ForgotPassword XML Result parsed]: $jsonResultStr");

          try {
            final Map<String, dynamic> resultJson = jsonDecode(jsonResultStr);
            final int status = resultJson["Status"] ?? 0;
            final String message =
                resultJson["Message"] ?? "An error occurred.";

            if (status == 1) {
              NeuSnackbar.success("Password Updated Successfully");
              Get.back();
            } else {
              NeuSnackbar.error(message);
            }
          } catch (e) {
            debugPrint("[ForgotPassword JSON Parse Error]: $e");
            NeuSnackbar.error("Invalid response format from server.");
          }
        } else {
          NeuSnackbar.error("No response payload from server.");
        }
      } else {
        debugPrint(
          "[SOAP ForgotPassword Error Response]: HTTP ${response.statusCode}",
        );
        NeuSnackbar.error(
          "Failed to update password. Server returned ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("[SOAP ForgotPassword Connection Exception]: $e");
      NeuSnackbar.error(e.toString().replaceAll("Exception: ", ""));
    } finally {
      isLoading.value = false;
    }
  }
}
