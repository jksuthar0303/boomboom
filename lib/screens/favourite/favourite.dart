import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../authentication/boomboom.dart';
import '../../constant/appsize.dart';
import '../../constant/apptextstyle.dart';
import '../../constant/colors.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {

  int myLikesCount = 12;
  int whoLikedCount = 45;
  int whoViewedCount = 128;
  int whoSortedCount = 18;
  int mySortedCount = 7;

  late final List<int> counts = [
    myLikesCount, whoLikedCount, whoViewedCount, whoSortedCount, mySortedCount,
  ];

  int selectedTab = 0;

  final tabs = ["My Likes", "Who Liked", "Who Viewed", "Who Favourite Me", "My Favourite"];

  final List<Map<String, dynamic>> users = [
    {"image": "https://randomuser.me/api/portraits/women/1.jpg", "name": "Jyunko", "age": 26, "flag": "🇹🇭", "city": "Thailand", "distance": "50km away"},
    {"image": "https://randomuser.me/api/portraits/women/2.jpg", "name": "Pin107", "age": 25, "flag": "🇹🇭", "city": "Chiang Mai", "distance": "2475km away"},
    {"image": "https://randomuser.me/api/portraits/women/3.jpg", "name": "Namkang16TH", "age": 57, "flag": "🇹🇭", "city": "Bangkok", "distance": "29km away"},
    {"image": "https://randomuser.me/api/portraits/women/4.jpg", "name": "Ploy15987", "age": 22, "flag": "🇮🇳", "city": "India", "distance": "8757km away"},
    {"image": "https://randomuser.me/api/portraits/women/5.jpg", "name": "Sara", "age": 28, "flag": "🇹🇭", "city": "Phuket", "distance": "120km away"},
    {"image": "https://randomuser.me/api/portraits/women/6.jpg", "name": "Mila", "age": 24, "flag": "🇮🇳", "city": "Mumbai", "distance": "300km away"},
    {"image": "https://randomuser.me/api/portraits/women/7.jpg", "name": "Lena", "age": 30, "flag": "🇹🇭", "city": "Pattaya", "distance": "5km away"},
    {"image": "https://randomuser.me/api/portraits/women/8.jpg", "name": "Nong", "age": 27, "flag": "🇹🇭", "city": "Chonburi", "distance": "18km away"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSize.w(2)),
          child: Column(
            children: [

              // // ── SEARCH BAR ──
              // Container(
              //   height: 48.h,
              //   padding: EdgeInsets.symmetric(horizontal: 16.w),
              //   decoration: BoxDecoration(
              //     color: Colors.white.withOpacity(0.07),
              //     borderRadius: BorderRadius.circular(30.r),
              //     border: Border.all(color: Colors.white.withOpacity(0.15)),
              //   ),
              //   child: Row(
              //     children: [
              //       Ic(Icons.search, color: Colors.white54, size: 20.sp),
              //       SizedBox(width: 10.w),
              //       Text(
              //         "Search by  country, name, age, district",
              //         style: AppTextStyles.body.copyWith(color: Colors.white38, fontSize: 13.sp),
              //       ),
              //     ],
              //   ),
              // ),

             // SizedBox(height: 14.h),

              // ── TABS ──
              // ── TABS ──
              SizedBox(
                height: 40.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: tabs.length,
                  itemBuilder: (_, index) {
                    final tabIcons = [
                      Icons.favorite_rounded,
                      Icons.people_alt_rounded,
                      Icons.remove_red_eye_rounded,
                      Icons.bookmark_rounded,
                      Icons.sort_rounded,
                    ];

                    final tabColors = [
                      Colors.red,
                      Colors.purple,
                      Colors.blue,
                      Colors.green,
                      Colors.amber,
                    ];

                    final isSelected = selectedTab == index;
                    final color = tabColors[index];

                    return GestureDetector(
                      onTap: () => setState(() => selectedTab = index),
                      child: Container(
                        margin: EdgeInsets.only(right: 10.w),
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.18)
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: isSelected ? color : Colors.white12,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Icon circle with count badge ──
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 34.w,
                                  height: 34.w,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: isSelected ? 0.25 : 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    tabIcons[index],
                                    color: isSelected ? color : Colors.white60,
                                    size: 17.sp,
                                  ),
                                ),
                                // Red count badge
                                Positioned(
                                  top: -8,
                                  right: -3,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: counts[index] > 9 ? 4.w : 5.w,
                                        vertical: 1.5.h),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10.r),
                                      border: Border.all(color: const Color(0xFF111111), width: 1.2),
                                    ),
                                    child: Text(
                                      counts[index] > 99 ? '99+' : counts[index].toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 7.sp,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(width: 8.w),

                            // ── Label ──
                            Text(
                              tabs[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white60,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: AppSize.h(16)),

              // ── GRID ──
              Expanded(
                child: GridView.builder(
                  itemCount: users.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 4.h,
                    crossAxisSpacing: 2.w,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (_, i) => _card(i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── DARK PILL BADGE (image style) ──
  Widget _darkPill({
    required Widget child,
    Color borderColor = const Color(0xFF2A2A2A),
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: Colors.black.withValues(alpha: 0.55),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: child,
    );
  }

  // ── CARD ──
  Widget _card(int index) {
    final user = users[index % users.length];

    return GestureDetector(
      onTap: (){
        Get.to(BoomProfileScreen());
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          children: [

            // ── PHOTO ──
            Image.network(
              user["image"],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, _, _) => Container(
                color: Colors.grey.shade900,
                child: Icon(Icons.person, color: Colors.white24, size: 40.sp),
              ),
            ),

            // ── GRADIENT ──
            Container(

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.88)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // ── X BUTTON (top-left) — BLUE filled circle ──
            // ── X BUTTON (top-left) ──
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: Colors.black, // Blue ki jagah black
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4), // Shadow bhi black
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
            ),

            // ── HEART ICON — same as Explore screen ──
            Positioned(
              top: 10.h,
              right: 10.w,
              child: Icon(
                Icons.favorite_border_rounded,
                color: Colors.white,
                size: 26.sp,
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 6,
                  ),
                ],
              ),
            ),

            // ── BOTTOM INFO ──
            Positioned(
              bottom: 0, left: 5.h, right: 8.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Name + Age + Verified
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          "${user["name"]}, ${user["age"]}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 14.sp),
                    ],
                  ),

                  SizedBox(height: 0.5.h),

                  // ── COUNTRY BADGE ──
                  _darkPill(
                    borderColor: Colors.white12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(user["flag"], style: TextStyle(fontSize: 9.sp,fontWeight: FontWeight.w900)),
                        SizedBox(width: 1.w),
                        Text(
                          user["city"],
                          style: AppTextStyles.small.copyWith(color: Colors.white70, fontSize: 8.sp,fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 0.5.h),

                  // ── DISTANCE BADGE ──
                  _darkPill(
                    borderColor: Colors.white12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined, color: Colors.white60, size: 11.sp),
                        SizedBox(width: 1.w),
                        Text(
                          user["distance"],
                          style: AppTextStyles.small.copyWith(color: Colors.white60, fontSize: 8.sp, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 0.5.h),

                  // ── ACTIVE NOW + FRIENDSHIP ROW ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      // Active now badge
                      _darkPill(
                        borderColor: Colors.white12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.w, height: 6.w,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2ECC71), shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              "Active now",
                              style: AppTextStyles.small.copyWith(color: Colors.white70, fontSize: 8.sp,fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),

                      // Friendship badge
                      // Friendship badge
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.r),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2216CA), Color(0xFFD8658F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(1.2),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(29.r),
                            color: Colors.black.withValues(alpha: 0.7),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_outline,
                                color: Colors.white,
                                size: 9.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                "Friendship",
                                style: AppTextStyles.small.copyWith(
                                  color: Colors.white,
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
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
    );
  }
}