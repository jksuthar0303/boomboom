import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:xml/xml.dart' as xml;
import '../backend/home_service.dart';
import '../backend/secure_storage.dart';

class AppSettingsController extends GetxController {
  static AppSettingsController get to => Get.find();

  /// true = hide users who have been messaged
  final RxBool hideChatUsers = false.obs;

  final RxBool ghostMode = false.obs;
  final RxBool isLoadingSettings = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSettings();
  }

  Map<String, dynamic> _parseXmlBody(String body) {
    try {
      final doc = xml.XmlDocument.parse(body);
      final nodes = doc.findAllElements('ShowSettingsByEmailResult');
      if (nodes.isNotEmpty) {
        final text = nodes.first.innerText.trim();
        return Map<String, dynamic>.from(jsonDecode(text) as Map);
      }
    } catch (_) {}

    try {
      final start = body.indexOf('{');
      final end = body.lastIndexOf('}');
      if (start >= 0 && end > start) {
        return Map<String, dynamic>.from(
          jsonDecode(body.substring(start, end + 1)) as Map,
        );
      }
    } catch (_) {}

    return const {};
  }

  Future<void> fetchSettings() async {
    try {
      isLoadingSettings.value = true;
      final email = await SecureStorage().getUserEmail();
      if (email == null || email.trim().isEmpty) return;

      final token = await SecureStorage().getUserToken();
      final response = await HomeService().showSettingsByEmail(
        email: email.trim(),
        token: token,
      );

      final document = _parseXmlBody(response.body);
      final data = document['Data'];
      if (document['Status'].toString() == '1' && data is List) {
        for (final row in data) {
          if (row is Map) {
            final type = row['Type']?.toString().trim().toLowerCase();
            final modeStr = row['Mode']?.toString().trim().toLowerCase();
            final isTrue = modeStr == 'true' || modeStr == '1';

            if (type == 'ghost mode') {
              ghostMode.value = isTrue;
            } else if (type == 'exclude message profile' ||
                type == 'hide message profile') {
              hideChatUsers.value = isTrue;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[AppSettingsController] Error fetching settings: $e');
    } finally {
      isLoadingSettings.value = false;
    }
  }

  Future<void> updateGhostMode(bool val) async {
    final prev = ghostMode.value;
    ghostMode.value = val;
    try {
      final email = await SecureStorage().getUserEmail();
      if (email == null || email.trim().isEmpty) return;

      final token = await SecureStorage().getUserToken();
      final response = await HomeService().updateSettings(
        type: 'Ghost Mode',
        mode: val,
        email: email.trim(),
        token: token,
      );
      debugPrint('[AppSettingsController] Update Ghost Mode response: ${response.statusCode}');
    } catch (e) {
      debugPrint('[AppSettingsController] Error updating ghost mode: $e');
      ghostMode.value = prev; // Revert on error
    }
  }

  Future<void> updateExcludeMessageProfile(bool val) async {
    final prev = hideChatUsers.value;
    hideChatUsers.value = val;
    try {
      final email = await SecureStorage().getUserEmail();
      if (email == null || email.trim().isEmpty) return;

      final token = await SecureStorage().getUserToken();
      final response = await HomeService().updateSettings(
        type: 'Exclude Message Profile',
        mode: val,
        email: email.trim(),
        token: token,
      );
      debugPrint('[AppSettingsController] Update Exclude Message Profile response: ${response.statusCode}');
    } catch (e) {
      debugPrint('[AppSettingsController] Error updating exclude message profile: $e');
      hideChatUsers.value = prev; // Revert on error
    }
  }
}