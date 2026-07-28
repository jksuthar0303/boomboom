import 'package:get/get.dart';

/// 🔥 CONTROLLER
class TravelAlertController extends GetxController {
  var users = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();

    loadDummyData();
  }

  /// 🔥 STATIC DATA
  /// FUTURE ME API DATA YAHI AA JAYEGA
  void loadDummyData() {
    users.value = [
      {
        "name": " Chandan",
        "age": 25,
        "flag": "🇮🇳",
        "height": "5'9\"",
        "from": "Aland Islands",
        "to": "Albania",
        "tag": "Business",
        "status": "2 days",
        "image":
            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d", // ✅ fixed
      },

      {
        "name": "Kabir",
        "age": 38,
        "flag": "🇵🇰",
        "height": "5'11\"",
        "from": "Encamp",
        "to": "les Escaldes",
        "tag": "Vacation",
        "status": "76d landed",
        "image": "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d",
      },

      {
        "name": "Alex",
        "age": 27,
        "flag": "🇮🇳",
        "height": "5'10\"",
        "from": "India",
        "to": "Thailand",
        "tag": "Nightlife",
        "status": "77d landed",
        "image": "https://images.unsplash.com/photo-1504593811423-6dd665756598",
      },

      {
        "name": "Maya",
        "age": 25,
        "flag": "🇦🇪",
        "height": "5'5\"",
        "from": "Dubai",
        "to": "Paris",
        "tag": "Solo",
        "status": "12d landed",
        "image": "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
      },
    ];
  }

  /// 🔥 FUTURE API
  Future<void> fetchUsers() async {
    // API CALL HERE
  }
}
