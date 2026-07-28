import 'dart:io';
import 'dart:convert';
import 'package:boomboom/authentication/registerscreen/Sexsualorentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boomboom/backend/secure_storage.dart';

import 'package:get/get.dart';
import '../../../controller/user_controller.dart';

import '../../constant/appsize.dart';
import '../../constant/colors.dart';

class LookingForScreen extends StatefulWidget {
  final bool isRegister;
  final String email;
  final String fullName;
  final String dob;
  final String password;
  final String bio;
  final String gender;
  final List<File> photos;
  final List<File> videos;

  const LookingForScreen({
    super.key,
    this.isRegister = false,
    this.email = "",
    this.fullName = "",
    this.dob = "",
    this.password = "",
    this.bio = "",
    this.gender = "",
    this.photos = const [],
    this.videos = const [],
  });

  @override
  State<LookingForScreen> createState() => _LookingForScreenState();
}

class _LookingForScreenState extends State<LookingForScreen> {
  final List<String> selected = [];

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
          final String lookingForStr = data["Lookingfor"] ?? "";
          if (lookingForStr.isNotEmpty) {
            final split = lookingForStr.split(',').map((s) => s.trim()).toList();
            if (mounted) {
              setState(() {
                selected.addAll(split);
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading profile in LookingForScreen: $e");
    }
  }

  final List<Map<String, String>> options = [
    {"emoji": "❤️", "title": "Serious Love"},
    {"emoji": "💍", "title": "Marriage"},
    {"emoji": "😀", "title": "Casual"},
    {"emoji": "✨", "title": "Long Term"},
    {"emoji": "⏳", "title": "Short Term"},
    {"emoji": "✈️", "title": "Travel Partner"},
    {"emoji": "🤝", "title": "Meet New People"},
    {"emoji": "👥", "title": "Mutual Support Partner"},
  ];
  void toggle(String label) {
    setState(() {
      selected.contains(label) ? selected.remove(label) : selected.add(label);
      if (Get.isRegistered<UserController>()) {
        Get.find<UserController>().lookingFor.value = selected.join(', ');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Scrollable content ──
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSize.w(isTablet ? 32 : 20),
                  vertical: AppSize.h(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 35.w,
                        height: 35.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: AppSize.h(16)),

                    Text(
                      "What are you\nlooking for?",
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 52.sp : 40.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.00,
                      ),
                    ),

                    // SizedBox(height: AppSize.h(6)),
                    //
                    // Text(
                    //   "Select multiple options that best describe your current status.",
                    //   style: GoogleFonts.poppins(
                    //     fontSize: AppSize.sp(isTablet ? 14 : 12),
                    //     color: AppColors.textSecondary,
                    //     height: 1.5,
                    //   ),
                    // ),
                    SizedBox(height: AppSize.h(15)),

                    // ── 2x2 Grid ──
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: options.length,
                      separatorBuilder: (_, _) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final item = options[index];
                        final bool isSelected = selected.contains(
                          item["title"],
                        );

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selected.clear();
                              selected.add(item["title"]!);
                            });
                          },
                          child: Container(
                            height: 50.h,
                            padding: EdgeInsets.symmetric(horizontal: 18.w),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(22.r),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  item["emoji"]!,
                                  style: TextStyle(fontSize: 18.sp),
                                ),

                                SizedBox(width: 10.w),

                                Expanded(
                                  child: Text(
                                    item["title"]!,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ),

                                Container(
                                  width: 20.w,
                                  height: 20.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle, // ✅
                                    color: AppColors.primary,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.accent
                                          : const Color(0xFF333333),
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Container(
                                            width: 10.w,
                                            height: 10.w,
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
                        );
                      },
                    ),
                    SizedBox(height: AppSize.h(16)),
                  ],
                ),
              ),
            ),

            // ── Fixed Bottom ──
            if (widget.isRegister)
              Container(
                color: AppColors.primary,
                padding: EdgeInsets.fromLTRB(
                  AppSize.w(isTablet ? 32 : 20),
                  AppSize.h(10),
                  AppSize.w(isTablet ? 32 : 20),
                  AppSize.h(20),
                ),
                child: Builder(
                  builder: (context) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Text(
                        //   selected.isEmpty
                        //       ? "Select at least one to continue"
                        //       : "${selected.length} option${selected.length > 1 ? 's' : ''} selected",
                        //   style: GoogleFonts.poppins(
                        //     fontSize: AppSize.sp(10),
                        //     color: selected.isNotEmpty
                        //         ? AppColors.accent
                        //         : AppColors.textSecondary,
                        //   ),
                        // ),
                        //SizedBox(height: AppSize.h(10)),
                        GestureDetector(
                          onTap: () {
                            if (selected.isEmpty) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SexualOrientationScreen(
                                  isRegister: true,
                                  email: widget.email,
                                  fullName: widget.fullName,
                                  dob: widget.dob,
                                  password: widget.password,
                                  bio: widget.bio,
                                  gender: widget.gender,
                                  lookingFor: selected.join(', '),
                                  photos: widget.photos,
                                  videos: widget.videos,
                                ),
                              ),
                            );
                          },

                          child: Container(
                            width: double.infinity,
                            height: 55.h,

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.r),

                              gradient: LinearGradient(
                                colors: selected.isNotEmpty
                                    ? [Colors.blue, Colors.purple]
                                    : [Colors.grey, Colors.grey],
                              ),
                            ),

                            padding: EdgeInsets.all(2),

                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.black,
                                borderRadius: BorderRadius.circular(30.r),
                              ),

                              child: Center(
                                child: Text(
                                  "Next",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
