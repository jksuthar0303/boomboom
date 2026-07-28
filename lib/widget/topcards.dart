import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constant/appsize.dart';
import '../constant/apptextstyle.dart';
import 'outlinedbutton.dart';

class TopCard extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  const TopCard({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      /// 🔥 RESPONSIVE WIDTH
      width: isTablet ? 420.w : 320.w,
      margin: EdgeInsets.only(right: 12.w),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),

        image: DecorationImage(
          image: image.startsWith('assets/')
              ? AssetImage(image)
              : NetworkImage(image) as ImageProvider,
          fit: BoxFit.cover,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),

      child: Container(
        padding: EdgeInsets.all(isTablet ? 20.w : 16.w),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.2),
              Colors.black.withValues(alpha: 0.85),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔥 TITLE
            Text(
              title,
              style: AppTextStyles.heading.copyWith(
                fontSize: isTablet ? AppSize.sp(22) : AppSize.sp(18),
              ),
            ),

            SizedBox(height: isTablet ? 6.h : 4.h),

            /// 🔥 SUBTITLE
            Text(
              subtitle,
              style: AppTextStyles.small.copyWith(
                fontSize: isTablet ? 13.sp : 11.sp,
                color: Colors.white70,
              ),
            ),

            SizedBox(height: isTablet ? 12.h : 8.h),

            /// 🔥 BUTTON
            // GestureDetector(
            //   onTap: onTap,
            //   child: Container(
            //     padding: EdgeInsets.symmetric(
            //       horizontal: isTablet ? 14.w : 10.w,
            //       vertical: isTablet ? 6.h : 4.h,
            //     ),
            //     decoration: BoxDecoration(
            //       color: Colors.white.withOpacity(0.2),
            //       borderRadius: BorderRadius.circular(20.r),
            //     ),
            //     child: Text(
            //       buttonText,
            //       style: AppTextStyles.small.copyWith(
            //         fontSize: isTablet ? 13.sp : 11.sp,
            //         color: Colors.white,
            //         fontWeight: FontWeight.w600,
            //       ),
            //     ),
            //   ),
            // ),
            GradientBorderButton(
              title: buttonText,
              isTablet: isTablet,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              borderRadius: 50.r,
              height: 35.h,
              onTap: onTap
            )
          ],
        ),
      ),
    );
  }
}