import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constant/colors.dart';
import '../constant/apptextstyle.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {

  int selectedTab = 0;
  RangeValues ageRange = const RangeValues(18, 80);
  double distance = 50;
  String? showMe;
  List<String> selectedInterests = [];
  String? selectedEthnicity;
  String? selectedSmoking;
  String? selectedDrinking;
  String? selectedWorkout;

  // ================= LABEL =================
  Widget _label(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Text(
        title,
        style: AppTextStyles.subHeading.copyWith(
          fontSize: 17.sp,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  // ================= CHIP =================
  Widget _chip({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.r),
          color: selected ? AppColors.accent : Colors.white,
          border: Border.all(
            color: selected ? AppColors.accent : Colors.black.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            color: selected ? Colors.black : Colors.black87,
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ================= SINGLE SECTION =================
  Widget _singleSection(
      String title,
      List<String> options,
      String? selected,
      void Function(String) onSelect,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(title),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: options.map((item) {
            return _chip(
              title: item,
              selected: selected == item,
              onTap: () => setState(() => onSelect(item)),
            );
          }).toList(),
        ),
        SizedBox(height: 28.h),
      ],
    );
  }

  // ================= MULTI SECTION =================
  Widget _multiSection(
      String title,
      List<String> options,
      List<String> selected,
      void Function(String) onToggle,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(title),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: options.map((item) {
            return _chip(
              title: item,
              selected: selected.contains(item),
              onTap: () => setState(() => onToggle(item)),
            );
          }).toList(),
        ),
        SizedBox(height: 28.h),
      ],
    );
  }

  // ================= SLIDER CARD =================
  Widget _sliderCard({
    required String title,
    required String value,
    required Widget slider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(title),
        Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.accent,
                  inactiveTrackColor: Colors.black12,
                  thumbColor: AppColors.accent,
                  overlayColor: AppColors.accent.withValues(alpha: 0.15),
                  rangeThumbShape: const RoundRangeSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                ),
                child: slider,
              ),
            ],
          ),
        ),
        SizedBox(height: 28.h),
      ],
    );
  }

  // ================= CLEAR ALL =================
  void _clearAll() {
    setState(() {
      ageRange = const RangeValues(18, 80);
      distance = 50;
      showMe = null;
      selectedInterests.clear();
      selectedEthnicity = null;
      selectedSmoking = null;
      selectedDrinking = null;
      selectedWorkout = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        content: Text(
          "All filters cleared!",
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.sp),
        ),
      ),
    );
  }

  // ================= APPLY FILTERS =================
  void _applyFilters() {
    final filters = {
      "ageRange": ageRange,
      "distance": distance,
      "showMe": showMe,
      "interests": selectedInterests,
      "ethnicity": selectedEthnicity,
      "smoking": selectedSmoking,
      "drinking": selectedDrinking,
      "workout": selectedWorkout,
    };
    Navigator.pop(context, filters);
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [

            /// ================= HEADER =================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.close, color: Colors.black, size: 20.sp),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Find Your Match",
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          "Apply filters to discover better people",
                          style: AppTextStyles.small.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// ================= TABS =================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.r),
                            color: selectedTab == 0
                                ? AppColors.accent
                                : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              "Basic Filters",
                              style: AppTextStyles.body.copyWith(
                                color: selectedTab == 0
                                    ? Colors.black
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.r),
                            color: selectedTab == 1
                                ? AppColors.accent
                                : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              "Advanced Filters",
                              style: AppTextStyles.body.copyWith(
                                color: selectedTab == 1
                                    ? Colors.black
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24.h),

            /// ================= BODY =================
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    if (selectedTab == 0) ...[

                      _sliderCard(
                        title: "How old are they?",
                        value: "Between ${ageRange.start.round()} and ${ageRange.end.round()}+",
                        slider: RangeSlider(
                          values: ageRange,
                          min: 18,
                          max: 80,
                          onChanged: (value) => setState(() => ageRange = value),
                        ),
                      ),

                      _sliderCard(
                        title: "How far away are they?",
                        value: "Up to ${distance.round()} kilometres away",
                        slider: Slider(
                          value: distance,
                          min: 1,
                          max: 100,
                          onChanged: (value) => setState(() => distance = value),
                        ),
                      ),

                      _singleSection(
                        "Who would you like to date?",
                        ["Men", "Women", "Everyone"],
                        showMe,
                            (v) => showMe = v,
                      ),

                      _multiSection(
                        "Filter by your interests",
                        [
                          "Music", "Travel", "Gaming", "Movies",
                          "Fitness", "Foodie", "Reading", "Pets",
                        ],
                        selectedInterests,
                            (v) {
                          if (selectedInterests.contains(v)) {
                            selectedInterests.remove(v);
                          } else {
                            selectedInterests.add(v);
                          }
                        },
                      ),
                    ],

                    if (selectedTab == 1) ...[

                      _singleSection(
                        "Ethnicity",
                        ["Asian", "Black", "White", "Mixed", "Other"],
                        selectedEthnicity,
                            (v) => selectedEthnicity = v,
                      ),

                      _singleSection(
                        "Smoking",
                        ["Never", "Socially", "Regularly"],
                        selectedSmoking,
                            (v) => selectedSmoking = v,
                      ),

                      _singleSection(
                        "Drinking",
                        ["Never", "Socially", "Regularly"],
                        selectedDrinking,
                            (v) => selectedDrinking = v,
                      ),

                      _singleSection(
                        "Workout",
                        ["Never", "Sometimes", "Weekly", "Daily"],
                        selectedWorkout,
                            (v) => selectedWorkout = v,
                      ),
                    ],

                    SizedBox(height: 120.h),
                  ],
                ),
              ),
            ),

            /// ================= BOTTOM BUTTONS =================
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [

                  // ✅ CLEAR ALL — fully tappable
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque, // ✅ poora area tappable
                      onTap: _clearAll,
                      child: Container(
                        height: 54.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30.r),
                          border: Border.all(color: Colors.black12, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "Clear All",
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // ✅ APPLY FILTERS — fully tappable
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque, // ✅ poora area tappable
                      onTap: _applyFilters,
                      child: Container(
                        height: 54.h,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.40),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "Apply Filters",
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}