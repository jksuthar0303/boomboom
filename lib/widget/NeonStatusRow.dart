
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constant/apptextstyle.dart';

class NeonStatusRow extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final List<Color>? gradientColors;

  const NeonStatusRow({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    this.gradientColors, // 👈 for Cross Path type
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 10.h),

        /// 🔥 ICON WITH NEON
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.8),
                blurRadius: 8,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color,
            size: 10.sp,
          ),
        ),

        SizedBox(width: 10.w),

        /// 🔥 TEXT WITH NEON / GRADIENT
        gradientColors != null
            ? ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: gradientColors!,
          ).createShader(bounds),
          child: Text(
            text,
            style: AppTextStyles.subHeading.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: gradientColors![0], blurRadius: 12),
                Shadow(color: gradientColors![1], blurRadius: 20),
              ],
            ),
          ),
        )
            : Text(
          text,
          style: AppTextStyles.subHeading.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: color, blurRadius: 10),
              Shadow(color: color.withValues(alpha: 0.6), blurRadius: 20),
            ],
          ),
        ),
      ],
    );
  }
}