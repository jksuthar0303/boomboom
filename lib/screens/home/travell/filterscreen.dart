import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../backend/countryapi.dart';

class TravelFilterScreen extends StatefulWidget {
  const TravelFilterScreen({super.key});

  @override
  State<TravelFilterScreen> createState() =>
      _TravelFilterScreenState();
}

class _TravelFilterScreenState
    extends State<TravelFilterScreen> {

  /// 🔥 COUNTRY CONTROLLER
  final LocationController controller =
  Get.put(LocationController());

  String selectedField = "";

  /// 🔥 SORT
  String selectedSort = "Newest First";

  final List<String> Datecategory = [
    "All date ",
    "upcoming Date",
    "ongoing Date",
    "landed this wee"
  ];

  /// 🔥 JOURNEY TYPE
  final List<String> journeyTypes = [
    "Vacation",
    "Business",
    "Nightlife & Parties",
    "Beach Fun",
    "Massage & Spa",
    "Island Hopping",
    "Temple Visits",
    "Shopping",
    "Adventure",
    "Dating",
  ];

  /// 🔥 CATEGORY
  final List<String> category = [
    "Solo",
    "Group",
    "Backpacker",
    "Couple",
  ];

  /// 🔥 GENDER
  final List<String> gender = [
    "Male",
    "Female",
    "Non-binary",
    "Other",
  ];

  final Set<String> selectedJourney = {};
  final Set<String> selectedCategory = {};
  final Set<String> selectedGender = {};

  /// 🔥 DATE
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();

    controller.fetchCountries();

    startDate = DateTime.now();
    endDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {

    final isTablet =
        MediaQuery.of(context).size.width > 600;

    return Scaffold(

      backgroundColor: Colors.black,

      body: SafeArea(

        child: Column(

          children: [

            /// 🔥 HEADER
            Padding(

              padding: EdgeInsets.symmetric(
                horizontal: 15.w,
                vertical: 12.h,
              ),

              child: Row(

                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

                children: [

                  Text(
                    "Filter Journeys",

                    style: TextStyle(
                      color: Colors.white,
                      fontSize:
                      isTablet ? 28.sp : 24.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  GestureDetector(

                    onTap: () {
                      Navigator.pop(context);
                    },

                    child: Container(

                      height:
                      isTablet ? 45.h : 38.h,

                      width:
                      isTablet ? 56.w : 48.w,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF232323),
                      ),

                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size:
                        isTablet ? 26.sp : 22.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              color: Colors.white10,
              thickness: 1,
            ),

            /// 🔥 BODY
            Expanded(

              child: SingleChildScrollView(

                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 18.h,
                ),

                child: Column(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    /// 🔥 SORT BY
                    title("Date category"),

                    SizedBox(height: 10.h),

                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,

                      children:
                      Datecategory.map((e) {

                        final selected =
                            selectedSort == e;

                        return filterChip(
                          title: e,
                          selected: selected,

                          onTap: () {

                            setState(() {
                              selectedSort = e;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 15.h),

                    /// 🔥 NATIONALITY
                    title("Nationality"),

                    SizedBox(height: 14.h),

                    Obx(
                          () => _dropdown(
                        controller.fromCountry.value,
                        "Nationality",
                        Icons.flag,
                      ),
                    ),

                    SizedBox(height: 26.h),

                    /// 🔥 JOURNEY TYPE
                    title("Journey Type"),

                    SizedBox(height: 14.h),

                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,

                      children:
                      journeyTypes.map((e) {

                        final selected =
                        selectedJourney.contains(e);

                        return filterChip(
                          title: e,
                          selected: selected,

                          onTap: () {

                            setState(() {

                              if (selected) {
                                selectedJourney.remove(e);
                              } else {
                                selectedJourney.add(e);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 18.h),

                    /// 🔥 CATEGORY
                    title("Category"),

                    SizedBox(height: 14.h),

                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,

                      children:
                      category.map((e) {

                        final selected =
                        selectedCategory.contains(e);

                        return filterChip(
                          title: e,
                          selected: selected,

                          onTap: () {

                            setState(() {

                              if (selected) {
                                selectedCategory.remove(e);
                              } else {
                                selectedCategory.add(e);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 18.h),

                    /// 🔥 GENDER
                    title("Gender Preference"),

                    SizedBox(height: 10.h),

                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,

                      children:
                      gender.map((e) {

                        final selected =
                        selectedGender.contains(e);

                        return filterChip(
                          title: e,
                          selected: selected,

                          onTap: () {

                            setState(() {

                              if (selected) {
                                selectedGender.remove(e);
                              } else {
                                selectedGender.add(e);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 20.h),

                    /// 🔥 FROM LOCATION
                    /// 🔥 FROM LOCATION
                    title("From Location"),

                    SizedBox(height: 10.h),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        /// COUNTRY
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [

                              Text(
                                "Country",

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              SizedBox(height: 10.h),

                              Obx(
                                    () => _dropdown(
                                  controller.fromCountry.value,
                                  "From Country",
                                  Icons.public,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 12.w),

                        /// CITY
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [

                              Text(
                                "City",

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              SizedBox(height: 10.h),

                              Obx(
                                    () => _dropdown(
                                  controller.fromCity.value,
                                  "From City",
                                  Icons.location_city,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18.h),

                    /// 🔥 DESTINATION
                    title("Destination"),

                    SizedBox(height: 10.h),

                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        /// COUNTRY
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [

                              Text(
                                "Country",

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              SizedBox(height: 10.h),

                              Obx(
                                    () => _dropdown(
                                  controller.destinationCountry.value,
                                  "Destination Country",
                                  Icons.public,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 12.w),

                        /// CITY
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [

                              Text(
                                "City",

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              SizedBox(height: 10.h),

                              Obx(
                                    () => _dropdown(
                                  controller.destinationCity.value,
                                  "Destination City",
                                  Icons.location_city,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18.h),

                    /// 🔥 DATE RANGE
                    title("Date Range"),

                    SizedBox(height: 10.h),

                    Row(
                      children: [

                        Expanded(
                          child: dateField(
                            title:
                            DateFormat(
                              "yyyy-MM-dd",
                            ).format(startDate!),

                            onTap: () async {

                              final picked =
                              await showDatePicker(

                                context: context,

                                initialDate:
                                startDate!,

                                firstDate:
                                DateTime(2020),

                                lastDate:
                                DateTime(2035),

                                builder:
                                    (context, child) {

                                  return Theme(
                                    data:
                                    ThemeData.dark(),
                                    child: child!,
                                  );
                                },
                              );

                              if (picked != null) {

                                setState(() {
                                  startDate = picked;
                                });
                              }
                            },
                          ),
                        ),

                        SizedBox(width: 10.w),

                        Expanded(
                          child: dateField(
                            title:
                            DateFormat(
                              "yyyy-MM-dd",
                            ).format(endDate!),

                            onTap: () async {

                              final picked =
                              await showDatePicker(

                                context: context,

                                initialDate:
                                endDate!,

                                firstDate:
                                DateTime(2020),

                                lastDate:
                                DateTime(2035),

                                builder:
                                    (context, child) {

                                  return Theme(
                                    data:
                                    ThemeData.dark(),
                                    child: child!,
                                  );
                                },
                              );

                              if (picked != null) {

                                setState(() {
                                  endDate = picked;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    /// 🔥 BUTTONS
                    Row(
                      children: [

                        Expanded(

                          child: GestureDetector(

                            onTap: () {

                              setState(() {

                                selectedJourney.clear();
                                selectedCategory.clear();
                                selectedGender.clear();

                                selectedSort =
                                "Newest First";
                              });
                            },

                            child: Container(

                              height:
                              isTablet ? 62.h : 56.h,

                              decoration: BoxDecoration(

                                borderRadius:
                                BorderRadius.circular(
                                    18.r),

                                color:
                                const Color(0xFF242424),
                              ),

                              child: Center(

                                child: Text(
                                  "CLEAR",

                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16.sp,
                                    fontWeight:
                                    FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 14.w),

                        Expanded(

                          child: GestureDetector(

                            onTap: () {},

                            child: Container(

                              height:
                              isTablet ? 62.h : 56.h,

                              decoration: BoxDecoration(

                                borderRadius:
                                BorderRadius.circular(
                                    18.r),

                                gradient:
                                const LinearGradient(
                                  colors: [
                                    Color(0xFFFF3D6D),
                                    Color(0xFFB22445),
                                  ],
                                ),
                              ),

                              child: Center(

                                child: Text(
                                  "FILTER",

                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight:
                                    FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 TITLE
  Widget title(String text) {

    return Text(
      text,

      style: TextStyle(
        color: Colors.white,
        fontSize: 15.sp,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  /// 🔥 CHIP
  Widget filterChip({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        padding: EdgeInsets.symmetric(
          horizontal: 18.w,
          vertical: 12.h,
        ),

        decoration: BoxDecoration(

          borderRadius:
          BorderRadius.circular(20.r),

          color: selected
              ? const Color(0xFFFF3D6D)
              : const Color(0xFF1F1F1F),

          border: Border.all(
            color: Colors.white10,
          ),
        ),

        child: Text(
          title,

          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 🔥 DROPDOWN
  Widget _dropdown(
      String selectedValue,
      String title,
      IconData icon,
      ) {

    return GestureDetector(

      onTap: () {

        selectedField = title;

        _openBottomSheet();
      },

      child: Container(

        height: 40.h,

        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
        ),

        decoration: BoxDecoration(

          color: const Color(0xFF1F1F1F),

          borderRadius:
          BorderRadius.circular(18.r),

          border: Border.all(
            color: Colors.white10,
          ),
        ),

        child: Row(

          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

          children: [

            Expanded(

              child: Text(

                selectedValue.isEmpty
                    ? "Select $title"
                    : selectedValue,

                overflow:
                TextOverflow.ellipsis,

                style: TextStyle(

                  color:
                  selectedValue.isEmpty
                      ? Colors.white38
                      : Colors.white,

                  fontSize: 12.sp,
                ),
              ),
            ),

            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFFFF3D6D),
              size: 25.sp,
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 DATE FIELD
  Widget dateField({
    required String title,
    required VoidCallback onTap,
  }) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        height: 40.h,

        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
        ),

        decoration: BoxDecoration(

          borderRadius:
          BorderRadius.circular(18.r),

          color: const Color(0xFF1F1F1F),

          border: Border.all(
            color: Colors.white10,
          ),
        ),

        child: Row(

          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

          children: [

            Text(
              title,

              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
              ),
            ),

            Icon(
              Icons.calendar_month,
              color: const Color(0xFFFF3D6D),
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 COUNTRY BOTTOM SHEET
  /// 🔥 COUNTRY BOTTOM SHEET
  /// 🔥 COUNTRY BOTTOM SHEET
  /// 🔥 COUNTRY BOTTOM SHEET
  void _openBottomSheet() {

    Get.bottomSheet(

      Container(

        height: 500.h,

        padding: EdgeInsets.all(16.w),

        decoration: BoxDecoration(

          /// 🔥 PREMIUM SHINY GREY
          gradient: const LinearGradient(

            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,

            colors: [

              Color(0xFF40465A),
              Color(0xFF313546),
              Color(0xFF262A36),
            ],
          ),

          borderRadius: BorderRadius.vertical(
            top: Radius.circular(34.r),
          ),

          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),

          /// 🔥 SHADOW FOR POPUP EFFECT
          boxShadow: [

            BoxShadow(
              color: Colors.black.withValues(alpha: 0.60),
              blurRadius: 45,
              spreadRadius: 10,
              offset: const Offset(0, -12),
            ),
          ],
        ),

        child: Column(

          children: [

            /// 🔥 TOP HANDLE
            Container(

              width: 65.w,
              height: 6.h,

              decoration: BoxDecoration(

                gradient: const LinearGradient(

                  colors: [

                    Colors.white70,
                    Colors.white24,
                  ],
                ),

                borderRadius:
                BorderRadius.circular(30.r),
              ),
            ),

            SizedBox(height: 22.h),

            /// 🔥 SEARCH FIELD
            Container(

              decoration: BoxDecoration(

                color: const Color(0xFF4A5065),

                borderRadius:
                BorderRadius.circular(20.r),

                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),

                boxShadow: [

                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: TextField(

                onChanged: (value) {
                  controller.filterCountries(value);
                },

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),

                decoration: InputDecoration(

                  hintText: "Search country...",

                  hintStyle: TextStyle(
                    color: Colors.white54,
                    fontSize: 14.sp,
                  ),

                  border: InputBorder.none,

                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white60,
                    size: 22.sp,
                  ),

                  contentPadding: EdgeInsets.symmetric(
                    vertical: 18.h,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            /// 🔥 COUNTRY LIST
            Expanded(

              child: Obx(

                    () => ListView.separated(

                  physics:
                  const BouncingScrollPhysics(),

                  itemCount:
                  controller.filteredCountries.length,

                  separatorBuilder: (_, _) =>
                      SizedBox(height: 12.h),

                  itemBuilder: (_, i) {

                    final country =
                    controller.filteredCountries[i];

                    return InkWell(

                      borderRadius:
                      BorderRadius.circular(20.r),

                      onTap: () {

                        if (selectedField ==
                            "Nationality") {

                          controller.fromCountry
                              .value =
                          country["name"];

                        } else if (selectedField ==
                            "From Country") {

                          controller.fromCountry
                              .value =
                          country["name"];

                        } else if (selectedField ==
                            "From City") {

                          controller.fromCity
                              .value =
                          country["name"];

                        } else if (selectedField ==
                            "Destination Country") {

                          controller
                              .destinationCountry
                              .value =
                          country["name"];

                        } else if (selectedField ==
                            "Destination City") {

                          controller
                              .destinationCity
                              .value =
                          country["name"];
                        }

                        Get.back();
                      },

                      child: Container(

                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 14.h,
                        ),

                        decoration: BoxDecoration(

                          /// 🔥 CARD SHINE COLOR
                          color: const Color(0xFF4A5065),

                          borderRadius:
                          BorderRadius.circular(20.r),

                          border: Border.all(
                            color:
                            Colors.white.withValues(alpha: 0.06),
                          ),

                          boxShadow: [

                            BoxShadow(
                              color:
                              Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),

                        child: Row(

                          children: [

                            /// 🔥 FLAG
                            ClipRRect(

                              borderRadius:
                              BorderRadius.circular(6.r),

                              child:
                              country["flag"] != null

                                  ? Image.network(

                                country["flag"],

                                width: 36.w,
                                height: 24.h,

                                fit: BoxFit.cover,
                              )

                                  : Icon(
                                Icons.flag,
                                color: Colors.white54,
                              ),
                            ),

                            SizedBox(width: 14.w),

                            /// 🔥 COUNTRY NAME
                            Expanded(

                              child: Text(

                                country["name"],

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight:
                                  FontWeight.w600,
                                ),
                              ),
                            ),

                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white38,
                              size: 16.sp,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      /// 🔥 IMPORTANT
      backgroundColor: Colors.transparent,

      /// 🔥 DIM BACKGROUND
      barrierColor: Colors.black.withValues(alpha: 0.55),

      isScrollControlled: true,
    );
  }  }