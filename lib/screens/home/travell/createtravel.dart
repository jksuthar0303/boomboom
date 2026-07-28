import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../backend/countryapi.dart';
import '../../../constant/appsize.dart';
import '../../../constant/apptextstyle.dart';
import '../../../constant/colors.dart';

class CreateJourneyScreen extends StatefulWidget {
  const CreateJourneyScreen({super.key});

  @override
  State<CreateJourneyScreen> createState() => _CreateJourneyScreenState();
}

class _CreateJourneyScreenState extends State<CreateJourneyScreen> {
  final LocationController controller = Get.put(LocationController());

  int journeyIndex = 0;
  int styleIndex = 0;
  int genderIndex = 0;

  bool hideFromCountry = false;
  String hideGender = "";

  String selectedField = "";

  final journeyList = [
    "Vocation",
    "Business",
    "Nightlife & Parties",
    "Travel Companion",
    "Tour Guide",
    "Massage & Spa",
    "Island"
  ];
  final styleList = ["Solo", "Group", "Backpacker", "Couple"];
  final genderList = [
    {"label": "Any Gender", "icon": Icons.transgender},
    {"label": "Male", "icon": Icons.male},
    {"label": "female", "icon": Icons.female},
  ];

  /// 🔥 Gender icon helper
  IconData _genderIcon(String gender) {
    switch (gender) {
      case "Male":
        return Icons.male;
      case "Female":
        return Icons.female;
      case "Both":
        return Icons.transgender;
      default:
        return Icons.transgender;
    }
  }

  @override
  void initState() {
    super.initState();
    controller.fetchCountries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSize.w(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔥 TITLE
              Center(
                child: Column(
                  children: [
                    Text(
                      "Create Your Journey",
                      style: AppTextStyles.heading.copyWith(
                        fontSize: AppSize.sp(20),
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      "Plan your perfect trip and connect with fellow travelers",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 25.h),

              /// 🔥 JOURNEY TYPE
              _title("Journey Type"),
              _chipRow(journeyList, journeyIndex, (i) {
                setState(() => journeyIndex = i);
              }),

              /// 🔥 TRAVEL STYLE
              _title("Travel Style"),
              _chipRow(styleList, styleIndex, (i) {
                setState(() => styleIndex = i);
              }),

              /// 🔥 GENDER
              _title("Preferred Travel Companions"),
              _chipRow(genderList, genderIndex, (i) {
                setState(() => genderIndex = i);
              }),

              SizedBox(height: 22.h),

              SizedBox(height: 24.h),

              // ─────────────────────────────────────────
              // 🔥 HIDE FROM COUNTRY ROW
              // ─────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  /// ICON
                  Icon(
                    CupertinoIcons.eye_slash,
                    color: const Color(0xFFFFB800),
                    size: 22.sp,
                  ),

                  SizedBox(width: 12.w),

                  /// TEXT
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "Hide from My Country",
                          style: AppTextStyles.subHeading.copyWith(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(height: 6.h),

                        Text(
                          "Enable to hide your journey from travelers in your country",
                          style: AppTextStyles.small.copyWith(
                            fontSize: 12.sp,
                            color: Colors.white38,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        // ─────────────────────────────
                        // 🔥 SELECTED GENDER CHIP
                        // ─────────────────────────────
                        if (hideFromCountry && hideGender.isNotEmpty) ...[
                          SizedBox(height: 10.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6A5AE0).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: const Color(0xFF6A5AE0),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _genderIcon(hideGender),
                                  color: const Color(0xFF6A5AE0),
                                  size: 16.sp,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  "Hidden from: $hideGender",
                                  style: AppTextStyles.small.copyWith(
                                    fontSize: 12.sp,
                                    color: const Color(0xFFB08FFF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                /// 🔥 TAP TO CHANGE
                                GestureDetector(
                                  onTap: () => _openHideBottomSheet(),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    color: const Color(0xFF6A5AE0),
                                    size: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(width: 10.w),

                  /// 🔥 TOGGLE
                  Transform.scale(
                    scale: 0.95,
                    child: CupertinoSwitch(
                      value: hideFromCountry,
                      activeTrackColor: const Color(0xFF8E2DE2),
                      inactiveTrackColor: const Color(0xFF1B2236),
                      thumbColor: Colors.white,
                      onChanged: (value) {
                        if (value == true) {
                          _openHideBottomSheet();
                        } else {
                          setState(() {
                            hideFromCountry = false;
                            hideGender = "";
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              /// 🔥 FROM LOCATION
              _title("From Location"),
              Row(
                children: [
                  Expanded(
                    child: Obx(() => _dropdown(
                      controller.fromCountry.value,
                      "From Country",
                      Icons.public,
                    )),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Obx(() => _dropdown(
                      controller.fromCity.value,
                      "From City",
                      Icons.location_city,
                    )),
                  ),
                ],
              ),

              SizedBox(height: 15.h),

              /// 🔥 DESTINATION
              _title("Destination"),
              Row(
                children: [
                  Expanded(
                    child: Obx(() => _dropdown(
                      controller.destinationCountry.value,
                      "Destination Country",
                      Icons.public,
                    )),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Obx(() => _dropdown(
                      controller.destinationCity.value,
                      "Destination City",
                      Icons.location_city,
                    )),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              /// 🔥 TRAVEL DATES
              _title("Travel Dates"),
              Row(
                children: [
                  Expanded(child: _dateBox("Mar 23, 2026")),
                  SizedBox(width: 10.w),
                  Expanded(child: _dateBox("Mar 23, 2026")),
                ],
              ),

              SizedBox(height: 25.h),

              /// 🔥 DESCRIPTION
              _title("Description"),
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: TextField(
                  maxLines: 5,
                  style: AppTextStyles.body.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Write something about your journey...",
                    hintStyle: AppTextStyles.small.copyWith(
                      color: Colors.white38,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              SizedBox(height: 25.h),

              /// 🔥 PUBLISH BUTTON
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Center(
                  child: Text("Publish Journey", style: AppTextStyles.button),
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🔥 HIDE BOTTOM SHEET (extracted method)
  // ─────────────────────────────────────────
  void _openHideBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// HANDLE
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),

            SizedBox(height: 16.h),

            Text(
              "Hide Journey From",
              style: AppTextStyles.subHeading.copyWith(
                fontSize: 20.sp,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 6.h),

            Text(
              "Select who should not see your journey",
              style: AppTextStyles.small.copyWith(
                color: Colors.white38,
                fontSize: 12.sp,
              ),
            ),

            SizedBox(height: 25.h),

            _hideOptionTile("Male", Icons.male),
            _hideOptionTile("Female", Icons.female),
            _hideOptionTile("Both", Icons.transgender),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🔥 TITLE
  // ─────────────────────────────────────────
  Widget _title(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, top: 10.h),
      child: Text(text, style: AppTextStyles.subHeading),
    );
  }

  // ─────────────────────────────────────────
  // 🔥 CHIP ROW
  // ─────────────────────────────────────────
  Widget _chipRow(
      List list,
      int selected,
      Function(int) onTap,
      ) {
    return SizedBox(
      height: 48.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, _) => SizedBox(width: 10.w),
        itemBuilder: (_, i) {
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.symmetric(
                horizontal: 18.w,
                vertical: 10.h,
              ),
              decoration: BoxDecoration(
                color: selected == i
                    ? const Color(0xFF6A5AE0)
                    : AppColors.secondary,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.05),
                    offset: const Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: list[i] is Map
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      list[i]["icon"],
                      size: 18,
                      color: selected == i
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      list[i]["label"],
                      style: AppTextStyles.small.copyWith(
                        color: selected == i
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                )
                    : Text(
                  list[i].toString(),
                  style: AppTextStyles.small.copyWith(
                    color: selected == i
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🔥 DROPDOWN
  // ─────────────────────────────────────────
  Widget _dropdown(
      String selectedValue,
      String title,
      IconData icon,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14.sp, color: const Color(0xFFB14DFF)),
            SizedBox(width: 5.w),
            Text(
              title,
              style: AppTextStyles.small.copyWith(
                fontSize: 11.sp,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () {
            // 🔥 City fields require a country to be picked first
            if (title == "From City" && controller.fromCountry.value.isEmpty) {
              _showSnack("Please select From Country first");
              return;
            }
            if (title == "Destination City" &&
                controller.destinationCountry.value.isEmpty) {
              _showSnack("Please select Destination Country first");
              return;
            }

            selectedField = title;

            if (title == "From Country" || title == "Destination Country") {
              _openCountryBottomSheet();
            } else {
              // From City / Destination City -> use cities fetched for the chosen country
              final country = title == "From City"
                  ? controller.fromCountry.value
                  : controller.destinationCountry.value;
              controller.fetchCities(country);
              _openCityBottomSheet();
            }
          },
          child: Container(
            height: 58.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: const Color(0xFF141B2D),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.02),
                  blurRadius: 2,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedValue.isEmpty ? "Select $title" : selectedValue,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small.copyWith(
                      fontSize: 13.sp,
                      color: selectedValue.isEmpty
                          ? Colors.white38
                          : Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white38,
                  size: 22.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSnack(String msg) {
    Get.snackbar(
      "",
      msg,
      backgroundColor: AppColors.secondary,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // ─────────────────────────────────────────
  // 🔥 HIDE OPTION TILE
  // ─────────────────────────────────────────
  Widget _hideOptionTile(String title, IconData icon) {
    final isSelected = hideGender == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          hideGender = title;
          hideFromCountry = true;
        });
        Get.back();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.symmetric(
          horizontal: 18.w,
          vertical: 16.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6A5AE0)
              : AppColors.secondary,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6A5AE0)
                : Colors.white.withValues(alpha: 0.06),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24.sp),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.white, size: 22.sp),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🔥 DATE BOX
  // ─────────────────────────────────────────
  Widget _dateBox(String text) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Text(text, style: AppTextStyles.body),
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🔥 COUNTRY BOTTOM SHEET (uses controller.filteredCountries)
  // ─────────────────────────────────────────
  void _openCountryBottomSheet() {
    // reset search + list every time the sheet opens
    controller.filterCountries("");

    Get.bottomSheet(
      Container(
        height: 500.h,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20.r),
          ),
        ),
        child: Column(
          children: [
            /// SEARCH — fires on every letter typed
            TextField(
              autofocus: false,
              onChanged: (value) {
                controller.filterCountries(value);
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search country...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: AppColors.secondary,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            SizedBox(height: 15.h),

            /// COUNTRY LIST
            Expanded(
              child: Obx(() {
                // 🔥 still loading the first time
                if (controller.isLoadingCountries.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                // 🔥 nothing matched the search, or API returned empty
                if (controller.filteredCountries.isEmpty) {
                  return Center(
                    child: Text(
                      "No countries found",
                      style: AppTextStyles.small.copyWith(color: Colors.white38),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: controller.filteredCountries.length,
                  itemBuilder: (_, i) {
                    final country = controller.filteredCountries[i];
                    return ListTile(
                      leading: country["flag"] != null
                          ? Image.network(
                        country["flag"],
                        width: 30,
                        height: 20,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                        const Icon(Icons.flag, color: Colors.white38),
                      )
                          : const Icon(Icons.flag, color: Colors.white38),
                      title: Text(
                        country["name"],
                        style: AppTextStyles.body.copyWith(color: Colors.white),
                      ),
                      onTap: () {
                        if (selectedField == "From Country") {
                          controller.fromCountry.value = country["name"];
                          controller.fromCity.value = ""; // 🔥 reset dependent city
                        } else if (selectedField == "Destination Country") {
                          controller.destinationCountry.value = country["name"];
                          controller.destinationCity.value = ""; // 🔥 reset dependent city
                        }
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🔥 CITY BOTTOM SHEET (uses controller.cities, fetched for chosen country)
  // ─────────────────────────────────────────
  void _openCityBottomSheet() {
    Get.bottomSheet(
      Container(
        height: 500.h,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20.r),
          ),
        ),
        child: Column(
          children: [
            Text(
              selectedField == "From City"
                  ? "Cities in ${controller.fromCountry.value}"
                  : "Cities in ${controller.destinationCountry.value}",
              style: AppTextStyles.subHeading.copyWith(
                fontSize: 16.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 15.h),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingCities.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (controller.cities.isEmpty) {
                  return Center(
                    child: Text(
                      "No cities found",
                      style: AppTextStyles.small.copyWith(color: Colors.white38),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: controller.cities.length,
                  itemBuilder: (_, i) {
                    final city = controller.cities[i];
                    return ListTile(
                      leading: const Icon(Icons.location_city, color: Colors.white38),
                      title: Text(
                        city,
                        style: AppTextStyles.body.copyWith(color: Colors.white),
                      ),
                      onTap: () {
                        if (selectedField == "From City") {
                          controller.fromCity.value = city;
                        } else if (selectedField == "Destination City") {
                          controller.destinationCity.value = city;
                        }
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}