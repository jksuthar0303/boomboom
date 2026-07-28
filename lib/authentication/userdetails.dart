import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../constant/apptextstyle.dart';
import '../../../constant/colors.dart';
import 'boomboom.dart';

class UserDetailScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserDetailScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: CustomScrollView(
        slivers: [
          /// 🔥 COLLAPSING IMAGE
          SliverAppBar(
            expandedHeight: 320.h,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: GestureDetector(
              onTap: () {
                Get.back();
              },
              child: Container(
                margin: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  /// 🔥 IMAGE
                  Image.network(
                    user["image"],
                    fit: BoxFit.cover,
                  ),

                  /// 🔥 OVERLAY
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// 🔥 BODY
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔥 TITLE CARD
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${user["tag"]} to ${user["to"]}",
                          style: AppTextStyles.subHeading.copyWith(
                            fontSize: 24.sp,
                          ),
                        ),

                        SizedBox(height: 16.h),

                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: Colors.white54,
                              size: 18.sp,
                            ),

                            SizedBox(width: 8.w),

                            Text(
                              "Jan 5 - Jan 5, 2026",
                              style: AppTextStyles.body.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 10.h),

                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.white54,
                              size: 18.sp,
                            ),

                            SizedBox(width: 8.w),

                            Text(
                              user["status"],
                              style: AppTextStyles.body.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 18.h),

                  /// 🔥 USER CARD
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32.r,
                          backgroundImage: NetworkImage(
                            user["image"],
                          ),
                        ),

                        SizedBox(width: 14.w),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user["name"],
                              style: AppTextStyles.subHeading,
                            ),

                            SizedBox(height: 4.h),

                            Text(
                              "${user["age"]} years",
                              style: AppTextStyles.body.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 18.h),

                  /// 🔥 TAGS
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: Row(
                      children: [
                        _tag(
                          user["tag"],
                          Colors.deepPurple,
                        ),

                        SizedBox(width: 12.w),

                        _tag(
                          "Solo",
                          Colors.pink,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 18.h),

                  /// 🔥 DESCRIPTION
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Description",
                          style: AppTextStyles.subHeading,
                        ),

                        SizedBox(height: 12.h),

                        Text(
                          user["description"] ??
                              "Looking for a fun and safe travel partner. Love music, coffee, long drives and exploring new places together.",
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white70,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 18.h),

                  /// 🔥 ROUTE
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Route",
                          style: AppTextStyles.subHeading,
                        ),

                        SizedBox(height: 18.h),

                        _routeBox(
                          "DEPARTURE FROM",
                          user["from"],
                          Icons.location_on,
                          Colors.deepPurple,
                        ),

                        SizedBox(height: 16.h),

                        _routeBox(
                          "DESTINATION",
                          user["to"],
                          Icons.flag,
                          Colors.pink,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30.h),

                  /// 🔥 SAY HI BUTTON
                  GestureDetector(
                    onTap: () {
                      Get.snackbar(
                        "Say Hi 👋",
                        "Message sent successfully",
                        backgroundColor: Colors.deepPurple,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: 16.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pink,
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      child: Center(
                        child: Text(
                          "Say Hi",
                          style: AppTextStyles.button.copyWith(
                            fontSize: 18.sp,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  /// 🔥 VIEW PROFILE BUTTON
                  GestureDetector(
                    onTap: () {
                      Get.to(() => BoomProfileScreen(
                        showStar: false,
                        showMore: false,
                        showTelegram: false,
                      ),
                        transition: Transition.rightToLeft,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: 16.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8B5CF6),
                            Color(0xFF6D28D9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      child: Center(
                        child: Text(
                          "View Profile",
                          style: AppTextStyles.button.copyWith(
                            fontSize: 18.sp,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 TAG
  Widget _tag(
      String text,
      Color color,
      ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: color,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 10.sp,
            color: color,
          ),

          SizedBox(width: 8.w),

          Text(
            text,
            style: AppTextStyles.body.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 ROUTE BOX
  Widget _routeBox(
      String title,
      String location,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
          ),

          SizedBox(width: 14.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.small.copyWith(
                    color: Colors.white54,
                    letterSpacing: 1,
                  ),
                ),

                SizedBox(height: 6.h),

                Text(
                  location,
                  style: AppTextStyles.subHeading.copyWith(
                    fontSize: 20.sp,
                  ),
                ),

                SizedBox(height: 4.h),

                Text(
                  location,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white54,
                  ),
                ),

                SizedBox(height: 12.h),

                Text(
                  "View on Map ↗",
                  style: AppTextStyles.body.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}