import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class FilterController extends GetxController {
  static FilterController get instance => Get.put(FilterController(), permanent: true);

  // ─── BASIC FILTER ────────────────────────────────────────────────────────
  final RxDouble minAge = 18.0.obs;
  final RxDouble maxAge = 100.0.obs;
  final RxDouble maxDistance = 150.0.obs;
  final RxBool distance150Plus = false.obs;
  final RxBool distanceFilterActive = false.obs;
  final RxSet<String> selectedGenders = <String>{}.obs;
  final RxSet<String> selectedRelationship = <String>{}.obs;

  // ─── ADVANCED FILTER ─────────────────────────────────────────────────────
  final Rx<String?> selectedNationality = Rx<String?>(null);
  final RxString cityCountry = "".obs;
  final RxSet<String> selectedBodyTypes = <String>{}.obs;
  final RxSet<String> selectedHeights = <String>{}.obs;
  final RxDouble selectedHeightCm = 175.0.obs;
  final RxBool heightFilterActive = false.obs;
  final RxSet<String> selectedDrinking = <String>{}.obs;
  final RxSet<String> selectedWorkout = <String>{}.obs;
  final RxSet<String> selectedInterests = <String>{}.obs;

  // Track filter trigger count for reactive listeners
  final RxInt filterVersion = 0.obs;
  final Map<String, geo.Placemark> _locationCache = {};

  Future<void> enrichLocationFields(
    Iterable<Map<String, dynamic>> users,
  ) async {
    for (final user in users) {
      final hasLocation = (user["Country"] ??
              user["country"] ??
              user["CountryName"] ??
              user["City"] ??
              user["city"] ??
              "")
          .toString()
          .trim()
          .isNotEmpty;
      if (hasLocation) continue;

      final lat = double.tryParse(
        (user["Latitude"] ?? user["Lat"] ?? user["latitude"] ?? "")
            .toString(),
      );
      final lon = double.tryParse(
        (user["Longitude"] ?? user["Lon"] ?? user["longitude"] ?? "")
            .toString(),
      );
      if (lat == null || lon == null || (lat == 0 && lon == 0)) continue;

      final key = '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';
      try {
        final place = _locationCache[key] ??=
            (await geo.Geocoding().placemarkFromCoordinates(lat, lon)).first;
        user["Country"] = place.country ?? "";
        user["City"] = place.locality ?? place.subAdministrativeArea ?? "";
      } catch (e) {
        debugPrint('[FilterController] Location lookup failed: $e');
      }
    }
  }

  bool get isFilterActive {
    return minAge.value > 18.0 ||
        maxAge.value < 100.0 ||
        distanceFilterActive.value ||
        selectedGenders.isNotEmpty ||
        selectedRelationship.isNotEmpty ||
        (selectedNationality.value != null &&
            selectedNationality.value!.isNotEmpty) ||
        cityCountry.value.trim().isNotEmpty ||
        heightFilterActive.value ||
        selectedBodyTypes.isNotEmpty ||
        selectedHeights.isNotEmpty ||
        selectedDrinking.isNotEmpty ||
        selectedWorkout.isNotEmpty ||
        selectedInterests.isNotEmpty;
  }

  void clearFilters() {
    minAge.value = 18.0;
    maxAge.value = 100.0;
    maxDistance.value = 150.0;
    distance150Plus.value = false;
    distanceFilterActive.value = false;
    selectedGenders.clear();
    selectedRelationship.clear();
    selectedNationality.value = null;
    cityCountry.value = "";
    selectedBodyTypes.clear();
    selectedHeights.clear();
    selectedDrinking.clear();
    selectedWorkout.clear();
    selectedInterests.clear();
    selectedHeightCm.value = 175.0;
    heightFilterActive.value = false;
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
        if (lookingFor.isEmpty) return false;

        bool relMatch = false;
        for (var r in selectedRelationship) {
          final target = r.toLowerCase().trim();
          if (target.isNotEmpty &&
              (lookingFor == target || lookingFor.contains(target))) {
            relMatch = true;
            break;
          }
        }
        if (!relMatch) return false;
      }

      // 4. NATIONALITY / COUNTRY FILTER
      if (selectedNationality.value != null &&
          selectedNationality.value!.trim().isNotEmpty) {
        final selectedNat = selectedNationality.value!.toLowerCase().trim();
        const nationalityAliases = <String, String>{
          'indian': 'india',
          'afghan': 'afghanistan',
          'american': 'united states',
          'british': 'united kingdom',
          'australian': 'australia',
          'canadian': 'canada',
        };
        final nat = nationalityAliases[selectedNat] ?? selectedNat;
        final userCountry = (user["Country"] ??
                user["country"] ??
                user["CountryName"] ??
                user["Nationality"] ??
                user["nationality"] ??
                user["Location"] ??
                "")
            .toString()
            .toLowerCase()
            .trim();
        final userCity = (user["City"] ??
                user["city"] ??
                user["CityName"] ??
                user["District"] ??
                user["district"] ??
                user["Address"] ??
                "")
            .toString()
            .toLowerCase()
            .trim();
        // A location filter requires a resolved country/city.
        if ((userCountry.isEmpty && userCity.isEmpty) ||
            (!userCountry.contains(nat) &&
                !userCity.contains(nat))) {
          return false;
        }
      }

      // 5. CITY / COUNTRY TEXT SEARCH
      if (cityCountry.value.trim().isNotEmpty) {
        final query = cityCountry.value.toLowerCase().trim();
        final userCity =
            (user["City"] ??
                    user["city"] ??
                    user["CityName"] ??
                    user["District"] ??
                    user["district"] ??
                    user["Address"] ??
                    "")
                .toString()
                .toLowerCase()
                .trim();
        final userCountry = (user["Country"] ??
                user["country"] ??
                user["CountryName"] ??
                user["Nationality"] ??
                user["Location"] ??
                "")
            .toString()
            .toLowerCase()
            .trim();
        if ((userCity.isEmpty && userCountry.isEmpty) ||
            (!userCity.contains(query) &&
                !userCountry.contains(query))) {
          return false;
        }
      }

      // 6. INTERESTS
      if (selectedInterests.isNotEmpty) {
        final interests = (user["Interests"] ??
                user["Interest"] ??
                user["interests"] ??
                user["Hobbies"] ??
                "")
            .toString()
            .toLowerCase()
            .trim();
        if (interests.isNotEmpty && !selectedInterests.any(
          (interest) {
            final target = interest
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
                .trim();
            return target.isNotEmpty && interests.contains(target);
          },
        )) {
          return false;
        }
      }

      // 7. BODY TYPE FILTER
      if (selectedBodyTypes.isNotEmpty) {
        final bodyType = (user["BodyType"] ?? user["body_type"] ?? "")
            .toString()
            .toLowerCase()
            .trim();
        if (bodyType.isNotEmpty) {
          bool match = false;
          for (var b in selectedBodyTypes) {
            final target = b.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
            final value = bodyType.replaceAll(RegExp(r'[^a-z0-9]'), '');
            if (target.isNotEmpty && value.contains(target)) {
              match = true;
              break;
            }
          }
          if (!match) return false;
        }
      }

      // 8. DRINKING HABITS FILTER
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
            final target = d.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
            final value = drinking.replaceAll(RegExp(r'[^a-z0-9]'), '');
            if (target.isNotEmpty && value.contains(target)) {
              match = true;
              break;
            }
          }
          if (!match) return false;
        }
      }

      // 9. WORKOUT FILTER
      if (selectedWorkout.isNotEmpty) {
        final workout = (user["Workout"] ?? user["workout"] ?? "")
            .toString()
            .toLowerCase()
            .trim();
        if (workout.isNotEmpty) {
          bool match = false;
          for (var w in selectedWorkout) {
            final target = w.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
            final value = workout.replaceAll(RegExp(r'[^a-z0-9]'), '');
            if (target.isNotEmpty && value.contains(target)) {
              match = true;
              break;
            }
          }
          if (!match) return false;
        }
      }

      // 10. HEIGHT FILTER. The slider is a preference, so allow a small
      // tolerance around the selected centimetre value.
      if (heightFilterActive.value) {
        final heightText = (user["Height"] ?? user["height"] ?? "")
            .toString();
        final heightMatch = RegExp(r'\d+(?:\.\d+)?').firstMatch(heightText);
        final userHeight = heightMatch == null
            ? null
            : double.tryParse(heightMatch.group(0)!);
        if (userHeight != null &&
            (userHeight - selectedHeightCm.value).abs() > 5) {
          return false;
        }
      }

      // 11. DISTANCE FILTER. Prefer GPS coordinates, then use an API-provided
      // Distance/distance value when location permission is unavailable.
      double? distKm;
      final lat = double.tryParse(
        (user["Latitude"] ?? user["Lat"] ?? user["latitude"] ?? "").toString(),
      );
      final lon = double.tryParse(
        (user["Longitude"] ?? user["Lon"] ?? user["longitude"] ?? "").toString(),
      );

      if (userPosition != null &&
          lat != null &&
          lon != null &&
          (lat != 0 || lon != 0)) {
        try {
          distKm = Geolocator.distanceBetween(
                userPosition.latitude,
                userPosition.longitude,
                lat,
                lon,
              ) /
              1000;
        } catch (_) {}
      }

      if (distKm == null) {
        final rawDistance =
            user["Distance"] ?? user["distance"] ?? user["DistanceKm"];
        if (rawDistance != null) {
          final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(rawDistance.toString());
          distKm = match == null ? null : double.tryParse(match.group(0)!);
        }
      }

      if (distanceFilterActive.value && distKm != null) {
        if (distance150Plus.value) {
          if (distKm < 150.0) return false;
        } else if (distKm > maxDistance.value) {
          return false;
        }
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
