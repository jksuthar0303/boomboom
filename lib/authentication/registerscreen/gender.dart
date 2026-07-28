import 'dart:io';
import 'dart:convert';
import 'package:boomboom/authentication/registerscreen/whatyourarelookingfor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boomboom/backend/secure_storage.dart';

import 'package:get/get.dart';
import '../../../controller/user_controller.dart';

import '../../constant/appsize.dart';
import '../../constant/colors.dart';
import '../../widget/outlinedbutton.dart';

class GenderScreen extends StatefulWidget {
  final bool isRegister;
  final String email;
  final String fullName;
  final String dob;
  final String password;
  final String bio;
  final List<File> photos;
  final List<File> videos;

  const GenderScreen({
    super.key,
    this.isRegister = false,
    this.email = "",
    this.fullName = "",
    this.dob = "",
    this.password = "",
    this.bio = "",
    this.photos = const [],
    this.videos = const [],
  });

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  String? selectedGender;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final jsonStr = await SecureStorage().getProfileJson();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        final List? dataList = decoded["Data"];
        if (dataList != null && dataList.isNotEmpty) {
          final data = dataList.first;
          final String genderStr = data["Gender"] ?? "";
          if (genderStr.isNotEmpty) {
            final exists = genderOptions.any((opt) => opt['label']!.toLowerCase().trim() == genderStr.toLowerCase().trim());
            if (exists && mounted) {
              setState(() {
                selectedGender = genderOptions.firstWhere((opt) => opt['label']!.toLowerCase().trim() == genderStr.toLowerCase().trim())['label'];
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading profile in GenderScreen: $e");
    }
  }

  final List<Map<String, String?>> genderOptions = [
    {'label': 'Male', 'sub': null},
    {'label': 'Female', 'sub': null},
    {'label': 'Transgender', 'sub': null},
    {'label': 'Non-binary', 'sub': 'Lesbian, gay, bisexual, queer...'},
  ];

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Scrollable top ──
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSize.w(isTablet ? 32 : 20),
                  vertical: AppSize.h(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () {
                        if (selectedGender == null) return;

                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) => LookingForScreen(
                              email: widget.email,
                              fullName: widget.fullName,
                              dob: widget.dob,
                              password: widget.password,
                              bio: widget.bio,
                              gender: selectedGender!,
                              photos: widget.photos,
                              videos: widget.videos,
                            ),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: AppSize.w(isTablet ? 44 : 36),
                        height: AppSize.h(isTablet ? 44 : 36),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black,
                              offset: const Offset(3, 3),
                              blurRadius: 7,
                            ),
                            BoxShadow(
                              color: const Color(0xFF1f1f1f),
                              offset: const Offset(-3, -3),
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

                    SizedBox(height: AppSize.h(20)),

                    // Title
                    Text(
                      "What's your\ngender?",
                      style: GoogleFonts.poppins(
                        fontSize: AppSize.sp(isTablet ? 32 : 26),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),

                    SizedBox(height: AppSize.h(8)),

                    // Subtitle
                    Text(
                      "Let us know how you identify. You can always change this later in your profile settings.",
                      style: GoogleFonts.poppins(
                        fontSize: AppSize.sp(isTablet ? 14 : 12),
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),

                    SizedBox(height: AppSize.h(28)),

                    // Gender Options
                    ...genderOptions.map((option) {
                      final bool isSel = selectedGender == option['label'];
                      return Padding(
                        padding: EdgeInsets.only(bottom: AppSize.h(12)),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => selectedGender = option['label']);
                            if (Get.isRegistered<UserController>()) {
                              Get.find<UserController>().gender.value = option['label']!;
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSize.w(18),
                              vertical: AppSize.h(isTablet ? 18 : 14),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: isSel ? Colors.blue : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: isSel
                                  ? [
                                      BoxShadow(
                                        color: Colors.black,
                                        offset: const Offset(3, 3),
                                        blurRadius: 7,
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFF1f1f1f),
                                        offset: const Offset(-3, -3),
                                        blurRadius: 7,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black,
                                        offset: const Offset(4, 4),
                                        blurRadius: 10,
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFF1f1f1f),
                                        offset: const Offset(-4, -4),
                                        blurRadius: 10,
                                      ),
                                    ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Label + sub
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option['label']!,
                                        style: GoogleFonts.poppins(
                                          fontSize: AppSize.sp(
                                            isTablet ? 16 : 14,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          color: isSel
                                              ? AppColors.white
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      if (option['sub'] != null) ...[
                                        SizedBox(height: AppSize.h(3)),
                                        Text(
                                          option['sub']!,
                                          style: GoogleFonts.poppins(
                                            fontSize: AppSize.sp(
                                              isTablet ? 11 : 10,
                                            ),
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Radio circle — neumorphic
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: AppSize.w(22),
                                  height: AppSize.w(22),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                    border: Border.all(
                                      color: isSel
                                          ? AppColors.accent
                                          : const Color(0xFF333333),
                                      width: 2,
                                    ),
                                    boxShadow: isSel
                                        ? [
                                            BoxShadow(
                                              color: Colors.black,
                                              offset: const Offset(2, 2),
                                              blurRadius: 4,
                                            ),
                                            BoxShadow(
                                              color: const Color(0xFF1f1f1f),
                                              offset: const Offset(-2, -2),
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: isSel
                                      ? Center(
                                          child: Container(
                                            width: AppSize.w(10),
                                            height: AppSize.w(10),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    SizedBox(height: AppSize.h(16)),
                  ],
                ),
              ),
            ),

            // ── Fixed Bottom Button ──
            if (widget.isRegister)
              Container(
                color: AppColors.primary,
                padding: EdgeInsets.fromLTRB(
                  AppSize.w(isTablet ? 32 : 20),
                  AppSize.h(10),
                  AppSize.w(isTablet ? 32 : 20),
                  AppSize.h(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedGender == null
                          ? "Select your gender to continue"
                          : "$selectedGender selected",
                      style: GoogleFonts.poppins(
                        fontSize: AppSize.sp(15),
                        fontWeight: FontWeight.bold,
                        color: selectedGender != null
                            ? AppColors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSize.h(10)),
                    GradientBorderButton(
                      title: "Next",
                      isTablet: isTablet,
                      width: 400,
                      height: 55,

                      onTap: () {
                        if (selectedGender == null) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LookingForScreen(
                              isRegister: true,
                              email: widget.email,
                              fullName: widget.fullName,
                              dob: widget.dob,
                              password: widget.password,
                              bio: widget.bio,
                              gender: selectedGender!,
                              photos: widget.photos,
                              videos: widget.videos,
                            ),
                          ),
                        );
                      },
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
