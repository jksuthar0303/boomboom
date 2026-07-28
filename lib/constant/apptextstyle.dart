  import 'package:flutter/material.dart';
  import 'package:flutter_screenutil/flutter_screenutil.dart';
  import 'package:google_fonts/google_fonts.dart';

  import 'colors.dart';

  class AppTextStyles {
    static TextStyle heading = GoogleFonts.poppins(
      fontSize: 22.sp,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    );

    static TextStyle subHeading = GoogleFonts.poppins(
      fontSize: 18.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );

    static TextStyle body = GoogleFonts.poppins(
      fontSize: 14.sp,
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondary,
    );

    static TextStyle button = GoogleFonts.poppins(
      fontSize: 16.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.white,
    );

    static TextStyle small = GoogleFonts.poppins(
      fontSize: 12.sp,
      color: AppColors.textSecondary,
    );
    static TextStyle onboarding = GoogleFonts.poppins(
      fontSize: 17.sp,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.4,
      letterSpacing: 0.3,
    );
    static TextStyle cardName = GoogleFonts.poppins(
      fontSize: 14.sp,
      fontWeight: FontWeight.w700, // 👈 strong bold
      color: Colors.white,
      letterSpacing: 0.3,
    );

    static TextStyle cardDistance = GoogleFonts.poppins(
      fontSize: 10.sp,
      fontWeight: FontWeight.w500,
      color: Colors.white70,
    );

    static TextStyle cardBadge = GoogleFonts.poppins(
      fontSize: 9.sp,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
  }