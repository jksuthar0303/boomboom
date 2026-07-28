import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.black,

      body: CustomScrollView(
        slivers: [
          /// 🔥 COLLAPSING IMAGE
          SliverAppBar(
            expandedHeight: isTablet ? 700.h : 500.h,

            pinned: true,

            backgroundColor: Colors.black,

            leading: GestureDetector(
              onTap: () {
                Get.back();
              },

              child: Container(
                margin: EdgeInsets.all(10.w),

                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),

                  shape: BoxShape.circle,
                ),

                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),

            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,

                children: [
                  /// IMAGE
                  Image.network(user["image"], fit: BoxFit.cover),

                  /// OVERLAY
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,

                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),

                  /// SIDE BUTTONS
                  Positioned(
                    right: 18.w,
                    bottom: 120.h,

                    child: Column(
                      children: [
                        _circleButton(Icons.chat),

                        SizedBox(height: 14.h),

                        _circleButton(Icons.share),
                      ],
                    ),
                  ),

                  /// NAME
                  Positioned(
                    left: 22.w,
                    right: 22.w,
                    bottom: 40.h,

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          "${user["name"]} • ${user["age"]} • M",

                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 34.sp : 28.sp,

                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 8.h),

                        Text(
                          "${user["to"]}, 0 km",

                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isTablet ? 18.sp : 15.sp,
                          ),
                        ),

                        SizedBox(height: 10.h),

                        Row(
                          children: [
                            Icon(
                              Icons.work_outline,
                              color: Colors.white,
                              size: 18.sp,
                            ),

                            SizedBox(width: 6.w),

                            Text(
                              "${user["tag"]} men",

                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// BODY
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  /// ABOUT
                  Text(
                    "About",

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 14.h),

                  Text(
                    "I am a positive and ambitious person who believes in continuous learning and self-growth. "
                    "I enjoy exploring new ideas, building meaningful connections, and working on creative projects. "
                    "I stay focused on my goals and always look for opportunities to improve myself and help others.",

                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.6,
                      fontSize: isTablet ? 17.sp : 15.sp,
                    ),
                  ),

                  SizedBox(height: 26.h),

                  Divider(color: Colors.white24),

                  SizedBox(height: 20.h),

                  /// LIFESTYLE
                  Text(
                    "Lifestyle",

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 18.h),

                  GridView.count(
                    physics: NeverScrollableScrollPhysics(),

                    shrinkWrap: true,

                    crossAxisCount: isTablet ? 3 : 2,

                    crossAxisSpacing: 14.w,
                    mainAxisSpacing: 14.h,

                    childAspectRatio: isTablet ? 1.9 : 1.25,

                    children: [
                      _lifeCard("🌍", "Ethnicity", "Asian"),

                      _lifeCard("💪", "Body Type", "Average"),

                      _lifeCard("📏", "Height", "Tall (> 5'9\")"),

                      _lifeCard("🚭", "Smoking", "Occasional"),

                      _lifeCard("🍷", "Drinking", "Social"),

                      _lifeCard("🏃", "Workout", "Fitness Enthusiast"),
                    ],
                  ),

                  SizedBox(height: 28.h),

                  Divider(color: Colors.white24),

                  SizedBox(height: 20.h),

                  /// INTERESTS
                  Text(
                    "Interests",

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 18.h),

                  Wrap(
                    spacing: 10.w,
                    runSpacing: 10.h,

                    children: [
                      _interest("Fitness"),
                      _interest("Music"),
                      _interest("Travel"),
                      _interest("Photography"),
                      _interest("Cooking"),
                      _interest("Reading"),
                      _interest("Art"),
                    ],
                  ),
                  SizedBox(height: 30.h),

                  Divider(color: Colors.white24),

                  SizedBox(height: 20.h),

                  /// 🔥 GALLERY TITLE
                  Text(
                    "Gallery",

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 18.h),

                  /// 🔥 GALLERY GRID
                  GridView.builder(
                    shrinkWrap: true,

                    physics: NeverScrollableScrollPhysics(),

                    itemCount: 10,

                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTablet ? 3 : 2,

                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,

                      childAspectRatio: 0.75,
                    ),

                    itemBuilder: (_, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(22.r),

                        child: Image.network(user["image"], fit: BoxFit.cover),
                      );
                    },
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

  /// 🔥 INTEREST CHIP
  Widget _interest(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),

      decoration: BoxDecoration(
        color: const Color(0xFF111827),

        borderRadius: BorderRadius.circular(30.r),
      ),

      child: Text(
        text,

        style: TextStyle(color: Colors.white, fontSize: 15.sp),
      ),
    );
  }

  /// 🔥 LIFESTYLE CARD
  Widget _lifeCard(String emoji, String title, String value) {
    return Container(
      padding: EdgeInsets.all(14.w),

      decoration: BoxDecoration(
        color: const Color(0xFF111827),

        borderRadius: BorderRadius.circular(20.r),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Text(emoji, style: TextStyle(fontSize: 28.sp)),

          SizedBox(height: 10.h),

          Text(
            title,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: TextStyle(color: Colors.white54, fontSize: 13.sp),
          ),

          SizedBox(height: 4.h),

          Expanded(
            child: Align(
              alignment: Alignment.topLeft,

              child: Text(
                value,

                maxLines: 2,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 SIDE BUTTON
  Widget _circleButton(IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.w),

      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),

      child: Icon(icon, color: Colors.pink, size: 24.sp),
    );
  }
}
