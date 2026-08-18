import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class FilterController extends GetxController {
  static FilterController get instance => Get.put(FilterController(), permanent: true);

  // ─── BASIC FILTER ────────────────────────────────────────────────────────
  final RxDouble minAge = 18.0.obs;
  final RxDouble maxAge = 100.0.obs;
  final RxDouble maxDistance = 50.0.obs;
  final RxSet<String> selectedGenders = <String>{}.obs;
  final RxSet<String> selectedRelationship = <String>{}.obs;

  // ─── ADVANCED FILTER ─────────────────────────────────────────────────────
  final Rx<String?> selectedNationality = Rx<String?>(null);
  final RxString cityCountry = "".obs;
  final RxSet<String> selectedBodyTypes = <String>{}.obs;
  final RxSet<String> selectedHeights = <String>{}.obs;
  final RxDouble selectedHeightCm = 175.0.obs;
  final RxSet<String> selectedDrinking = <String>{}.obs;
  final RxSet<String> selectedWorkout = <String>{}.obs;
  final RxSet<String> selectedInterests = <String>{}.obs;

  // Track filter trigger count for reactive listeners
  final RxInt filterVersion = 0.obs;

  bool get isFilterActive {
    return minAge.value > 18.0 ||
        maxAge.value < 100.0 ||
        maxDistance.value < 50.0 ||
        selectedGenders.isNotEmpty ||
        selectedRelationship.isNotEmpty ||
        (selectedNationality.value != null &&
            selectedNationality.value!.isNotEmpty) ||
        cityCountry.value.trim().isNotEmpty ||
        selectedBodyTypes.isNotEmpty ||
        selectedHeights.isNotEmpty ||
        selectedDrinking.isNotEmpty ||
        selectedWorkout.isNotEmpty ||
        selectedInterests.isNotEmpty;
  }

  void clearFilters() {
    minAge.value = 18.0;
    maxAge.value = 100.0;
    maxDistance.value = 50.0;
    selectedGenders.clear();
    selectedRelationship.clear();
    selectedNationality.value = null;
    cityCountry.value = "";
    selectedBodyTypes.clear();
    selectedHeights.clear();
    selectedDrinking.clear();
    selectedWorkout.clear();
    selectedInterests.clear();
    filterVersion.value++;
    debugPrint("🧹 [FilterController] All filters cleared.");
  }

  void notifyFilterApplied() {
    filterVersion.value++;
    debugPrint("🎯 [FilterController] Filters applied! (Version: ${filterVersion.value})");
  }

  /// Filter a given list of user profiles in-memory on frontend
  List<Map<String, dynamic>> applyFilterToUsers(
    List<Map<String, dynamic>> rawList, {
    Position? userPosition,
  }) {
    if (!isFilterActive) {
      return rawList;
    }

    return rawList.where((user) {
      // 1. AGE FILTER
      final dobStr = (user["Dob"] ?? user["dob"] ?? "").toString();
      final age = _calculateAge(dobStr, fallback: user["Age"] ?? user["age"]);
      if (age < minAge.value.toInt() || age > maxAge.value.toInt()) {
        return false;
      }

      // 2. GENDER FILTER
      if (selectedGenders.isNotEmpty) {
        final gender = (user["Gender"] ?? user["gender"] ?? "")
            .toString()
            .toLowerCase()
            .trim();
        bool genderMatched = false;
        for (var g in selectedGenders) {
          final target = g.toLowerCase().trim();
          if (target == "everyone") {
            genderMatched = true;
            break;
          } else if (target == "men" || target == "man" || target == "male") {
            if (gender == "male" || gender == "man" || gender == "men") {
              genderMatched = true;
              break;
            }
          } else if (target == "women" ||
              target == "woman" ||
              target == "female") {
            if (gender == "female" || gender == "woman" || gender == "women") {
              genderMatched = true;
              break;
            }
          } else if (target.contains("non-binary") ||
              target.contains("nonbinary")) {
            if (gender.contains("non-binary") ||
                gender.contains("nonbinary") ||
                gender.contains("other")) {
              genderMatched = true;
              break;
            }
          } else if (target.contains("trans")) {
            if (gender.contains("trans")) {
              genderMatched = true;
              break;
            }
          } else if (gender.contains(target)) {
            genderMatched = true;
            break;
          }
        }
        if (!genderMatched) return false;
      }

      // 3. RELATIONSHIP TYPE / LOOKING FOR FILTER
      if (selectedRelationship.isNotEmpty) {
        final lookingFor = (user["Lookingfor"] ??
                user["LookingFor"] ??
                user["looking_for"] ??
                user["Relationship"] ??
                "")
            .toString()
            .toLowerCase()
            .trim();
        if (lookingFor.isNotEmpty) {
          bool relMatch = false;
          for (var r in selectedRelationship) {
            if (lookingFor.contains(r.toLowerCase().trim())) {
              relMatch = true;
              break;
            }
          }
          if (!relMatch) return false;
        }
      }

      // 4. NATIONALITY / COUNTRY FILTER
      if (selectedNationality.value != null &&
          selectedNationality.value!.trim().isNotEmpty) {
        final nat = selectedNationality.value!.toLowerCase().trim();
        final userCountry = (user["Country"] ??
                user["country"] ??
                user["Nationality"] ??
                user["nationality"] ??
                "")
            .toString()
            .toLowerCase()
            .trim();
        final userCity =
            (user["City"] ?? user["city"] ?? "").toString().toLowerCase().trim();
        if (userCountry.isNotEmpty || userCity.isNotEmpty) {
          if (!userCountry.contains(nat) && !userCity.contains(nat)) {
            return false;
          }
        }
      }

      // 5. CITY / COUNTRY TEXT SEARCH
      if (cityCountry.value.trim().isNotEmpty) {
        final query = cityCountry.value.toLowerCase().trim();
        final userCity =
            (user["City"] ?? user["city"] ?? "").toString().toLowerCase().trim();
        final userCountry = (user["Country"] ?? user["country"] ?? "")
            .toString()
            .toLowerCase()
            .trim();
        if (userCity.isNotEmpty || userCountry.isNotEmpty) {
          if (!userCity.contains(query) && !userCountry.contains(query)) {
            return false;
          }
        }
      }

      // 6. BODY TYPE FILTER
      if (selectedBodyTypes.isNotEmpty) {
        final bodyType = (user["BodyType"] ?? user["body_type"] ?? "")
            .toString()
            .toLowerCase()
            .trim();
        if (bodyType.isNotEmpty) {
          bool match = false;
          for (var b in selectedBodyTypes) {
            if (bodyType.contains(b.toLowerCase().trim())) {
              match = true;
              break;
            }
          }
          if (!match) return false;
        }
      }

      // 7. DRINKING HABITS FILTER
      if (selectedDrinking.isNotEmpty) {
        final drinking = (user["DrinkingHabits"] ??
                user["drinking_habits"] ??
                user["Drinking"] ??
                "")
            .toString()
            .toLowerCase()
            .trim();
        if (drinking.isNotEmpty) {
          bool match = false;
          for (var d in selectedDrinking) {
            if (drinking.contains(d.toLowerCase().trim())) {
              match = true;
              break;
            }
          }
          if (!match) return false;
        }
      }

      // 8. WORKOUT FILTER
      if (selectedWorkout.isNotEmpty) {
        final workout = (user["Workout"] ?? user["workout"] ?? "")
            .toString()
            .toLowerCase()
            .trim();
        if (workout.isNotEmpty) {
          bool match = false;
          for (var w in selectedWorkout) {
            if (workout.contains(w.toLowerCase().trim())) {
              match = true;
              break;
            }
          }
          if (!match) return false;
        }
      }

      // 9. DISTANCE FILTER (if user GPS available)
      if (userPosition != null &&
          user["Latitude"] != null &&
          user["Longitude"] != null) {
        try {
          final lat = double.tryParse(user["Latitude"].toString());
          final lon = double.tryParse(user["Longitude"].toString());
          if (lat != null && lon != null && (lat != 0 || lon != 0)) {
            final distMeters = Geolocator.distanceBetween(
              userPosition.latitude,
              userPosition.longitude,
              lat,
              lon,
            );
            final distKm = distMeters / 1000;
            if (distKm > maxDistance.value) {
              return false;
            }
          }
        } catch (_) {}
      }

      return true;
    }).toList();
  }

  int _calculateAge(String? dobStr, {dynamic fallback}) {
    if (dobStr != null && dobStr.trim().isNotEmpty) {
      try {
        final dob = DateTime.parse(dobStr.trim());
        final today = DateTime.now();
        int age = today.year - dob.year;
        if (today.month < dob.month ||
            (today.month == dob.month && today.day < dob.day)) {
          age--;
        }
        if (age > 0) return age;
      } catch (_) {}
    }
    if (fallback != null) {
      final parsed = int.tryParse(fallback.toString());
      if (parsed != null && parsed > 0) return parsed;
    }
    return 24;
  }
}
