// view_profile_screen.dart
//
// 📌 Ye "VIEW" profile screen hai — sirf data DISPLAY karta hai,
// koi TextField / input nahi hai. Edit screen alag se hai jo
// aapne already bana rakhi hai.
//
// 📌 REQUIRED PACKAGES (pubspec.yaml):
//   flutter_screenutil: ^5.9.3
//   google_fonts: ^6.2.1
//   cached_network_image: ^3.4.1   👈 caching ke liye zaroori
//
// 📌 NOTE: main.dart mein ScreenUtilInit already lagaya hua hona chahiye.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ─────────────────────────────────────────────────────────
// 🎨 THEME / COLORS
// ─────────────────────────────────────────────────────────
class AppColors {
  static const Color bg = Color(0xFF0A0A0A);
  static const Color card = Color(0xFF141414);
  static const Color cardBorder = Color(0xFF262626);
  static const Color accent = Color(0xFFFF2D78); // neon pink
  static const Color accent2 = Color(0xFF7A3CFF); // purple
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color chipBg = Color(0xFF1C1C1C);
}

// ─────────────────────────────────────────────────────────
// 📦 MODEL (Ye data aapko API / Edit screen se milega,
// abhi demo ke liye static rakha hai)
// ─────────────────────────────────────────────────────────
class UserProfile {
  final String name;
  final String email;
  final DateTime dob;
  final String gender;
  final String orientation;
  final String lookingFor;
  final List<String> interests;
  final String smoking;
  final String drinking;
  final String work;
  final String height;
  final String bodyType;
  final String personalityType;
  final List<String> languages;
  final List<String> photos;

  UserProfile({
    required this.name,
    required this.email,
    required this.dob,
    required this.gender,
    required this.orientation,
    required this.lookingFor,
    required this.interests,
    required this.smoking,
    required this.drinking,
    required this.work,
    required this.height,
    required this.bodyType,
    required this.personalityType,
    required this.languages,
    required this.photos,
  });

  int get age {
    final now = DateTime.now();
    int a = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      a--;
    }
    return a;
  }

  String get dobFormatted =>
      "${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}";
}

// ─────────────────────────────────────────────────────────
// 📱 VIEW PROFILE SCREEN
// ─────────────────────────────────────────────────────────
class ViewProfileScreen extends StatelessWidget {
  final UserProfile profile;

  const ViewProfileScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── HEADER WITH MAIN PHOTO ─────────────────
            SliverToBoxAdapter(child: _buildHeader(context)),

            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 40.h),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildNameAgeRow(),
                  SizedBox(height: 4.h),
                  _buildInfoLine(Icons.email_outlined, profile.email),
                  SizedBox(height: 20.h),

                  _buildQuickInfoGrid(),

                  SizedBox(height: 24.h),
                  _sectionTitle("Looking For"),
                  SizedBox(height: 10.h),
                  _highlightPill(profile.lookingFor, Icons.favorite_rounded),

                  SizedBox(height: 24.h),
                  _sectionTitle("Interests"),
                  SizedBox(height: 10.h),
                  _buildChipWrap(profile.interests),

                  SizedBox(height: 24.h),
                  _sectionTitle("Lifestyle"),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: _lifestyleCard(
                          icon: Icons.smoking_rooms_outlined,
                          label: "Smoking",
                          value: profile.smoking,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _lifestyleCard(
                          icon: Icons.local_bar_outlined,
                          label: "Drinking",
                          value: profile.drinking,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),
                  _sectionTitle("Languages"),
                  SizedBox(height: 10.h),
                  _buildChipWrap(profile.languages, color: AppColors.accent2),

                  SizedBox(height: 24.h),
                  _sectionTitle("Photos"),
                  SizedBox(height: 10.h),
                  _buildPhotoGrid(),

                  SizedBox(height: 32.h),
                  // _buildActionButtons(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // 🖼 HEADER (cover photo + back button)
  // ─────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 500.h,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28.r),
              bottomRight: Radius.circular(28.r),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: profile.photos.isNotEmpty
                    ? profile.photos.first
                    : "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e",
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade900,
                  child: Center(
                    child: SizedBox(
                      width: 26.w,
                      height: 26.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade900,
                  child: Icon(Icons.person, color: Colors.white24, size: 90.sp),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 8.h,
          left: 8.w,
          child: GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.4),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  // 🏷 NAME + AGE + VERIFIED BADGE
  // ─────────────────────────────────────────────────────
  Widget _buildNameAgeRow() {
    return Row(
      children: [
        Text(
          "${profile.name}, ${profile.age}",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: 6.w),
        Icon(Icons.verified_rounded, color: AppColors.accent, size: 20.sp),
      ],
    );
  }

  Widget _buildInfoLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 14.sp),
        SizedBox(width: 6.w),
        Text(
          text,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 12.5.sp,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  // 🧩 QUICK INFO GRID (DOB, Work, Height, Body Type, Personality)
  // ─────────────────────────────────────────────────────
  Widget _buildQuickInfoGrid() {
    final items = [
      _InfoItem(Icons.cake_outlined, "Birthday", profile.dobFormatted),
      _InfoItem(Icons.work_outline_rounded, "Work", profile.work),
      _InfoItem(Icons.height_rounded, "Height", profile.height),
      _InfoItem(Icons.fitness_center_rounded, "Body Type", profile.bodyType),
      _InfoItem(
        Icons.psychology_outlined,
        "Personality",
        profile.personalityType,
      ),
      _InfoItem(Icons.wc_rounded, "Gender", profile.gender),
      _InfoItem(Icons.diversity_1_rounded, "Orientation", profile.orientation),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 2.6,
      ),
      itemBuilder: (context, index) => _infoCard(items[index]),
    );
  }

  Widget _infoCard(_InfoItem item) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.12),
            ),
            child: Icon(item.icon, color: AppColors.accent, size: 15.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label,
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 10.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.value.isEmpty ? "—" : item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // 🏷 SECTION TITLE
  // ─────────────────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // ❤️ HIGHLIGHT PILL (Looking For)
  // ─────────────────────────────────────────────────────
  Widget _highlightPill(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accent2],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18.sp),
          SizedBox(width: 10.w),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // 🏷 CHIP DISPLAY (Interests / Languages) — read only
  // ─────────────────────────────────────────────────────
  Widget _buildChipWrap(List<String> items, {Color color = AppColors.accent}) {
    if (items.isEmpty) {
      return Text(
        "Not added yet",
        style: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: 12.sp,
        ),
      );
    }
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: items.map((item) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: AppColors.chipBg,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            item,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.sp),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────
  // 🚬 🍷 LIFESTYLE CARD
  // ─────────────────────────────────────────────────────
  Widget _lifestyleCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent2, size: 18.sp),
          SizedBox(height: 8.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 10.5.sp,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value.isEmpty ? "—" : value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // 📸 PHOTOS — chhoti chhoti portrait cards, horizontal scroll
  // ─────────────────────────────────────────────────────
  static const List<String> _fallbackPhotos = [
    "https://images.unsplash.com/photo-1544005313-94ddf0286df2",
    "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e",
    "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
    "https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91",
    "https://images.unsplash.com/photo-1517841905240-472988babdf9",
  ];

  Widget _buildPhotoGrid() {
    // Agar user ne photos nahi daali to bhi khali "No photos" text
    // dikhane ke jagah chhoti sample photos dikhao — UI kabhi khali nahi lagega.
    final displayPhotos = profile.photos.isNotEmpty
        ? profile.photos
        : _fallbackPhotos;

    return SizedBox(
      height: 150.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayPhotos.length,
        separatorBuilder: (_, _) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final isFeatured = index == 0; // pehli photo highlight
          return _photoCard(displayPhotos[index], isFeatured: isFeatured);
        },
      ),
    );
  }

  Widget _photoCard(String url, {bool isFeatured = false}) {
    return Container(
      width: 105.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isFeatured ? const Color(0xFFFFB020) : AppColors.cardBorder,
          width: isFeatured ? 2 : 1,
        ),
        boxShadow: isFeatured
            ? [
                BoxShadow(
                  color: const Color(0xFFFFB020).withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: CachedNetworkImage(
          imageUrl: url,
          height: 148.h,
          width: 103.w,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (context, _) => Container(
            color: Colors.grey.shade900,
            child: Center(
              child: SizedBox(
                width: 16.w,
                height: 16.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          errorWidget: (context, _, _) => Container(
            color: Colors.grey.shade900,
            child: Icon(Icons.person, color: Colors.white24, size: 22.sp),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // 🔘 ACTION BUTTONS (Like / Message)
  // ─────────────────────────────────────────────────────
  // Widget _buildActionButtons() {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: SizedBox(
  //           height: 50.h,
  //           child: OutlinedButton.icon(
  //             onPressed: () {},
  //             style: OutlinedButton.styleFrom(
  //               side: BorderSide(color: AppColors.cardBorder),
  //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
  //             ),
  //             icon: Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 17.sp),
  //             label: Text(
  //               "Message",
  //               style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5.sp, fontWeight: FontWeight.w600),
  //             ),
  //           ),
  //         ),
  //       ),
  //       SizedBox(width: 12.w),
  //       Expanded(
  //         child: SizedBox(
  //           height: 50.h,
  //           child: ElevatedButton.icon(
  //             onPressed: () {},
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: AppColors.accent,
  //               elevation: 0,
  //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
  //             ),
  //             icon: Icon(Icons.favorite_rounded, color: Colors.white, size: 17.sp),
  //             label: Text(
  //               "Like",
  //               style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5.sp, fontWeight: FontWeight.w600),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  _InfoItem(this.icon, this.label, this.value);
}

// ─────────────────────────────────────────────────────────
// 🧪 DEMO USAGE — apna real data yahan se pass karo
// ─────────────────────────────────────────────────────────
class ViewProfileDemo extends StatelessWidget {
  const ViewProfileDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final demoProfile = UserProfile(
      name: "Ava",
      email: "ava@example.com",
      dob: DateTime(1997, 5, 12),
      gender: "Female",
      orientation: "Straight",
      lookingFor: "Serious Relationship",
      interests: ["Travel", "Fitness", "Music", "Photography"],
      smoking: "Never",
      drinking: "Sometimes",
      work: "Graphic Designer",
      height: "5'5\"",
      bodyType: "Athletic",
      personalityType: "Extrovert",
      languages: ["Hindi", "English"],
      photos: const [
        "https://images.unsplash.com/photo-1544005313-94ddf0286df2",
        "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e",
        "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
        "https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91",
        "https://images.unsplash.com/photo-1517841905240-472988babdf9",
        "https://images.unsplash.com/photo-1488426862026-3ee34a7d66df",
      ],
    );

    return ViewProfileScreen(profile: demoProfile);
  }
}
