import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../constant/apptextstyle.dart';
import '../../../../constant/colors.dart';
import 'createeventscreen.dart';
import 'freetonightcreen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔝 TOP BAR
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24.w : 16.w,
                  vertical: isTablet ? 16.h : 12.h,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// LEFT — ICON + TITLE
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isTablet ? 12.r : 8.r),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(2, 2),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(-1, -1),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: isTablet ? 22.sp : 16.sp,
                          ),
                        ),
                        SizedBox(width: isTablet ? 12.w : 10.w),
                        Text(
                          "Free Tonight",
                          style: AppTextStyles.heading.copyWith(
                            fontSize: isTablet ? 22.sp : 16.sp,
                          ),
                        ),
                      ],
                    ),

                    /// RIGHT — TONIGHT ENDS + ADD
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// 🕐 TONIGHT ENDS WIDGET
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 14.w : 10.w,
                            vertical: isTablet ? 11.h : 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 8,
                                offset: const Offset(2, 2),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(-1, -1),
                              ),
                            ],
                          ),
                          child: StreamBuilder(
                            stream: Stream.periodic(
                              const Duration(seconds: 60),
                            ),
                            builder: (context, snapshot) {
                              final now = DateTime.now();
                              final midnight = DateTime(
                                now.year,
                                now.month,
                                now.day + 1,
                              );
                              final diff = midnight.difference(now);
                              final hours = diff.inHours;
                              final minutes = diff.inMinutes % 60;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_filled,
                                    color: Colors.pink,
                                    size: isTablet ? 16.sp : 12.sp,
                                  ),
                                  SizedBox(width: isTablet ? 6.w : 5.w),
                                  Text(
                                    "ends in ${hours}h ${minutes}m",
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 13.sp : 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        SizedBox(width: isTablet ? 14.w : 10.w),

                        /// ➕ ADD BUTTON
                        _iconBtn(
                          Icons.add,
                          isTablet,
                          isAccent: true,
                          onTap: () async {
                            final res = await Get.to(() => const CreateEventScreen());
                            if (res == true && mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 4.h : 2.h),

              /// 🔥 BODY
              const Expanded(child: FreeTonightScreen()),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔘 ICON BUTTON
  Widget _iconBtn(
    IconData icon,
    bool isTablet, {
    bool isAccent = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 12.r : 8.r),
        decoration: BoxDecoration(
          color: isAccent ? Colors.white : AppColors.secondary,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(-1, -1),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isAccent ? Colors.black : Colors.white,
          size: isTablet ? 22.sp : 16.sp,
        ),
      ),
    );
  }

  /// 🔥 EVENT CARD (kept for reference)
  // Widget _eventCard(Map<String, String> event, bool isTablet) {
  //   return GestureDetector(
  //     onTap: () {
  //       Get.to(
  //         const ProfileDetailsScreen(),
  //         transition: Transition.rightToLeft,
  //         duration: const Duration(milliseconds: 350),
  //       );
  //     },
  //     child: Container(
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(14.r),
  //         color: AppColors.secondary,
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withValues(alpha: 0.5),
  //             blurRadius: 12,
  //             offset: const Offset(4, 4),
  //           ),
  //           BoxShadow(
  //             color: Colors.white.withValues(alpha: 0.04),
  //             blurRadius: 6,
  //             offset: const Offset(-2, -2),
  //           ),
  //         ],
  //       ),
  //       child: ClipRRect(
  //         borderRadius: BorderRadius.circular(14.r),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [

  //             /// IMAGE
  //             Expanded(
  //               child: Stack(
  //                 children: [
  //                   Positioned.fill(
  //                     child: Image.network(
  //                       event['image']!,
  //                       fit: BoxFit.cover,
  //                       errorBuilder: (_, _, _) => Container(
  //                         color: const Color(0xFF2a2a2a),
  //                         child: Icon(
  //                           Icons.person,
  //                           color: Colors.white24,
  //                           size: isTablet ? 56.sp : 48.sp,
  //                         ),
  //                       ),
  //                     ),
  //                   ),

  //                   /// DAYS BADGE
  //                   Positioned(
  //                     top: 8.h,
  //                     right: 8.w,
  //                     child: Container(
  //                       padding: EdgeInsets.symmetric(
  //                         horizontal: isTablet ? 10.w : 8.w,
  //                         vertical: isTablet ? 4.h : 3.h,
  //                       ),
  //                       decoration: BoxDecoration(
  //                         color: Colors.black.withValues(alpha: 0.65),
  //                         borderRadius: BorderRadius.circular(8.r),
  //                         boxShadow: [
  //                           BoxShadow(
  //                             color: Colors.black.withValues(alpha: 0.4),
  //                             blurRadius: 6,
  //                             offset: const Offset(1, 1),
  //                           ),
  //                         ],
  //                       ),
  //                       child: Text(
  //                         event['days']!,
  //                         style: GoogleFonts.poppins(
  //                           fontSize: isTablet ? 11.sp : 9.sp,
  //                           fontWeight: FontWeight.w600,
  //                           color: Colors.white,
  //                         ),
  //                       ),
  //                     ),
  //                   ),

  //                   /// BOTTOM GRADIENT
  //                   Positioned.fill(
  //                     child: DecoratedBox(
  //                       decoration: BoxDecoration(
  //                         gradient: LinearGradient(
  //                           begin: Alignment.topCenter,
  //                           end: Alignment.bottomCenter,
  //                           colors: [
  //                             Colors.transparent,
  //                             Colors.black.withValues(alpha: 0.3),
  //                           ],
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),

  //             /// BOTTOM INFO
  //             Padding(
  //               padding: EdgeInsets.symmetric(
  //                 horizontal: isTablet ? 12.w : 8.w,
  //                 vertical: isTablet ? 10.h : 6.h,
  //               ),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     event['title']!,
  //                     style: GoogleFonts.poppins(
  //                       fontSize: isTablet ? 14.sp : 10.sp,
  //                       fontWeight: FontWeight.w600,
  //                       color: Colors.white,
  //                     ),
  //                     maxLines: 1,
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                   SizedBox(height: 3.h),

  //                   Row(
  //                     children: [
  //                       Icon(
  //                         Icons.location_on_rounded,
  //                         color: Colors.white38,
  //                         size: isTablet ? 12.sp : 9.sp,
  //                       ),
  //                       SizedBox(width: 2.w),
  //                       Expanded(
  //                         child: Text(
  //                           event['location']!,
  //                           style: GoogleFonts.poppins(
  //                             fontSize: isTablet ? 11.sp : 8.sp,
  //                             color: Colors.white38,
  //                             fontWeight: FontWeight.w400,
  //                           ),
  //                           maxLines: 1,
  //                           overflow: TextOverflow.ellipsis,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
