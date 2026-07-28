import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constant/appsize.dart';
import '../../constant/apptextstyle.dart';
import '../../constant/colors.dart';

class EnableLocationScreen extends StatelessWidget {
  const EnableLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSize.w(20)),
          child: Column(
            children: [
              SizedBox(height: AppSize.h(40)),

              /// ICON
              Container(
                height: AppSize.h(isTablet ? 90 : 70),
                width: AppSize.h(isTablet ? 90 : 70),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary,
                ),
                child: Icon(Icons.location_on,
                    color: Colors.white, size: AppSize.sp(28)),
              ),

              SizedBox(height: AppSize.h(20)),

              Text("Enable Location", style: AppTextStyles.heading),

              SizedBox(height: 6.h),

              Text(
                "Find perfect matches near you",
                style: AppTextStyles.small,
              ),

              SizedBox(height: AppSize.h(30)),

              /// CARD
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSize.w(20)),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Column(
                  children: [
                    Icon(Icons.location_off,
                        color: Colors.white38, size: 30.sp),

                    SizedBox(height: 10.h),

                    Text("Location Not Set",
                        style: AppTextStyles.subHeading),

                    SizedBox(height: 6.h),

                    Text(
                      "Enable location to discover nearby matches",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              /// FEATURES
              _feature("Find nearby matches", Icons.people),
              _feature("Privacy protected", Icons.shield),
              _feature("Better connections", Icons.flash_on),

              Spacer(),

              /// BUTTON
              Container(
                width: double.infinity,
                height: AppSize.h(55),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Center(
                  child: Text("Enable Location",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.black)),
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feature(String text, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18.sp),
          SizedBox(width: 10.w),
          Text(text, style: AppTextStyles.body),
        ],
      ),
    );
  }
}