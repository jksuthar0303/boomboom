import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../authentication/boomboom.dart';
import '../../../../authentication/messagedetail.dart';
import '../../../../constant/apptextstyle.dart';
import '../../../../constant/colors.dart';
import '../../../../widget/app_image_helper.dart';

class ProfileDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProfileDetailsScreen({
    super.key,
    this.data = const {},
  });

  String _calculateAgeFromDob(dynamic dobVal, dynamic ageVal) {
    if (ageVal != null &&
        ageVal.toString().trim().isNotEmpty &&
        ageVal.toString().trim() != "null") {
      return ageVal.toString().trim();
    }
    if (dobVal == null) return "";
    final String str = dobVal.toString().trim();
    if (str.isEmpty || str == "null") return "";
    try {
      final dob = DateTime.parse(str);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age > 0 ? "$age" : "";
    } catch (_) {
      return "";
    }
  }

  IconData _getPlanningIcon(String plan) {
    final p = plan.toLowerCase();
    if (p.contains("dinner") || p.contains("food") || p.contains("meal")) {
      return Icons.restaurant_rounded;
    }
    if (p.contains("party") || p.contains("club") || p.contains("night")) {
      return Icons.celebration_rounded;
    }
    if (p.contains("drink") || p.contains("bar")) {
      return Icons.local_bar_rounded;
    }
    if (p.contains("chat") || p.contains("meet")) {
      return Icons.forum_rounded;
    }
    return Icons.local_activity_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    // 🛡️ Safe field extraction from Tonight API response
    final String email = (data["EmailAddress"] ??
            data["TonightEmail"] ??
            data["Email"] ??
            data["email"] ??
            "")
        .toString()
        .trim();

    final String rawName = (data["FullName"] ??
            data["Name"] ??
            data["name"] ??
            (email.isNotEmpty ? email.split('@').first : "Traveler"))
        .toString()
        .trim();

    final String age = _calculateAgeFromDob(data["Dob"], data["Age"] ?? data["age"]);
    final String nameDisplay = age.isNotEmpty ? "$rawName, $age" : rawName;

    final String planning = (data["Planning"] ?? data["tag"] ?? "Dinner").toString().trim();

    final String image = (data["Image"] ??
            data["ProfileImage"] ??
            data["image"] ??
            data["Media"] ??
            "")
        .toString()
        .trim();

    final String location = (data["Location"] ??
            data["FromCity"] ??
            data["City"] ??
            data["location"] ??
            "Nearby")
        .toString()
        .trim();

    final String distanceKM = (data["DistanceKM"] ?? "").toString().trim();
    final String distance = distanceKM.isNotEmpty && distanceKM != "null"
        ? "$distanceKM km away"
        : ((data["Distance"] ?? data["distance"] ?? "1.2 km away").toString());

    final String height = (data["Height"] ?? data["height"] ?? "5'4\"").toString().trim();

    final String rawBio = (data["BIO"] ?? data["bio"] ?? "").toString().trim();
    final String bio = rawBio.isNotEmpty
        ? rawBio
        : "Looking to make good memories tonight ✨";

    final String rawLookingFor = (data["TonightDescription"] ??
            data["Lookingfor"] ??
            data["Description"] ??
            "")
        .toString()
        .trim();
    final String lookingFor = rawLookingFor.isNotEmpty
        ? rawLookingFor
        : "I'm up for good conversations, sharing laughs, and maybe grabbing dinner or exploring the city. Looking for someone who's kind, interesting, and spontaneous.";

    final bool isOnline = data["IsOnline"]?.toString().toLowerCase() == "true" ||
        data["isOnline"]?.toString().toLowerCase() == "true";

    final bool isVerified = data["IsVerified"]?.toString().toLowerCase() == "true" ||
        data["isVerified"]?.toString().toLowerCase() == "true";

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 1. 🔝 TOP BAR
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24.w : 16.w,
                  vertical: isTablet ? 16.h : 12.h,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: _circleButton(Icons.arrow_back_ios_new_rounded, isTablet),
                    ),
                  ],
                ),
              ),

              /// 2. 👤 PROFILE HEADER ROW
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
                        AppAvatar(
                          imageUrl: image,
                          radius: isTablet ? 50.r : 40.r,
                          backgroundColor: const Color(0xFF1B2236),
                        ),

                        /// Online dot
                        Positioned(
                          top: 2.h,
                          right: 2.w,
                          child: Container(
                            height: isTablet ? 14.h : 12.h,
                            width: isTablet ? 14.w : 12.w,
                            decoration: BoxDecoration(
                              color: isOnline ? AppColors.green : Colors.grey,
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
                              style: TextStyle(fontSize: isTablet ? 18.sp : 14.sp),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(width: 14.w),

                    /// NAME + INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Name + verified
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  nameDisplay,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.white,
                                    fontSize: isTablet ? 26.sp : 20.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Icon(
                                isVerified ? Icons.verified_rounded : Icons.verified,
                                color: Colors.blue,
                                size: isTablet ? 22.sp : 18.sp,
                              ),
                            ],
                          ),

                          SizedBox(height: 6.h),

                          /// Location | Height | Activity
                          Wrap(
                            spacing: 6.w,
                            runSpacing: 4.h,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _metaChip(
                                Icons.location_on_rounded,
                                Colors.pinkAccent,
                                distance,
                                isTablet,
                              ),
                              _divider(),
                              _metaChip(
                                Icons.height_rounded,
                                AppColors.textSecondary,
                                height,
                                isTablet,
                              ),
                              _divider(),
                              _metaChip(
                                _getPlanningIcon(planning),
                                AppColors.textSecondary,
                                planning,
                                isTablet,
                              ),
                            ],
                          ),

                          SizedBox(height: 8.h),

                          /// FREE TONIGHT chip
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(30.r),
                              border: Border.all(
                                color: AppColors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7.w,
                                  height: 7.w,
                                  decoration: const BoxDecoration(
                                    color: Colors.pinkAccent,
                                    shape: BoxShape.circle,
                                  ),
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
                                  "7h 23m",
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

              SizedBox(height: 12.h),

              /// 3. 📝 BIO TEXT
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.w : 16.w),
                child: Text(
                  bio,
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: isTablet ? 14.sp : 12.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              SizedBox(height: 14.h),

              /// 4. 📸 MAIN PHOTO with location tag
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.w : 16.w),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: AppNetworkImage(
                        imageUrl: image,
                        width: double.infinity,
                        height: isTablet ? 340.h : 260.h,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.nightlife_rounded,
                        fallbackIconSize: 64.sp,
                        backgroundColor: const Color(0xFF161E31),
                      ),
                    ),

                    /// Dark Gradient
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.6, 1.0],
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                      ),
                    ),

                    /// Location overlay
                    Positioned(
                      bottom: 12.h,
                      left: 12.w,
                      right: 12.w,
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: Colors.pinkAccent,
                            size: isTablet ? 16.sp : 14.sp,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: AppColors.white,
                                fontSize: isTablet ? 13.sp : 11.5.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 14.h),

              /// 5. 💖 WHAT I'M LOOKING FOR CARD
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
                              lookingFor,
                              style: AppTextStyles.body.copyWith(
                                fontSize: isTablet ? 13.sp : 11.5.sp,
                                height: 1.6,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        "🥂",
                        style: TextStyle(fontSize: isTablet ? 40.sp : 32.sp),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 14.h),

              /// 6. 💬 SAY HELLO CARD
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.w : 16.w),
                child: GestureDetector(
                  onTap: () {
                    Get.to(
                      () => MessageDetailPage(
                        index: 0,
                        messageData: {
                          "name": rawName,
                          "image": image,
                          "age": age,
                          "gender": data["Gender"] ?? "M",
                          "city": location,
                          "flag": "🇮🇳",
                          "email": email,
                        },
                      ),
                      transition: Transition.rightToLeft,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20.w : 16.w,
                      vertical: isTablet ? 18.h : 14.h,
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              color: Colors.blueAccent,
                              size: isTablet ? 18.sp : 14.sp,
                            ),
                            SizedBox(height: 6.h),
                            Icon(
                              Icons.star_rounded,
                              color: Colors.blueAccent,
                              size: isTablet ? 12.sp : 10.sp,
                            ),
                          ],
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Say Hello 👋",
                                style: GoogleFonts.poppins(
                                  color: AppColors.white,
                                  fontSize: isTablet ? 17.sp : 14.5.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                "Don't be shy! Start a conversation and see where the night takes you.",
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: isTablet ? 12.sp : 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
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
                            size: isTablet ? 22.sp : 18.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              /// 7. 👤 VIEW PROFILE BUTTON
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.w : 16.w),
                child: GestureDetector(
                  onTap: () {
                    Get.to(
                      () => BoomProfileScreen(
                        userEmail: email,
                        initialUserData: data,
                        showStar: false,
                        showMore: false,
                        showTelegram: false,
                      ),
                      transition: Transition.rightToLeft,
                    );
                  },
                  child: Container(
                    height: isTablet ? 60.h : 52.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18.r),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF7B2FBE),
                          Colors.pinkAccent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_rounded,
                          color: AppColors.white,
                          size: isTablet ? 22.sp : 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          "View Profile",
                          style: AppTextStyles.button.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
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
      height: isTablet ? 50.h : 42.h,
      width: isTablet ? 50.w : 42.w,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: AppColors.white,
        size: isTablet ? 20.sp : 16.sp,
      ),
    );
  }
}