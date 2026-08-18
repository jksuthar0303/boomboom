import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../widget/app_image_helper.dart';
import 'boomboom.dart';

class UserDetailScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserDetailScreen({super.key, required this.user});

  String _formatTravelDates(String? fromDateStr, String? toDateStr) {
    if ((fromDateStr == null || fromDateStr.trim().isEmpty) &&
        (toDateStr == null || toDateStr.trim().isEmpty)) {
      return "Upcoming Trip";
    }

    try {
      DateTime? from;
      DateTime? to;
      if (fromDateStr != null && fromDateStr.trim().isNotEmpty) {
        from = DateTime.parse(fromDateStr.trim());
      }
      if (toDateStr != null && toDateStr.trim().isNotEmpty) {
        to = DateTime.parse(toDateStr.trim());
      }

      if (from != null && to != null) {
        final fDay = DateFormat('d MMM').format(from); // e.g. 18 Aug
        final tDay = DateFormat('d MMM, yyyy').format(to); // e.g. 25 Aug, 2026
        if (from.year != to.year) {
          final fDayFull = DateFormat('d MMM, yyyy').format(from);
          return "$fDayFull - $tDay";
        }
        return "$fDay - $tDay";
      } else if (from != null) {
        return DateFormat('d MMM, yyyy').format(from);
      } else if (to != null) {
        return DateFormat('d MMM, yyyy').format(to);
      }
    } catch (_) {}

    return "${fromDateStr ?? ''} ${toDateStr != null && toDateStr.isNotEmpty ? '- $toDateStr' : ''}"
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    // 🛡️ Safe field extractions
    final String fromCity = (user["FromCity"] ?? "").toString().trim();
    final String fromCountry = (user["FromCountry"] ?? user["from"] ?? "")
        .toString()
        .trim();
    final String fromLocation = fromCountry.isNotEmpty
        ? fromCountry
        : (fromCity.isNotEmpty ? fromCity : "Departure");
    final String fromSubtitle = fromCity.isNotEmpty ? fromCity : fromLocation;

    final String toCity = (user["ToCity"] ?? "").toString().trim();
    final String toCountry = (user["ToCountry"] ?? user["to"] ?? "")
        .toString()
        .trim();
    final String toLocation = toCountry.isNotEmpty
        ? toCountry
        : (toCity.isNotEmpty ? toCity : "Destination");
    final String toSubtitle = toCity.isNotEmpty ? toCity : toLocation;

    final String journeyType = (user["JourneyType"] ?? user["tag"] ?? "Travel")
        .toString()
        .trim();
    final String travelStyle = (user["TravelStyle"] ?? "Solo")
        .toString()
        .trim();
    final String travelCompanion =
        (user["TravelCompanion"] ?? user["companion"] ?? "").toString().trim();

    final String fromDate = (user["FromDate"] ?? "").toString().trim();
    final String toDate = (user["ToDate"] ?? "").toString().trim();
    final String dateDisplay = _formatTravelDates(fromDate, toDate);

    // Duration calculation
    String durationDisplay = (user["duration"] ?? "").toString().trim();
    if (durationDisplay.isEmpty) {
      if (fromDate.isNotEmpty && toDate.isNotEmpty) {
        try {
          final f = DateTime.parse(fromDate);
          final t = DateTime.parse(toDate);
          final diff = t.difference(f).inDays.abs();
          durationDisplay = diff == 0 ? "1 day" : "$diff days";
        } catch (_) {
          durationDisplay = "2 days";
        }
      } else if (fromDate.isNotEmpty) {
        try {
          final f = DateTime.parse(fromDate);
          final diff = f.difference(DateTime.now()).inDays.abs();
          durationDisplay = diff == 0 ? "Today" : "$diff days";
        } catch (_) {
          durationDisplay = "2 days";
        }
      } else {
        durationDisplay = "2 days";
      }
    }

    final String rawDesc =
        (user["Description"] ?? user["BIO"] ?? user["description"] ?? "")
            .toString()
            .trim();
    final String description = rawDesc.isNotEmpty
        ? rawDesc
        : "Looking for a fun and safe travel partner. Love music, coffee, long drives and exploring new places together.";

    final String email =
        (user["Email"] ?? user["EmailAddress"] ?? user["email"] ?? "")
            .toString()
            .trim();
    final String rawName =
        (user["FullName"] ?? user["Name"] ?? user["name"] ?? "")
            .toString()
            .trim();
    final String name = rawName.isNotEmpty
        ? rawName
        : (email.isNotEmpty ? email.split('@').first : "Traveler");

    // Age from Dob or Age field
    String age = (user["Age"] ?? user["age"] ?? "").toString().trim();
    if (age.isEmpty || age == "null") {
      final dobStr = (user["Dob"] ?? user["DOB"] ?? user["dob"] ?? "")
          .toString()
          .trim();
      if (dobStr.isNotEmpty && dobStr != "null") {
        try {
          final dob = DateTime.parse(dobStr);
          final now = DateTime.now();
          int a = now.year - dob.year;
          if (now.month < dob.month ||
              (now.month == dob.month && now.day < dob.day)) {
            a--;
          }
          if (a > 0) age = "$a";
        } catch (_) {}
      }
    }
    final String ageDisplay = age.isNotEmpty
        ? "$age years"
        : (email.isNotEmpty ? email : "Traveler");

    final String image =
        (user["ProfileImage"] ??
                user["image"] ??
                user["Media"] ??
                user["profileImage"] ??
                "")
            .toString()
            .trim();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F17),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          /// 🔥 TOP COLLAPSING HERO IMAGE
          SliverAppBar(
            expandedHeight: 330.h,
            pinned: true,
            backgroundColor: const Color(0xFF0D0F17),
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                margin: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: Colors.white, size: 20.sp),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.person,
                    fallbackIconSize: 80.sp,
                    backgroundColor: const Color(0xFF161E31),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.2),
                          const Color(0xFF0D0F17),
                        ],
                        stops: const [0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// 🔥 BODY CONTENT
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 1. 🏷️ TITLE & DATES CARD
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A2A),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$journeyType to $toLocation",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              color: Colors.white54,
                              size: 18.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              dateDisplay,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: Colors.white54,
                              size: 18.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              durationDisplay,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  /// 2. 👤 TRAVELER INFO CARD
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A2A),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: Row(
                      children: [
                        AppAvatar(
                          imageUrl: image,
                          radius: 28.r,
                          backgroundColor: const Color(0xFF1F293D),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                ageDisplay,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  /// 3. 🏷️ TAGS ROW (Business, Solo, etc.)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A2A),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: Wrap(
                      spacing: 12.w,
                      runSpacing: 10.h,
                      children: [
                        _tag(journeyType, const Color(0xFF8E2DE2)),
                        if (travelStyle.isNotEmpty)
                          _tag(travelStyle, const Color(0xFFFF2D55)),
                        if (travelCompanion.isNotEmpty)
                          _tag(travelCompanion, const Color(0xFF00E676)),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  /// 4. 📝 DESCRIPTION CARD
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A2A),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Description",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13.5.sp,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  /// 5. 🗺️ ROUTE CARD
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A2A),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Route",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _routeBox(
                          "DEPARTURE FROM",
                          fromLocation,
                          fromSubtitle,
                          Icons.location_on,
                          const Color(0xFF8E2DE2),
                        ),
                        SizedBox(height: 14.h),
                        _routeBox(
                          "DESTINATION",
                          toLocation,
                          toSubtitle,
                          Icons.flag,
                          const Color(0xFFFF2D55),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  /// 6. 💬 SAY HI BUTTON
                  GestureDetector(
                    onTap: () {
                      Get.snackbar(
                        "Say Hi 👋",
                        "Message sent successfully to $name",
                        backgroundColor: const Color(0xFFFF2D55),
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2D55),
                        borderRadius: BorderRadius.circular(18.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFF2D55,
                            ).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "Say Hi",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 14.h),

                  /// 7. 👤 VIEW PROFILE BUTTON
                  GestureDetector(
                    onTap: () {
                      Get.to(
                        () => BoomProfileScreen(
                          userEmail: email,
                          initialUserData: user,
                          showStar: false,
                          showMore: false,
                          showTelegram: false,
                        ),
                        transition: Transition.rightToLeft,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        ),
                        borderRadius: BorderRadius.circular(18.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "View Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🏷️ TAG PILL (with bullet dot)
  Widget _tag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8.sp, color: color),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 🗺️ ROUTE BOX (Departure / Destination)
  Widget _routeBox(
    String title,
    String mainLocation,
    String subLocation,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10.sp,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  mainLocation,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  subLocation,
                  style: TextStyle(color: Colors.white54, fontSize: 13.sp),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
