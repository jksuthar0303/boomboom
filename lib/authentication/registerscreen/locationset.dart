import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constant/appsize.dart';
import '../../constant/apptextstyle.dart';
import '../../constant/colors.dart';

class LocationEnabledScreen extends StatelessWidget {
  const LocationEnabledScreen({super.key});

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

              /// LOCATION CARD
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSize.w(20)),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.white, size: 24.sp),

                    SizedBox(height: 10.h),

                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: Colors.white, size: 18.sp),
                        SizedBox(width: 6.w),
                        Text("Delhi", style: AppTextStyles.subHeading),
                      ],
                    ),

                    SizedBox(height: 4.h),

                    Row(
                      children: [
                        Icon(Icons.public,
                            color: Colors.white38, size: 14.sp),
                        SizedBox(width: 6.w),
                        Text("India", style: AppTextStyles.small),
                      ],
                    ),

                    Divider(height: 20),

                    Text(
                      "Updated 15/04/2026, 13:14:59",
                      style: AppTextStyles.small,
                    ),

                    SizedBox(height: 10.h),

                    Container(
                      width: double.infinity,
                      height: 45.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: Text("Update Location",
                            style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.w600)),
                      ),
                    )
                  ],
                ),
              ),

              Spacer(),

              /// NEXT BUTTON (GRADIENT BORDER STYLE)
              Container(
                width: double.infinity,
                height: 55.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ),
                ),
                padding: EdgeInsets.all(2),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Center(
                    child: Text("Next",
                        style: AppTextStyles.button.copyWith(
                            color: Colors.white)),
                  ),
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}