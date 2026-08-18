import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TravelFilterController extends GetxController {
  static TravelFilterController get instance {
    try {
      return Get.find<TravelFilterController>();
    } catch (_) {
      return Get.put(TravelFilterController(), permanent: true);
    }
  }

  // 1. Date Category: "All date", "upcoming Date", "ongoing Date", "landed this week"
  final RxString selectedDateCategory = "All date".obs;

  // 2. Nationality / Country
  final Rx<String?> selectedCountry = Rx<String?>(null);

  // 2b. Location filters
  final Rx<String?> fromCountry = Rx<String?>(null);
  final Rx<String?> fromCity = Rx<String?>(null);
  final Rx<String?> destinationCountry = Rx<String?>(null);
  final Rx<String?> destinationCity = Rx<String?>(null);

  // 3. Journey Types (Vacation, Business, Nightlife & Parties, etc.)
  final RxSet<String> selectedJourneyTypes = <String>{}.obs;

  // 4. Categories (Solo, Group, Backpacker, Couple)
  final RxSet<String> selectedCategories = <String>{}.obs;

  // 5. Gender (Male, Female, Non-binary, Other)
  final RxSet<String> selectedGenders = <String>{}.obs;

  // 6. Custom Date Range
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);

  // 7. Sort: "Newest First", "Oldest First"
  final RxString selectedSort = "Newest First".obs;

  final RxInt filterVersion = 0.obs;

  bool get isFilterActive {
    final dCat = selectedDateCategory.value.trim().toLowerCase();
    final isDateActive = dCat.isNotEmpty && !dCat.startsWith("all");
    return isDateActive ||
        (selectedCountry.value != null && selectedCountry.value!.trim().isNotEmpty) ||
        (fromCountry.value != null && fromCountry.value!.trim().isNotEmpty) ||
        (fromCity.value != null && fromCity.value!.trim().isNotEmpty) ||
        (destinationCountry.value != null && destinationCountry.value!.trim().isNotEmpty) ||
        (destinationCity.value != null && destinationCity.value!.trim().isNotEmpty) ||
        selectedJourneyTypes.isNotEmpty ||
        selectedCategories.isNotEmpty ||
        selectedGenders.isNotEmpty ||
        startDate.value != null ||
        endDate.value != null;
  }

  void clearFilters() {
    selectedDateCategory.value = "All date";
    selectedCountry.value = null;
    fromCountry.value = null;
    fromCity.value = null;
    destinationCountry.value = null;
    destinationCity.value = null;
    selectedJourneyTypes.clear();
    selectedCategories.clear();
    selectedGenders.clear();
    startDate.value = null;
    endDate.value = null;
    selectedSort.value = "Newest First";
    filterVersion.value++;
    debugPrint("🧹 [TravelFilterController] Cleared all travel filters.");
  }

  void notifyFilterApplied() {
    filterVersion.value++;
    debugPrint("🎯 [TravelFilterController] Travel filters applied! (v${filterVersion.value})");
  }

  /// In-memory frontend filtering of journeys/trips
  List<Map<String, dynamic>> applyFilterToJourneys(List<Map<String, dynamic>> rawList) {
    if (rawList.isEmpty) return [];

    if (!isFilterActive && selectedSort.value == "Newest First") {
      return List<Map<String, dynamic>>.from(rawList);
    }

    final now = DateTime.now();

    var filtered = rawList.where((trip) {
      // 1. Journey Type Filter
      if (selectedJourneyTypes.isNotEmpty) {
        final jType = (trip["JourneyType"] ??
                trip["journeyType"] ??
                trip["tag"] ??
                trip["type"] ??
                "")
            .toString()
            .toLowerCase()
            .trim();
        bool match = false;
        for (var t in selectedJourneyTypes) {
          final target = t.toLowerCase().trim();
          if (jType.contains(target) || target.contains(jType)) {
            match = true;
            break;
          }
        }
        if (!match && jType.isNotEmpty) return false;
      }

      // 2. Category / Travel Style Filter (Solo, Group, Couple, etc.)
      if (selectedCategories.isNotEmpty) {
        final cat = (trip["Category"] ??
                trip["category"] ??
                trip["TravelStyle"] ??
                trip["travelStyle"] ??
                "")
            .toString()
            .toLowerCase()
            .trim();
        bool match = false;
        for (var c in selectedCategories) {
          final target = c.toLowerCase().trim();
          if (cat.contains(target) || target.contains(cat)) {
            match = true;
            break;
          }
        }
        if (!match && cat.isNotEmpty) return false;
      }

      // 3. Gender Filter
      if (selectedGenders.isNotEmpty) {
        final g = (trip["Gender"] ?? trip["gender"] ?? "")
            .toString()
            .toLowerCase()
            .trim();
        bool match = false;
        for (var target in selectedGenders) {
          final t = target.toLowerCase().trim();
          if (t == "male" && (g == "male" || g == "men")) {
            match = true;
          } else if (t == "female" && (g == "female" || g == "women")) {
            match = true;
          } else if (g.contains(t)) {
            match = true;
          }
        }
        if (!match && g.isNotEmpty) return false;
      }

      // 4. Country / Nationality Filter
      if (selectedCountry.value != null && selectedCountry.value!.trim().isNotEmpty) {
        final target = selectedCountry.value!.toLowerCase().trim();
        final from = (trip["from"] ??
                trip["From"] ??
                trip["FromCountry"] ??
                trip["DepartureCountry"] ??
                "")
            .toString()
            .toLowerCase()
            .trim();
        final to = (trip["to"] ??
                trip["To"] ??
                trip["ToCountry"] ??
                trip["DestinationCountry"] ??
                trip["Destination"] ??
                "")
            .toString()
            .toLowerCase()
            .trim();
        final nat = (trip["Nationality"] ??
                trip["nationality"] ??
                trip["Country"] ??
                trip["country"] ??
                "")
            .toString()
            .toLowerCase()
            .trim();

        if (!from.contains(target) &&
            !to.contains(target) &&
            !nat.contains(target) &&
            (from.isNotEmpty || to.isNotEmpty || nat.isNotEmpty)) {
          return false;
        }
      }

      // 4b. From Location Filter (Country & City)
      if (fromCountry.value != null && fromCountry.value!.trim().isNotEmpty) {
        final target = fromCountry.value!.toLowerCase().trim();
        final fCountry = (trip["FromCountry"] ?? trip["from"] ?? "").toString().toLowerCase().trim();
        if (!fCountry.contains(target) && fCountry.isNotEmpty) {
          return false;
        }
      }
      if (fromCity.value != null && fromCity.value!.trim().isNotEmpty) {
        final target = fromCity.value!.toLowerCase().trim();
        final fCity = (trip["FromCity"] ?? "").toString().toLowerCase().trim();
        if (!fCity.contains(target) && fCity.isNotEmpty) {
          return false;
        }
      }

      // 4c. Destination Location Filter (Country & City)
      if (destinationCountry.value != null && destinationCountry.value!.trim().isNotEmpty) {
        final target = destinationCountry.value!.toLowerCase().trim();
        final toCountry = (trip["ToCountry"] ?? trip["to"] ?? trip["Destination"] ?? "").toString().toLowerCase().trim();
        if (!toCountry.contains(target) && toCountry.isNotEmpty) {
          return false;
        }
      }
      if (destinationCity.value != null && destinationCity.value!.trim().isNotEmpty) {
        final target = destinationCity.value!.toLowerCase().trim();
        final toCity = (trip["ToCity"] ?? "").toString().toLowerCase().trim();
        if (!toCity.contains(target) && toCity.isNotEmpty) {
          return false;
        }
      }

      // 5. Date Category Filter ("All date", "upcoming Date", "ongoing Date", "landed this week")
      final sDateStr = (trip["StartDate"] ?? trip["startDate"] ?? trip["date"] ?? "").toString();
      final eDateStr = (trip["EndDate"] ?? trip["endDate"] ?? "").toString();
      DateTime? sDate;
      DateTime? eDate;
      try {
        if (sDateStr.isNotEmpty) sDate = DateTime.tryParse(sDateStr);
        if (eDateStr.isNotEmpty) eDate = DateTime.tryParse(eDateStr);
      } catch (_) {}

      final dCat = selectedDateCategory.value.toLowerCase().trim();
      if (dCat.contains("upcoming")) {
        if (sDate != null && sDate.isBefore(now.subtract(const Duration(days: 1)))) {
          return false;
        }
      } else if (dCat.contains("ongoing")) {
        if (sDate != null && eDate != null) {
          if (now.isBefore(sDate) || now.isAfter(eDate.add(const Duration(days: 1)))) {
            return false;
          }
        }
      } else if (dCat.contains("landed") || dCat.contains("week") || dCat.contains("wee")) {
        if (sDate != null) {
          final diffDays = now.difference(sDate).inDays;
          if (diffDays < 0 || diffDays > 7) {
            return false;
          }
        }
      }

      // 6. Custom Start / End Date Range Filter
      if (startDate.value != null && sDate != null) {
        if (sDate.isBefore(DateTime(startDate.value!.year, startDate.value!.month, startDate.value!.day))) {
          return false;
        }
      }
      if (endDate.value != null && eDate != null) {
        if (eDate.isAfter(DateTime(endDate.value!.year, endDate.value!.month, endDate.value!.day, 23, 59, 59))) {
          return false;
        }
      }

      return true;
    }).toList();

    return filtered;
  }
}
