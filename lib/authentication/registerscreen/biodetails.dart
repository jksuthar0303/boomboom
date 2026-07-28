import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controller/auth_controller.dart';
import '../../constant/appsize.dart';
import '../../constant/apptextstyle.dart';
import '../../constant/colors.dart';
import '../../widget/outlinedbutton.dart';
import 'dart:io';
import '../../widget/snakbar.dart';

class BioDetailsScreen extends StatefulWidget {
  final String email;
  final String fullName;
  final String dob;
  final String password;
  final String bio;
  final String gender;
  final String lookingFor;
  final String orientation;
  final List<File> photos;
  final List<File> videos;

  const BioDetailsScreen({
    super.key,
    required this.email,
    required this.fullName,
    required this.dob,
    required this.password,
    required this.bio,
    required this.gender,
    required this.lookingFor,
    required this.orientation,
    this.photos = const [],
    this.videos = const [],
  });

  @override
  State<BioDetailsScreen> createState() => _BioDetailsScreenState();
}

class _BioDetailsScreenState extends State<BioDetailsScreen> {
  final AuthController _controller = Get.put(AuthController());
  final TextEditingController occupationController = TextEditingController();

  String? selectedHeight;
  String? selectedBodyType;
  String? selectedDrinking;
  String? selectedWorkout;

  // Options lists
  late final List<String> heightOptions;

  final List<String> bodyTypeOptions = [
    'Slim',
    'Average',
    'Athletic',
    'Muscular',
    'Curvy',
    'Heavyset',
    'Fat',
  ];

  final List<String> drinkingOptions = [
    'Never',
    'Socially',
    'Regularly',
    'Trying to quit',
  ];

  final List<String> workoutOptions = ['Daily', 'Weekly', 'Rarely', 'Never'];

  @override
  void initState() {
    super.initState();
    // Generate height options from 140 cm to 220 cm
    heightOptions = List.generate(81, (index) {
      final cm = 140 + index;
      final inchesTotal = cm / 2.54;
      final feet = (inchesTotal / 12).floor();
      final inches = (inchesTotal % 12).round();
      return "$feet'$inches\" ($cm cm)";
    });
  }

  @override
  void dispose() {
    occupationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (occupationController.text.trim().isEmpty) {
      NeuSnackbar.error("Please enter your occupation");
      return;
    }
    if (selectedHeight == null) {
      NeuSnackbar.error("Please select your height");
      return;
    }
    if (selectedBodyType == null) {
      NeuSnackbar.error("Please select your body type");
      return;
    }
    if (selectedDrinking == null) {
      NeuSnackbar.error("Please select your drinking habits");
      return;
    }
    if (selectedWorkout == null) {
      NeuSnackbar.error("Please select your workout routine");
      return;
    }

    _controller.register(
      email: widget.email,
      fullName: widget.fullName,
      dob: widget.dob,
      password: widget.password,
      bio: widget.bio,
      gender: widget.gender,
      lookingFor: widget.lookingFor,
      orientation: widget.orientation,
      occupation: occupationController.text.trim(),
      height: selectedHeight!,
      bodyType: selectedBodyType!,
      drinkingHabits: selectedDrinking!,
      workout: selectedWorkout!,
      interests: const [],
      photos: widget.photos,
      videos: widget.videos,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSize.w(20),
                vertical: AppSize.h(16),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: AppSize.w(isTablet ? 44 : 36),
                      height: AppSize.h(isTablet ? 44 : 36),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(3, 3),
                            blurRadius: 7,
                          ),
                          BoxShadow(
                            color: Color(0xFF1f1f1f),
                            offset: Offset(-3, -3),
                            blurRadius: 7,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textSecondary,
                        size: AppSize.w(isTablet ? 18 : 14),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSize.w(16)),
                  Expanded(
                    child: Text(
                      "About You",
                      style: GoogleFonts.poppins(
                        fontSize: AppSize.sp(isTablet ? 24 : 20),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── SCROLLABLE FORM ──
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppSize.w(20)),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Complete Your Profile",
                      style: GoogleFonts.poppins(
                        fontSize: AppSize.sp(isTablet ? 28 : 22),
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: AppSize.h(4)),
                    Text(
                      "Let others know a bit more about you.",
                      style: GoogleFonts.poppins(
                        fontSize: AppSize.sp(isTablet ? 14 : 12),
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSize.h(20)),

                    // Occupation (Text field matching first screen style)
                    _buildField(
                      label: "Occupation",
                      controller: occupationController,
                      hint: "Enter your occupation",
                      icon: Icons.work_outline,
                    ),
                    SizedBox(height: AppSize.h(16)),

                    // Height (Dropdown selection)
                    _buildDropdownField(
                      label: "Height",
                      value: selectedHeight,
                      items: heightOptions,
                      hint: "Select your height",
                      icon: Icons.height,
                      onChanged: (val) {
                        setState(() {
                          selectedHeight = val;
                        });
                      },
                    ),
                    SizedBox(height: AppSize.h(16)),

                    // Body Type (Dropdown selection)
                    _buildDropdownField(
                      label: "BodyType",
                      value: selectedBodyType,
                      items: bodyTypeOptions,
                      hint: "Select your body type",
                      icon: Icons.accessibility_new,
                      onChanged: (val) {
                        setState(() {
                          selectedBodyType = val;
                        });
                      },
                    ),
                    SizedBox(height: AppSize.h(16)),

                    // Drinking Habits (Dropdown selection)
                    _buildDropdownField(
                      label: "DrinkingHabits",
                      value: selectedDrinking,
                      items: drinkingOptions,
                      hint: "Select drinking habits",
                      icon: Icons.local_bar,
                      onChanged: (val) {
                        setState(() {
                          selectedDrinking = val;
                        });
                      },
                    ),
                    SizedBox(height: AppSize.h(16)),

                    // Workout (Dropdown selection)
                    _buildDropdownField(
                      label: "Workout",
                      value: selectedWorkout,
                      items: workoutOptions,
                      hint: "Select workout routine",
                      icon: Icons.fitness_center,
                      onChanged: (val) {
                        setState(() {
                          selectedWorkout = val;
                        });
                      },
                    ),
                    SizedBox(height: AppSize.h(30)),

                    // Submit Button
                    Obx(
                      () => _controller.isLoading.value
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    color: AppColors.accent,
                                  ),
                                  SizedBox(height: AppSize.h(12)),
                                  Text(
                                    _controller.loadingMessage.value,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.white,
                                      fontSize: AppSize.sp(13),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_controller.uploadProgress.value > 0.0 &&
                                      _controller.uploadProgress.value <
                                          1.0) ...[
                                    SizedBox(height: AppSize.h(10)),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4.r),
                                      child: LinearProgressIndicator(
                                        value: _controller.uploadProgress.value,
                                        color: AppColors.accent,
                                        backgroundColor: AppColors.textSecondary
                                            .withValues(alpha: 0.2),
                                        minHeight: 6.h,
                                      ),
                                    ),
                                    SizedBox(height: AppSize.h(4)),
                                    Text(
                                      "${(_controller.uploadProgress.value * 100).toInt()}% uploaded",
                                      style: AppTextStyles.small.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : GradientBorderButton(
                              title: "Submit",
                              isTablet: isTablet,
                              width: double.infinity,
                              height: 55.h,
                              onTap: _submit,
                            ),
                    ),
                    SizedBox(height: AppSize.h(30)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _neuField({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFFFF6C9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(1.3),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSize.w(15)),
        height: AppSize.h(53),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.05),
              offset: const Offset(-4, -4),
              blurRadius: 6,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.9),
              offset: const Offset(4, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.textSecondary, size: 16.sp),
              SizedBox(width: AppSize.w(6)),
            ],
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: AppColors.white,
                fontSize: AppSize.sp(12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSize.h(8)),
        _neuField(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: AppTextStyles.body.copyWith(
              color: AppColors.white,
              fontSize: AppSize.sp(12),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.body.copyWith(
                fontSize: AppSize.sp(12),
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.textSecondary, size: 16.sp),
              SizedBox(width: AppSize.w(6)),
            ],
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: AppColors.white,
                fontSize: AppSize.sp(12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSize.h(8)),
        _neuField(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: AppColors.secondary,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
              isExpanded: true,
              hint: Text(
                hint,
                style: AppTextStyles.body.copyWith(
                  fontSize: AppSize.sp(12),
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
              style: AppTextStyles.body.copyWith(
                color: AppColors.white,
                fontSize: AppSize.sp(12),
              ),
              items: items.map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.white,
                      fontSize: AppSize.sp(12),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
