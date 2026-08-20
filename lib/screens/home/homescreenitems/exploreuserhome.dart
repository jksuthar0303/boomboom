import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../constant/apptextstyle.dart';
import '../../../../constant/colors.dart';
import '../../../authentication/boomboom.dart';
//import 'profile_details_screen.dart';

class ExploreUsersScreen extends StatelessWidget {
  const ExploreUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> users = [
      {
        "name": "User 1",
        "age": "25",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
      },

      {
        "name": "User 2",
        "age": "25",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
      },

      {
        "name": "User 3",
        "age": "25",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1438761681033-6461ffad8d80",
      },

      {
        "name": "User 4",
        "age": "25",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d",
      },

      {
        "name": "User 5",
        "age": "25",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1517841905240-472988babdf9",
      },

      {
        "name": "User 6",
        "age": "25",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1521119989659-a83eee488004",
      },

      {
        "name": "User 7",
        "age": "24",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1488426862026-3ee34a7d66df",
      },

      {
        "name": "User 8",
        "age": "26",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1504593811423-6dd665756598",
      },

      {
        "name": "User 9",
        "age": "23",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1524504388940-b1c1722653e1",
      },

      {
        "name": "User 10",
        "age": "27",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1521572267360-ee0c2909d518",
      },

      {
        "name": "User 11",
        "age": "24",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e",
      },

      {
        "name": "User 12",
        "age": "28",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1504257432389-52343af06ae3",
      },

      {
        "name": "User 13",
        "age": "25",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1492562080023-ab3db95bfbce",
      },

      {
        "name": "User 14",
        "age": "26",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1544005313-94ddf0286df2",
      },

      {
        "name": "User 15",
        "age": "25",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
      },

      {
        "name": "User 16",
        "age": "22",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
      },

      {
        "name": "User 17",
        "age": "29",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1519345182560-3f2917c472ef",
      },

      {
        "name": "User 18",
        "age": "23",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1517365830460-955ce3ccd263",
      },

      {
        "name": "User 19",
        "age": "25",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1521572267360-ee0c2909d518",
      },

      {
        "name": "User 20",
        "age": "24",
        "country": "India",
        "image": "https://images.unsplash.com/photo-1524504388940-b1c1722653e1",
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,

      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,

        centerTitle: true,

        title: Text(
          "Explore Users",
          style: AppTextStyles.subHeading.copyWith(color: Colors.white),
        ),
      ),

      body: GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: 4.w),

        itemCount: users.length,

        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,

          crossAxisSpacing: 5.w,

          mainAxisSpacing: 5.h,

          childAspectRatio: 0.62,
        ),

        itemBuilder: (_, index) {
          final user = users[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BoomProfileScreen(
                    userEmail:
                        user["EmailAddress"]?.toString() ??
                        user["email"]?.toString(),
                    initialUserData: user,
                  ),
                ),
              );
            },

            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26.r),

                color: AppColors.cardBg,

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(26.r),

                child: Stack(
                  children: [
                    /// 🔥 IMAGE
                    Positioned.fill(
                      child: Image.network(user["image"], fit: BoxFit.cover),
                    ),

                    /// 🔥 OVERLAY
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,

                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),
                    ),

                    /// NEW BADGE
                    Positioned(
                      top: 10.h,
                      left: 10.w,

                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),

                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          ),
                        ),

                        child: Text(
                          "NEW",

                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9.sp,
                          ),
                        ),
                      ),
                    ),

                    /// HEART ICON
                    Positioned(
                      top: 10.h,
                      right: 10.w,
                      child: Icon(
                        Icons.favorite_border_rounded,
                        color: Colors.white,
                        size: 26.sp,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),

                    /// 🔥 BOTTOM INFO
                    /// BOTTOM INFO
                    Positioned(
                      left: 6.w,
                      right: 6.w,
                      bottom: 6.h,

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          /// NAME
                          Row(
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,

                                  children: [
                                    Flexible(
                                      child: Text(
                                        "${user["name"]}, ${user["age"]}",

                                        maxLines: 1,

                                        overflow: TextOverflow.ellipsis,

                                        style: TextStyle(
                                          color: Colors.white,

                                          fontWeight: FontWeight.w900,

                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ),

                                    SizedBox(width: 1.w),

                                    Icon(
                                      Icons.verified_rounded,
                                      color: Colors.blueAccent,
                                      size: 10.sp,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 2.h),

                          /// LOCATION
                          /// BADGES ROW 1
                          /// COUNTRY
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 1.h,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.32),

                              borderRadius: BorderRadius.circular(18.r),
                            ),

                            child: Row(
                              mainAxisSize: MainAxisSize.min,

                              children: [
                                Text(
                                  countryFlag(user["country"]?.toString() ?? ""),
                                  style: TextStyle(fontSize: 8.sp),
                                ),

                                SizedBox(width: 1.w),

                                Text(
                                  user["country"],

                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 2.h),

                          /// DISTANCE
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 2.h,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.32),

                              borderRadius: BorderRadius.circular(18.r),
                            ),

                            child: Row(
                              mainAxisSize: MainAxisSize.min,

                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white,
                                  size: 9.sp,
                                ),

                                SizedBox(width: 1.w),

                                Text(
                                  "${(index + 1) * 2} km away",

                                  overflow: TextOverflow.ellipsis,

                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 2.h),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5.w,
                                      height: 5.w,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00E676),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1,
                                        ),
                                      ),
                                    ),

                                    SizedBox(width: 3.w),

                                    Text(
                                      "Active now",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30.r),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF291FC8),
                                      Color(0xFFFF6C9E),
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(
                                  1.5,
                                ), // ✅ Yahi gradient border hai
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(29.r),
                                    color: Colors
                                        .black, // ✅ Andar black background
                                  ),
                                  child: Text(
                                    index % 2 == 0 ? "Friendship" : "Casual",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
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
          );
        },
      ),
    );
  }
}
