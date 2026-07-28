import 'package:boomboom/screens/home/travell/filterscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../authentication/userdetails.dart';
import '../../../backend/routesmatch.dart';
import '../../../constant/appsize.dart';
import '../../../constant/apptextstyle.dart';
import '../../../constant/colors.dart';
import 'createtravel.dart';

class TravelAlertScreen extends StatefulWidget {
  const TravelAlertScreen({super.key});

  @override
  State<TravelAlertScreen> createState() => _TravelAlertScreenState();
}

class _TravelAlertScreenState extends State<TravelAlertScreen> {
  int selectedTab = 0;

  /// 🔥 HEART STATE — har user card ke liye alag
  final Set<int> _likedIndexes = {};

  /// TABS WITH ICONS
  final tabs = [
    {"label": "Arrivals", "icon": Icons.flight_land_rounded},
    {"label": "My Journeys", "icon": Icons.luggage_rounded},
  ];

  final TravelAlertController controller = Get.put(TravelAlertController());

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.primary,

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSize.w(16)),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              /// 🔥 HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  /// LEFT TEXT
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          "Travel Alert",

                          style: AppTextStyles.heading.copyWith(
                            fontSize: AppSize.sp(23),
                          ),
                        ),

                        SizedBox(height: 4.h),

                        Text(
                          selectedTab == 1
                              ? "CREATE JOURNEY, GET DESTINATION MESSAGES."
                              : "CREATE JOURNEY",

                          style: AppTextStyles.small.copyWith(
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// RIGHT ICONS
                  Row(
                    children: [
                      _iconBox(
                        Icons.add,

                        onTap: () {
                          Get.to(
                            () => CreateJourneyScreen(),

                            transition: Transition.rightToLeft,
                          );
                        },
                      ),

                      SizedBox(width: 8.w),

                      _iconBox(
                        Icons.tune,

                        onTap: () {
                          Get.bottomSheet(
                            FractionallySizedBox(
                              heightFactor: 0.72,

                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(28),
                                ),

                                child: const TravelFilterScreen(),
                              ),
                            ),

                            isScrollControlled: true,

                            backgroundColor: Colors.transparent,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              /// 🔥 TABS WITH ICONS
              Container(
                padding: EdgeInsets.all(4.w),

                decoration: BoxDecoration(
                  color: AppColors.secondary,

                  borderRadius: BorderRadius.circular(30.r),
                ),

                child: Row(
                  children: List.generate(
                    tabs.length,

                    (index) => Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTab = index;
                          });
                        },

                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),

                          padding: EdgeInsets.symmetric(vertical: 10.h),

                          decoration: BoxDecoration(
                            color: selectedTab == index
                                ? Colors.white
                                : Colors.transparent,

                            borderRadius: BorderRadius.circular(25.r),
                          ),

                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                /// TAB ICON
                                Icon(
                                  tabs[index]["icon"] as IconData,
                                  size: isTablet ? 16.sp : 14.sp,
                                  color: selectedTab == index
                                      ? Colors.black
                                      : AppColors.textSecondary,
                                ),

                                SizedBox(width: 6.w),

                                /// TAB LABEL
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    tabs[index]["label"] as String,
                                    style: AppTextStyles.body.copyWith(
                                      color: selectedTab == index
                                          ? Colors.black
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isTablet ? 14.sp : 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30.h),

              Expanded(
                child: selectedTab == 0
                    ? CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(color: Colors.white24),
                                    ),

                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14.w,
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.flight_land_rounded,
                                                color: Colors.white70,
                                                size: 14.sp,
                                              ),
                                              SizedBox(width: 6.w),

                                              Text(
                                                "UPCOMING ARRIVALS",
                                                style: AppTextStyles.subHeading
                                                    .copyWith(letterSpacing: 1),
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: 2.h),

                                          Text(
                                            "WHO ARRIVING IN YOUR COUNTRY",
                                            style: AppTextStyles.small.copyWith(
                                              fontSize: 10.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Expanded(
                                      child: Divider(color: Colors.white24),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 20.h),
                              ],
                            ),
                          ),

                          SliverGrid(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final user = controller.users[index];
                              return _userCard(user, index);
                            }, childCount: controller.users.length),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isTablet ? 3 : 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.62,
                                ),
                          ),
                        ],
                      )
                    : Center(
                        child: Text(
                          "MY JOURNEYS",
                          style: AppTextStyles.subHeading,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 ICON BOX
  Widget _iconBox(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: EdgeInsets.all(8.w),

        decoration: BoxDecoration(
          color: AppColors.secondary,

          borderRadius: BorderRadius.circular(10.r),
        ),

        child: Icon(icon, color: Colors.white, size: 18.sp),
      ),
    );
  }

  /// 🔥 ROUTE CARD
  // Widget _routeCard() {

  //   return Container(

  //     height: 240.h,
  //     width: double.infinity,

  //     decoration: BoxDecoration(

  //       color: const Color(0xFFDCD4F5),

  //       borderRadius:
  //       BorderRadius.circular(28.r),
  //     ),

  //     child: Stack(
  //       children: [

  //         /// 🔥 MAP IMAGE
  //         Positioned.fill(
  //           child: ClipRRect(

  //             borderRadius:
  //             BorderRadius.circular(28.r),

  //             child: Opacity(

  //               opacity: 0.10,

  //               child: Image.network(
  //                 "https://upload.wikimedia.org/wikipedia/commons/8/80/World_map_-_low_resolution.svg",

  //                 fit: BoxFit.cover,
  //               ),
  //             ),
  //           ),
  //         ),

  //         /// 🔥 CURVE LINE
  //         Positioned.fill(
  //           child: CustomPaint(
  //             painter: RoutePainter(),
  //           ),
  //         ),

  //         /// 🔥 CENTER GLOW DOT
  //         Positioned(
  //           top: 62.h,
  //           left: 165.w,

  //           child: Container(

  //             height: 24.h,
  //             width: 24.w,

  //             decoration: BoxDecoration(

  //               color: Colors.purple,

  //               shape: BoxShape.circle,

  //               border: Border.all(
  //                 color: Colors.white,
  //                 width: 3,
  //               ),

  //               boxShadow: [

  //                 BoxShadow(
  //                   color:
  //                   Colors.purple.withValues(alpha: 0.45),

  //                   blurRadius: 16,
  //                   spreadRadius: 3,
  //                 ),
  //               ],
  //             ),

  //             child: Center(
  //               child: Container(

  //                 height: 8.h,
  //                 width: 8.w,

  //                 decoration: const BoxDecoration(
  //                   color: Colors.white,
  //                   shape: BoxShape.circle,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),

  //         /// 🔥 LEFT USER
  //         Positioned(
  //           left: 20.w,
  //           top: 25.h,

  //           child: Column(
  //             children: [

  //               CircleAvatar(
  //                 radius: 30.r,

  //                 backgroundImage:
  //                 const NetworkImage(
  //                   "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
  //                 ),
  //               ),

  //               SizedBox(height: 8.h),

  //               Text(
  //                 "Alex, 27",

  //                 style:
  //                 AppTextStyles.body.copyWith(
  //                   color: Colors.black,
  //                   fontWeight:
  //                   FontWeight.w600,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),

  //         /// 🔥 RIGHT USER
  //         Positioned(
  //           right: 20.w,
  //           top: 25.h,

  //           child: Column(
  //             children: [

  //               CircleAvatar(
  //                 radius: 30.r,

  //                 backgroundImage:
  //                 const NetworkImage(
  //                   "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
  //                 ),
  //               ),

  //               SizedBox(height: 8.h),

  //               Text(
  //                 "Maya, 25",

  //                 style:
  //                 AppTextStyles.body.copyWith(
  //                   color: Colors.black,
  //                   fontWeight:
  //                   FontWeight.w600,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),

  //         /// 🔥 BOTTOM TEXT
  //         Positioned(
  //           bottom: 36.h,
  //           left: 0,
  //           right: 0,

  //           child: Column(
  //             children: [

  //               Text(
  //                 "From  →  Destination",

  //                 style:
  //                 AppTextStyles.subHeading
  //                     .copyWith(
  //                   color: Colors.black,
  //                   fontSize: 11.sp,
  //                   fontWeight:
  //                   FontWeight.w900,

  //                 ),
  //               ),

  //               SizedBox(height: 4.h),

  //               Text(
  //                 "Journey",

  //                 style:
  //                 AppTextStyles.body.copyWith(
  //                   color: Colors.black54,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// 🔥 USER CARD — with heart icon top-right + index for liked state
  Widget _userCard(Map<String, dynamic> user, int index) {
    final bool isLiked = _likedIndexes.contains(index);

    return GestureDetector(
      onTap: () {
        Get.to(
          () => UserDetailScreen(user: user),

          transition: Transition.rightToLeft,
        );
      },

      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24.r)),

        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.r),

                child: Image.network(
                  user["image"],

                  fit: BoxFit.cover,

                  errorBuilder: (_, _, _) {
                    return Container(
                      color: Colors.grey.shade900,

                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40.sp,
                      ),
                    );
                  },
                ),
              ),
            ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.r),

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
            ),

            /// STATUS BADGE — top left
            Positioned(
              top: 7.h,
              left: 4.w,

              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),

                decoration: BoxDecoration(
                  color: Colors.green,

                  borderRadius: BorderRadius.circular(30.r),
                ),

                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 12.sp),

                    SizedBox(width: 4.w),

                    Text(user["status"] ?? "", style: AppTextStyles.cardBadge),
                  ],
                ),
              ),
            ),

            /// 🔥 HEART ICON — top right (image jaisa)
            Positioned(
              top: 10.h,
              right: 10.w,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isLiked) {
                      _likedIndexes.remove(index);
                    } else {
                      _likedIndexes.add(index);
                    }
                  });
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(isLiked),
                    color: isLiked ? Colors.red : Colors.white,
                    size: 26.sp,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ),

            /// BOTTOM INFO
            Positioned(
              left: 10.w,
              right: 14.w,
              bottom: 8.h,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  /// NAME + FLAG
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              "${user["name"]}, ${user["age"]}",
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.cardName,
                            ),
                          ),

                          SizedBox(width: 4.w),

                          Text(
                            user["flag"] ?? "🏳️",
                            style: TextStyle(fontSize: 16.sp),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  /// HEIGHT ROW
                  // Row(
                  //   children: [
                  //     Icon(
                  //       Icons.height,
                  //       color: Colors.white54,
                  //       size: 13.sp,
                  //     ),
                  //     SizedBox(width: 3.w),
                  //     Text(
                  //       user["height"] ?? "",
                  //       style: AppTextStyles.small.copyWith(
                  //         color: Colors.white54,
                  //         fontWeight: FontWeight.w500,
                  //       ),
                  //     ),
                  //   ],
                  // ),

                  //SizedBox(height: 6.h),

                  /// FROM → TO
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 8.sp,
                      ),

                      SizedBox(width: 1.w),

                      Expanded(
                        child: Text(
                          "${user["from"]} ➜ ${user["to"]}",
                          style: AppTextStyles.cardDistance.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 9.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 6.h),

                  /// TAG BUTTON
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(30.r),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        Icon(
                          Icons.local_offer_outlined,

                          size: 14.sp,

                          color: Colors.black,
                        ),

                        SizedBox(width: 5.w),

                        Text(
                          user["tag"] ?? "",

                          style: AppTextStyles.small.copyWith(
                            color: Colors.black,

                            fontWeight: FontWeight.w500,
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
    );
  }
}

/// 🔥 ROUTE LINE
class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.purple, Colors.pink],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    path.moveTo(70, 85);

    path.cubicTo(
      size.width * 0.28,
      20,

      size.width * 0.60,
      145,

      size.width - 70,
      85,
    );

    canvas.drawPath(path, paint);

    canvas.drawCircle(
      Offset(size.width * 0.50, 85),

      10,

      Paint()..color = Colors.purple,
    );

    canvas.drawCircle(
      Offset(size.width * 0.50, 85),

      5,

      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
