import 'dart:io';
import 'dart:convert';
import 'package:boomboom/authentication/registerscreen/intrest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boomboom/backend/secure_storage.dart';

import 'package:get/get.dart';
import '../../../controller/user_controller.dart';

import '../../constant/apptextstyle.dart';
import '../../constant/colors.dart';

class SexualOrientationScreen extends StatefulWidget {
  final bool isRegister;
  final String email;
  final String fullName;
  final String dob;
  final String password;
  final String bio;
  final String gender;
  final String lookingFor;
  final List<File> photos;
  final List<File> videos;

  const SexualOrientationScreen({
    super.key,
    this.isRegister = false,
    this.email = "",
    this.fullName = "",
    this.dob = "",
    this.password = "",
    this.bio = "",
    this.gender = "",
    this.lookingFor = "",
    this.photos = const [],
    this.videos = const [],
  });

  @override
  State<SexualOrientationScreen> createState() =>
      _SexualOrientationScreenState();
}

class _SexualOrientationScreenState extends State<SexualOrientationScreen> {
  int selectedIndex = -1;

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
          final String orientationStr = data["Orientation"] ?? "";
          if (orientationStr.isNotEmpty) {
            final index = options.indexWhere(
              (opt) => opt["title"]!.toLowerCase().trim() == orientationStr.toLowerCase().trim()
            );
            if (index != -1 && mounted) {
              setState(() {
                selectedIndex = index;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading profile in SexualOrientationScreen: $e");
    }
  }

  final List<Map<String, String>> options = [
    {
      "title": "Heterosexual / Straight",
      "desc":
          "Emotionally and sexually attracted to people of a different gender. Attraction is typically to complementary gender expressions.",
    },
    {
      "title": "Gay",
      "desc":
          "Primarily attracted to individuals of the same gender. Often used to describe men but also inclusive of other gender identities.",
    },
    {
      "title": "Lesbian",
      "desc":
          "A woman who is emotionally and sexually attracted to other women. Identity centers shared gender experiences.",
    },
    {
      "title": "Bisexual",
      "desc":
          "Attracted to more than one gender (not necessarily equally). Emotional and sexual connections may vary across the spectrum.",
    },
    {
      "title": "Pansexual (or Omnisexual)",
      "desc":
          "Attracted to individuals regardless of gender identity or expression. Love beyond binary boundaries.",
    },
    {
      "title": "Queer",
      "desc":
          "Umbrella term used by people whose sexual orientation isn’t exclusively heterosexual. Embraces fluidity and non-conformity.",
    },
    {
      "title": "Asexual",
      "desc":
          "Experiences little or no sexual attraction to others. Romantic orientations may still exist.",
    },
    {
      "title": "Demisexual",
      "desc":
          "Only experiences sexual attraction after forming a strong emotional connection.",
    },
    {
      "title": "Questioning",
      "desc":
          "Exploring or uncertain about one’s sexual orientation. A valid identity during the discovery process.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              /// HEADER
              Row(
                children: [
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      "How do you identify in terms of sexual orientation?",
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 24.sp : 20.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10.h),

              Text(
                "Select an option that best reflects your identity.",
                style: AppTextStyles.small,
              ),

              SizedBox(height: 20.h),

              /// LIST
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    final isSelected = selectedIndex == i;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = i;
                          if (Get.isRegistered<UserController>()) {
                            Get.find<UserController>().orientation.value = options[i]["title"]!;
                          }
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(14.r),

                          /// BORDER LIKE SCREEN
                          border: Border.all(
                            color: isSelected
                                ? Colors.blueAccent
                                : Colors.white12,
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// TITLE
                            Text(
                              options[i]["title"]!,
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),

                            SizedBox(height: 6.h),

                            /// DESC
                            Text(
                              options[i]["desc"]!,
                              style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              /// NEXT BUTTON
              /// NEXT BUTTON
              if (widget.isRegister)
                GestureDetector(
                  onTap: () {
                    if (selectedIndex == -1) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LifestyleScreen(
                          isRegister: true,
                          email: widget.email,
                          fullName: widget.fullName,
                          dob: widget.dob,
                          password: widget.password,
                          bio: widget.bio,
                          gender: widget.gender,
                          lookingFor: widget.lookingFor,
                          orientation: options[selectedIndex]["title"]!,
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
                        colors: selectedIndex != -1
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
                        child: Text("Next", style: AppTextStyles.button),
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }
}
