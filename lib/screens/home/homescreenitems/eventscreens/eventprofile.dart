import 'package:boomboom/authentication/boomboom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../authentication/messagedetail.dart';
import '../../../../constant/apptextstyle.dart';
import '../../../../constant/colors.dart';

class ProfileDetailsScreen extends StatelessWidget {
  const ProfileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// TOP BAR
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24.w : 16.w,
                  vertical: isTablet ? 16.h : 12.h,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: _circleButton(Icons.arrow_back_ios_new_rounded, isTablet),
                    ),
                  ],
                ),
              ),

              /// PROFILE HEADER ROW
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24.w : 16.w,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// AVATAR with online dot + flag
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: isTablet ? 52.r : 44.r,
                          backgroundImage: const NetworkImage(
                            "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
                          ),
                        ),
                        /// Online dot
                        Positioned(
                          top: 4.h,
                          right: 4.w,
                          child: Container(
                            height: isTablet ? 14.h : 12.h,
                            width: isTablet ? 14.w : 12.w,
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.bg, width: 2),
                            ),
                          ),
                        ),
                        /// Flag
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(2.r),
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "🇮🇳",
                              style: TextStyle(fontSize: isTablet ? 18.sp : 15.sp),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(width: 16.w),

                    /// NAME + INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// Name + verified
                          Row(
                            children: [
                              Text(
                                "Anaya, 24",
                                style: GoogleFonts.poppins(
                                  color: AppColors.white,
                                  fontSize: isTablet ? 28.sp : 22.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Icon(
                                Icons.verified_rounded,
                                color: Colors.blue,
                                size: isTablet ? 22.sp : 18.sp,
                              ),
                            ],
                          ),

                          SizedBox(height: 6.h),

                          /// Location | Height | Activity
                          Wrap(
                            spacing: 8.w,
                            children: [
                              _metaChip(
                                Icons.location_on_rounded,
                                Colors.pinkAccent,
                                "1.2 km away",
                                isTablet,
                              ),
                              _divider(),
                              _metaChip(
                                Icons.height_rounded,
                                AppColors.textSecondary,
                                "5'4\"",
                                isTablet,
                              ),
                              _divider(),
                              _metaChip(
                                Icons.restaurant_rounded,
                                AppColors.textSecondary,
                                "Dinner",
                                isTablet,
                              ),
                            ],
                          ),

                          SizedBox(height: 8.h),

                          /// FREE TONIGHT chip
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(30.r),
                              border: Border.all(color: AppColors.white.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  color: AppColors.white,
                                  size: isTablet ? 14.sp : 12.sp,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  "Free Tonight",
                                  style: GoogleFonts.poppins(
                                    color: AppColors.white,
                                    fontSize: isTablet ? 12.sp : 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  "ends in ",
                                  style: GoogleFonts.poppins(
                                    color: AppColors.white.withValues(alpha: 0.6),
                                    fontSize: isTablet ? 11.sp : 9.sp,
                                  ),
                                ),
                                Text(
                                  "3h 12m",
                                  style: GoogleFonts.poppins(
                                    color: Colors.pinkAccent,
                                    fontSize: isTablet ? 11.sp : 9.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10.h),

              /// BIO TEXT
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.w : 16.w),
                child: Text(
                  "Looking to make good memories tonight ✨",
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: isTablet ? 14.sp : 12.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              SizedBox(height: 14.h),

              /// MAIN PHOTO with location tag
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.w : 16.w),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18.r),
                      child: Image.network(
                        "https://images.unsplash.com/photo-1488426862026-3ee34a7d66df",
                        width: double.infinity,
                        height: isTablet ? 340.h : 260.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                    /// Location overlay
                    Positioned(
                      bottom: 12.h,
                      left: 12.w,
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: Colors.pinkAccent,
                            size: isTablet ? 16.sp : 13.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            "Connaught Place, Delhi",
                            style: GoogleFonts.poppins(
                              color: AppColors.white,
                              fontSize: isTablet ? 13.sp : 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 14.h),

              /// WHAT I'M LOOKING FOR CARD
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.w : 16.w),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color: Colors.pinkAccent,
                                  size: isTablet ? 20.sp : 17.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  "What I'm Looking For",
                                  style: GoogleFonts.poppins(
                                    color: AppColors.white,
                                    fontSize: isTablet ? 16.sp : 13.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              "I'm up for good conversations, sharing laughs, and maybe grabbing dinner or exploring the city. Looking for someone who's kind, interesting, and spontaneous.",
                              style: AppTextStyles.body.copyWith(
                                fontSize: isTablet ? 13.sp : 11.sp,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      /// Wine glasses icon area
                      Text(
                        "🥂",
                        style: TextStyle(fontSize: isTablet ? 44.sp : 36.sp),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 14.h),

              /// SAY HELLO CARD
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.w : 16.w),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessageDetailPage(
                          index: 0,
                          messageData: {
                            "name": "Anaya",
                            "image": "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
                            "age": "24",
                            "gender": "F",
                            "city": "New Delhi",
                            "flag": "🇮🇳",
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20.w : 16.w,
                      vertical: isTablet ? 20.h : 16.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        /// Stars decoration
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.stars_rounded,
                                color: Colors.blueAccent,
                                size: isTablet ? 18.sp : 14.sp),
                            SizedBox(height: 8.h),
                            Icon(Icons.star_rounded,
                                color: Colors.blueAccent,
                                size: isTablet ? 12.sp : 10.sp),
                          ],
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Say Hello 👋",
                                style: GoogleFonts.poppins(
                                  color: AppColors.white,
                                  fontSize: isTablet ? 18.sp : 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                "Don't be shy! Start a conversation and\nsee where the night takes you.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: isTablet ? 12.sp : 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        /// Chat bubble icon
                        Container(
                          padding: EdgeInsets.all(isTablet ? 10.r : 8.r),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blueAccent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Icon(
                            Icons.chat_bubble_rounded,
                            color: Colors.blueAccent,
                            size: isTablet ? 24.sp : 20.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 14.h),

              /// VISIT PROFILES CARD
              // Padding(
              //   padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.w : 16.w),
              //   child: Container(
              //     width: double.infinity,
              //     padding: EdgeInsets.symmetric(
              //       horizontal: isTablet ? 20.w : 16.w,
              //       vertical: isTablet ? 18.h : 14.h,
              //     ),
              //     decoration: BoxDecoration(
              //       color: AppColors.cardBg,
              //       borderRadius: BorderRadius.circular(18.r),
              //       border: Border.all(
              //         color: Colors.pinkAccent.withOpacity(0.5),
              //         width: 1.5,
              //       ),
              //     ),
              //     child: Row(
              //       children: [
              //         /// Eye icon with sparkles
              //         Stack(
              //           clipBehavior: Clip.none,
              //           children: [
              //             Icon(
              //               Icons.remove_red_eye_outlined,
              //               color: Colors.pinkAccent,
              //               size: isTablet ? 36.sp : 30.sp,
              //             ),
              //             Positioned(
              //               top: -6.h,
              //               left: -8.w,
              //               child: Icon(Icons.star_rounded,
              //                   color: Colors.pinkAccent,
              //                   size: isTablet ? 10.sp : 8.sp),
              //             ),
              //             Positioned(
              //               bottom: -4.h,
              //               left: -10.w,
              //               child: Icon(Icons.star_rounded,
              //                   color: Colors.pinkAccent,
              //                   size: isTablet ? 8.sp : 6.sp),
              //             ),
              //           ],
              //         ),
              //         SizedBox(width: 16.w),
              //         // Expanded(
              //         //   child: Column(
              //         //     crossAxisAlignment: CrossAxisAlignment.start,
              //         //     children: [
              //         //       Text(
              //         //         "Visit 10 Profiles",
              //         //         style: GoogleFonts.poppins(
              //         //           color: AppColors.white,
              //         //           fontSize: isTablet ? 16.sp : 13.sp,
              //         //           fontWeight: FontWeight.w700,
              //         //         ),
              //         //       ),
              //         //       SizedBox(height: 2.h),
              //         //       RichText(
              //         //         text: TextSpan(
              //         //           children: [
              //         //             TextSpan(
              //         //               text: "10 ",
              //         //               style: GoogleFonts.poppins(
              //         //                 color: Colors.pinkAccent,
              //         //                 fontSize: isTablet ? 12.sp : 10.sp,
              //         //                 fontWeight: FontWeight.w700,
              //         //               ),
              //         //             ),
              //         //             TextSpan(
              //         //               text: "profile views left today",
              //         //               style: GoogleFonts.poppins(
              //         //                 color: AppColors.textSecondary,
              //         //                 fontSize: isTablet ? 12.sp : 10.sp,
              //         //               ),
              //         //             ),
              //         //           ],
              //         //         ),
              //         //       ),
              //         //     ],
              //         //   ),
              //         // ),
              //         /// Person icon with sparkle
              //         Stack(
              //           clipBehavior: Clip.none,
              //           children: [
              //             Icon(
              //               Icons.person_outlined,
              //               color: Colors.pinkAccent,
              //               size: isTablet ? 36.sp : 30.sp,
              //             ),
              //             Positioned(
              //               top: -6.h,
              //               right: -8.w,
              //               child: Icon(Icons.star_rounded,
              //                   color: Colors.pinkAccent,
              //                   size: isTablet ? 10.sp : 8.sp),
              //             ),
              //           ],
              //         ),
              //       ],
              //     ),
              //   ),
              // ),

              SizedBox(height: 20.h),

              /// SAY HI BUTTON (purple → pink gradient, same as Image 2)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.w : 16.w),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BoomProfileScreen()
                      ),
                    );
                  },
                  child: Container(
                    height: isTablet ? 65.h : 58.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18.r),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF7B2FBE), // deep purple
                          Colors.pinkAccent,  // pink
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_rounded,
                          color: AppColors.white,
                          size: isTablet ? 24.sp : 20.sp,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          "View Profile",
                          style: AppTextStyles.button,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  /// META CHIP
  Widget _metaChip(IconData icon, Color iconColor, String text, bool isTablet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: isTablet ? 14.sp : 12.sp),
        SizedBox(width: 3.w),
        Text(
          text,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: isTablet ? 12.sp : 10.sp,
          ),
        ),
      ],
    );
  }

  /// DIVIDER
  Widget _divider() {
    return Text(
      " | ",
      style: TextStyle(color: Colors.white24, fontSize: 12.sp),
    );
  }

  /// CIRCLE BUTTON
  Widget _circleButton(IconData icon, bool isTablet) {
    return Container(
      height: isTablet ? 52.h : 44.h,
      width: isTablet ? 52.w : 44.w,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: AppColors.white,
        size: isTablet ? 22.sp : 18.sp,
      ),
    );
  }
}