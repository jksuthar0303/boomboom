import 'package:boomboom/authentication/boomboom.dart';
import 'package:boomboom/screens/home/homescreenitems/exploreuserhome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../constant/appsize.dart';
import '../../../constant/apptextstyle.dart';
import '../../../constant/colors.dart';

class FullCardScreen extends StatelessWidget {
  const FullCardScreen({super.key});

  final List<String> images = const [
    "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e",
    "https://images.unsplash.com/photo-1534528741775-53994a69daeb",
    "https://images.unsplash.com/photo-1517841905240-472988babdf9",
    "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
    "https://images.unsplash.com/photo-1524504388940-b1c1722653e1",
    "https://images.unsplash.com/photo-1519340333755-c6e5d7b9f0f7",
  ];

  @override
  Widget build(BuildContext context) {

    return ListView.builder(
      scrollDirection: Axis.horizontal,

      /// 🔥 +1 FOR SEE ALL CARD
      itemCount: images.length + 1,

      itemBuilder: (_, index) {

        /// 🔥 SEE ALL CARD
        if (index == images.length) {

          return GestureDetector(

            onTap: () {
              Get.to(() => const ExploreUsersScreen());
            },
            child: Container(
              width: AppSize.w(280),
              height: AppSize.h(420),

              margin: EdgeInsets.only(
                right: AppSize.w(12),
              ),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.r),

                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,

                  colors: [
                    Color(0xFFFF6A00),
                    Color(0xFFFFC000),
                  ],
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  /// 🔥 ICON
                  Container(
                    height: 85.h,
                    width: 85.w,

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),

                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 42.sp,
                    ),
                  ),

                  SizedBox(height: 22.h),

                  /// 🔥 TITLE
                  Text(
                    "See All",

                    style: AppTextStyles.heading.copyWith(
                      color: Colors.white,
                      fontSize: 28.sp,
                    ),
                  ),

                  SizedBox(height: 10.h),

                  /// 🔥 SUBTITLE
                  Text(
                    "Explore More Profiles",

                    style: AppTextStyles.body.copyWith(
                      color: Colors.white70,
                      fontSize: 13.sp,
                    ),
                  ),

                  SizedBox(height: 30.h),

                  /// 🔥 BUTTON
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 22.w,
                      vertical: 12.h,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30.r),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Text(
                          "Open",

                          style: AppTextStyles.body.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(width: 8.w),

                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.black,
                          size: 14.sp,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }


        /// 🔥 NORMAL USER CARD
        return GestureDetector(

          onTap: () {

            Get.to(() => BoomProfileScreen());
          },

          child: _card(images[index]),
        );
      },
    );
  }

  /// 🔥 USER CARD
  Widget _card(String image) {

    return Container(
      width: AppSize.w(280),
      height: AppSize.h(420),

      margin: EdgeInsets.only(
        right: AppSize.w(12),
      ),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.r),
        color: AppColors.secondary,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 10,
          )
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(25.r),

        child: Stack(
          children: [

            /// 🔥 IMAGE
            Image.network(
              image,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),

            /// 🔥 TOP INFO
            /// 🔥 TOP INFO
            Positioned(
              top: 15.h,
              left: 15.w,
              right: 15.w,

              child: Row(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Expanded(

                    child: Column(

                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        /// NAME + VERIFIED
                        Row(

                          children: [

                            Expanded(

                              child: Text(

                                "Taniya Agarwal, 32",

                                maxLines: 1,

                                overflow:
                                TextOverflow.ellipsis,

                                style:
                                AppTextStyles.heading.copyWith(
                                  fontSize: 17.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            SizedBox(width: 4.w),

                            Icon(
                              Icons.verified_rounded,
                              color: Colors.blueAccent,
                              size: 18.sp,
                            ),
                          ],
                        ),

                        SizedBox(height: 8.h),

                        /// COUNTRY
                        Container(

                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),

                          decoration: BoxDecoration(
                            color:
                            Colors.black.withValues(alpha: 0.35),

                            borderRadius:
                            BorderRadius.circular(20.r),
                          ),

                          child: Row(

                            mainAxisSize: MainAxisSize.min,

                            children: [

                              Text(
                                "🇮🇳",
                                style: TextStyle(fontSize: 10.sp),
                              ),

                              SizedBox(width: 4.w),

                              Text(

                                "New Delhi, India",

                                style:
                                AppTextStyles.small.copyWith(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 6.h),

                        /// ONLINE NOW
                        Container(

                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),

                          decoration: BoxDecoration(
                            color:
                            Colors.black.withValues(alpha: 0.35),

                            borderRadius:
                            BorderRadius.circular(20.r),
                          ),

                          child: Row(

                            mainAxisSize: MainAxisSize.min,

                            children: [

                              Container(
                                width: 7.w,
                                height: 7.w,

                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E676),
                                  shape: BoxShape.circle,

                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                              ),

                              SizedBox(width: 5.w),

                              Text(

                                "Online now",

                                style:
                                AppTextStyles.small.copyWith(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 10.w),

                  /// ❤️ FAVORITE ICON
                  Container(
                    padding: EdgeInsets.all(8.w),

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                      Colors.black.withValues(alpha: 0.35),

                      border: Border.all(
                        color: Colors.white24,
                      ),
                    ),

                    child: Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ],
              ),
            ),

            /// 🔥 BOTTOM OVERLAY
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,

              child: Container(
                padding: EdgeInsets.all(
                  AppSize.w(12),
                ),

                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],

                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),

                child: Column(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    /// DISTANCE + RELATIONSHIP
                    Row(

                      children: [

                        Container(

                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),

                            borderRadius:
                            BorderRadius.circular(18.r),
                          ),

                          child: Row(

                            children: [

                              Icon(
                                Icons.location_on,
                                color: Colors.purpleAccent,
                                size: 12.sp,
                              ),

                              SizedBox(width: 4.w),

                              Text(

                                "1.2 km",

                                style:
                                AppTextStyles.small.copyWith(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 8.w),

                        Container(

                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),

                            borderRadius:
                            BorderRadius.circular(18.r),
                          ),

                          child: Row(

                            children: [

                              Icon(
                                Icons.favorite,
                                color: Colors.pinkAccent,
                                size: 11.sp,
                              ),

                              SizedBox(width: 4.w),

                              Text(

                                "Long Term",

                                style:
                                AppTextStyles.small.copyWith(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    /// MESSAGE BOX
                    Row(
                      children: [

                        Expanded(
                          child: Container(
                            height: 45.h,

                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),

                              borderRadius:
                              BorderRadius.circular(30.r),

                              border: Border.all(
                                color: Colors.white12,
                              ),
                            ),

                            child: Row(
                              children: [

                                /// TEXT
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: 15.w,
                                    ),
                                    child: Text(
                                      "Send message...",
                                      style: AppTextStyles.body.copyWith(
                                        color: Colors.white70,
                                        fontSize: AppSize.sp(12),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    // TODO: apna send message function yahan call karo
                                  },
                                  child: Container(
                                    height: double.infinity,
                                    width: 42 .w,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        "assets/arroriconimage.png",
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),

                                /// SEND BUTTON

                              ],
                            ),
                          ),
                        ),

                        SizedBox(width: 10.w),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}