import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../constant/apptextstyle.dart';

class PremiumMatchCarousel extends StatelessWidget {
  const PremiumMatchCarousel({super.key});

  final List<Map<String, String>> data = const [
    {
      "name": "Ava, 24",
      "percent": "96%",
      "img": "https://images.unsplash.com/photo-1544005313-94ddf0286df2"
    },
    {
      "name": "Emma, 22",
      "percent": "91%",
      "img": "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e"
    },
    {
      "name": "Sophia, 25",
      "percent": "88%",
      "img": "https://images.unsplash.com/photo-1494790108377-be9c29b29330"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        children: [
          ...data.map((e) => _premiumCard(
            e["name"]!,
            e["percent"]!,
            e["img"]!,
          )),
          _seeAllCard(),
        ],
      ),
    );
  }

  /// 🔥 PREMIUM CARD
  Widget _premiumCard(String name, String percent, String image) {
    return Container(
      width: 130.w,
      margin: EdgeInsets.only(right: 14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),

        /// 🔥 NEON GLOW BORDER
        gradient: const LinearGradient(
          colors: [Colors.pinkAccent, Colors.deepPurple],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 1,
          )
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(1.5.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: Stack(
            children: [
              /// IMAGE
              Positioned.fill(
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                ),
              ),

              /// 🔥 GLASS EFFECT
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                ),
              ),

              /// 🔥 GRADIENT DARK
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              /// 💎 MATCH %
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    percent,
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ),

              /// ❤️ LIKE BUTTON (PREMIUM)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.pinkAccent.withValues(alpha: 0.8),
                        Colors.redAccent.withValues(alpha: 0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withValues(alpha: 0.6),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                ),
              ),

              /// 🔥 NAME
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  name,
                  style: AppTextStyles.small.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🚀 SEE ALL (UPGRADED)
  Widget _seeAllCard() {
    return Container(
      width: 110.w,
      margin: EdgeInsets.only(right: 12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withValues(alpha: 0.6),
            Colors.black,
          ],
        ),
        border: Border.all(color: Colors.purpleAccent),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withValues(alpha: 0.4),
            blurRadius: 12,
          )
        ],
      ),
      child: Center(
        child: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 20.sp,
        ),
      ),
    );
  }
}