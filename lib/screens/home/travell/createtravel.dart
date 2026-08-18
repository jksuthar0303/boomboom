import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart' as xml;

import '../../../backend/countryapi.dart';
import '../../../backend/secure_storage.dart';
import '../../../backend/travel_service.dart';
import '../../../constant/appsize.dart';
import '../../../constant/apptextstyle.dart';
import '../../../constant/colors.dart';
import '../../../widget/snakbar.dart';

class CreateJourneyScreen extends StatefulWidget {
  const CreateJourneyScreen({super.key});

  @override
  State<CreateJourneyScreen> createState() => _CreateJourneyScreenState();
}

class _CreateJourneyScreenState extends State<CreateJourneyScreen> {
  final LocationController controller = Get.put(LocationController());
  final TravelService _travelService = TravelService();
  final TextEditingController _descController = TextEditingController();

  int journeyIndex = 0;
  int styleIndex = 0;
  int genderIndex = 0;

  bool hideFromCountry = false;
  String hideGender = "";

  String selectedField = "";

  DateTime? fromDate;
  DateTime? toDate;

  bool isSubmitting = false;

  final journeyList = [
    "Vacation",
    "Business",
    "Nightlife & Parties",
    "Travel Companion",
    "Tour Guide",
    "Massage & Spa",
    "Island",
  ];
  final styleList = ["Solo", "Group", "Backpacker", "Couple"];
  final genderList = [
    {"label": "Any Gender", "icon": Icons.transgender},
    {"label": "Male", "icon": Icons.male},
    {"label": "Female", "icon": Icons.female},
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
    fromDate = DateTime.now();
    toDate = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFromDate}) async {
    final initial = isFromDate ? (fromDate ?? DateTime.now()) : (toDate ?? DateTime.now());
    final firstDate = isFromDate
        ? DateTime.now().subtract(const Duration(days: 1))
        : (fromDate ?? DateTime.now());
    final lastDate = DateTime.now().add(const Duration(days: 365 * 5));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8E2DE2),
              onPrimary: Colors.white,
              surface: Color(0xFF141B2D),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF141B2D),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
          if (toDate != null && toDate!.isBefore(picked)) {
            toDate = picked.add(const Duration(days: 1));
          }
        } else {
          toDate = picked;
        }
      });
    }
  }

  Future<void> _publishJourney() async {
    FocusScope.of(context).unfocus();

    final fromCountry = controller.fromCountry.value.trim();
    final fromCity = controller.fromCity.value.trim();
    final toCountry = controller.destinationCountry.value.trim();
    final toCity = controller.destinationCity.value.trim();

    if (fromCountry.isEmpty) {
      NeuSnackbar.warning("Please select departure country (From Country)");
      return;
    }
    if (fromCity.isEmpty) {
      NeuSnackbar.warning("Please select departure city (From City)");
      return;
    }
    if (toCountry.isEmpty) {
      NeuSnackbar.warning("Please select destination country (To Country)");
      return;
    }
    if (toCity.isEmpty) {
      NeuSnackbar.warning("Please select destination city (To City)");
      return;
    }
    if (fromDate == null || toDate == null) {
      NeuSnackbar.warning("Please select travel dates");
      return;
    }
    if (toDate!.isBefore(fromDate!)) {
      NeuSnackbar.warning("Return date cannot be earlier than departure date");
      return;
    }

    final email = await SecureStorage().getUserEmail();
    if (email == null || email.trim().isEmpty) {
      NeuSnackbar.error("User email not found. Please log in again.");
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final journeyType = journeyList[journeyIndex];
      final travelStyle = styleList[styleIndex];
      final travelCompanion = genderList[genderIndex]["label"]?.toString() ?? "Any Gender";
      final isHide = hideFromCountry ? "true" : "false";
      final fromDateStr = DateFormat("yyyy-MM-dd").format(fromDate!);
      final toDateStr = DateFormat("yyyy-MM-dd").format(toDate!);
      final description = _descController.text.trim();

      final response = await _travelService.insertTravel(
        journeyType: journeyType,
        travelStyle: travelStyle,
        travelCompanion: travelCompanion,
        isHide: isHide,
        fromCountry: fromCountry,
        fromCity: fromCity,
        toCountry: toCountry,
        toCity: toCity,
        fromDate: fromDateStr,
        toDate: toDateStr,
        description: description,
        email: email.trim(),
      );

      if (response.statusCode == 200) {
        final bodyStr = response.body.trim();
        String message = "Journey created successfully!";
        bool isSuccess = true;

        // Extract JSON portion: {"Status":1,"Message":"Journey inserted successfully","TravelId":1}
        try {
          final jsonMatch = RegExp(r'\{.*?\}').firstMatch(bodyStr);
          if (jsonMatch != null) {
            final jsonStr = jsonMatch.group(0)!;
            final decoded = jsonDecode(jsonStr);
            if (decoded is Map) {
              final status = decoded["Status"];
              final msg = decoded["Message"]?.toString();
              if (msg != null && msg.isNotEmpty) {
                message = msg;
              }
              if (status != null) {
                isSuccess = (status == 1 || status == "1" || status == true);
              }
            }
          } else if (bodyStr.contains("<")) {
            final doc = xml.XmlDocument.parse(bodyStr);
            final resultElements = doc.findAllElements('InsertTravelResult');
            if (resultElements.isNotEmpty) {
              final resultText = resultElements.first.innerText.trim();
              if (resultText.toLowerCase().contains("error") || resultText == "-1") {
                isSuccess = false;
                message = resultText;
              }
            }
          }
        } catch (e) {
          debugPrint("Response parse note: $e");
        }

        if (!isSuccess) {
          throw Exception(message);
        }

        NeuSnackbar.success(message);

        // Reset location fields
        controller.fromCountry.value = "";
        controller.fromCity.value = "";
        controller.destinationCountry.value = "";
        controller.destinationCity.value = "";
        _descController.clear();

        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.of(context).pop(true);
        } else {
          Get.back(result: true);
        }
      } else {
        throw Exception("Server returned status code: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("InsertTravel Error: $e");
      NeuSnackbar.error(
        e.toString().replaceAll("Exception:", "").trim(),
        title: "Failed to Add Travel",
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
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
              /// 🔥 HEADER WITH BACK BUTTON
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(right: 36.w),
                        child: Column(
                          children: [
                            Text(
                              "Create Your Journey",
                              style: AppTextStyles.heading.copyWith(
                                fontSize: AppSize.sp(20),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              "Plan your perfect trip and connect with fellow travelers",
                              textAlign: TextAlign.center,
                              style: AppTextStyles.small.copyWith(
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
                  Expanded(
                    child: _dateBox(
                      label: "Departure Date",
                      date: fromDate,
                      onTap: () => _pickDate(isFromDate: true),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _dateBox(
                      label: "Return Date",
                      date: toDate,
                      onTap: () => _pickDate(isFromDate: false),
                    ),
                  ),
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
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
                child: TextField(
                  controller: _descController,
                  maxLines: 4,
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

              SizedBox(height: 30.h),

              /// 🔥 PUBLISH BUTTON WITH LOADING STATE
              GestureDetector(
                onTap: isSubmitting ? null : _publishJourney,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 54.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSubmitting
                          ? [const Color(0xFF5A1E8E), const Color(0xFF32008E)]
                          : [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8E2DE2).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isSubmitting
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 20.h,
                                width: 20.h,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                "Publishing Journey...",
                                style: AppTextStyles.button.copyWith(
                                  fontSize: 15.sp,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            "Publish Journey",
                            style: AppTextStyles.button.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),

              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🔥 HIDE BOTTOM SHEET
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
            if (title == "From City" && controller.fromCountry.value.isEmpty) {
              NeuSnackbar.warning("Please select departure country first");
              return;
            }
            if (title == "Destination City" &&
                controller.destinationCountry.value.isEmpty) {
              NeuSnackbar.warning("Please select destination country first");
              return;
            }

            selectedField = title;

            if (title == "From Country" || title == "Destination Country") {
              _openCountryBottomSheet();
            } else {
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
  Widget _dateBox({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final formatted = date != null ? DateFormat("MMM dd, yyyy").format(date) : "Select Date";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 14.sp, color: const Color(0xFFB14DFF)),
            SizedBox(width: 5.w),
            Text(
              label,
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
          onTap: onTap,
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
                    formatted,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.event_available_rounded,
                  color: const Color(0xFF8E2DE2),
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // 🔥 COUNTRY BOTTOM SHEET
  // ─────────────────────────────────────────
  void _openCountryBottomSheet() {
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
            /// SEARCH
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
                if (controller.isLoadingCountries.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

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
                          controller.fromCity.value = "";
                        } else if (selectedField == "Destination Country") {
                          controller.destinationCountry.value = country["name"];
                          controller.destinationCity.value = "";
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
  // 🔥 CITY BOTTOM SHEET (Search + Fallback + Custom input)
  // ─────────────────────────────────────────
  void _openCityBottomSheet() {
    controller.filterCities("");

    Get.bottomSheet(
      Container(
        height: 520.h,
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
            SizedBox(height: 12.h),

            /// 🔥 CITY SEARCH FIELD
            TextField(
              autofocus: false,
              onChanged: (value) {
                controller.filterCities(value);
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search city or type custom...",
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

            SizedBox(height: 12.h),

            Expanded(
              child: Obx(() {
                if (controller.isLoadingCities.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final hasTypedCustom = controller.searchCityText.value.trim().isNotEmpty;
                final customQuery = controller.searchCityText.value.trim();
                final citiesList = controller.filteredCities;

                if (citiesList.isEmpty && !hasTypedCustom) {
                  return Center(
                    child: Text(
                      "No cities found. Type above to enter custom city.",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.small.copyWith(color: Colors.white38),
                    ),
                  );
                }

                return ListView(
                  children: [
                    // 🔥 If user typed a search term, allow selecting it directly as custom city
                    if (hasTypedCustom) ...[
                      ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A5AE0).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: const Icon(
                            Icons.add_location_alt_rounded,
                            color: Color(0xFFB08FFF),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          "Use \"$customQuery\"",
                          style: AppTextStyles.body.copyWith(
                            color: const Color(0xFFB08FFF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          "Tap to select this custom city",
                          style: AppTextStyles.small.copyWith(
                            color: Colors.white38,
                            fontSize: 11.sp,
                          ),
                        ),
                        onTap: () {
                          if (selectedField == "From City") {
                            controller.fromCity.value = customQuery;
                          } else if (selectedField == "Destination City") {
                            controller.destinationCity.value = customQuery;
                          }
                          Get.back();
                        },
                      ),
                      const Divider(color: Colors.white12),
                    ],

                    ...citiesList.map((city) {
                      return ListTile(
                        leading: const Icon(
                          Icons.location_city,
                          color: Colors.white38,
                        ),
                        title: Text(
                          city.toString(),
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        onTap: () {
                          if (selectedField == "From City") {
                            controller.fromCity.value = city.toString();
                          } else if (selectedField == "Destination City") {
                            controller.destinationCity.value = city.toString();
                          }
                          Get.back();
                        },
                      );
                    }),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}