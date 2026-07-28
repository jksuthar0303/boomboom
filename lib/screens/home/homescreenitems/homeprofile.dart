// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// import '../../../authentication/messagedetail.dart';
// import '../../../constant/colors.dart';
//
// class VedicaProfileScreen extends StatefulWidget {
//   const VedicaProfileScreen({super.key});
//
//   @override
//   State<VedicaProfileScreen> createState() =>
//       _VedicaProfileScreenState();
// }
//
// class _VedicaProfileScreenState extends State<VedicaProfileScreen>
//     with SingleTickerProviderStateMixin {
//
//   late AnimationController _controller;
//   late ScrollController _scrollController;
//   bool isVed = false; // V button state (was isStarred)
//   double _scrollOffset = 0;
//
//   final List<String> userPhotos = [
//     "https://images.unsplash.com/photo-1524504388940-b1c1722653e1",
//     "https://images.unsplash.com/photo-1517841905240-472988babdf9",
//     "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
//     "https://images.unsplash.com/photo-1488426862026-3ee34a7d66df",
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1200),
//     )..repeat(reverse: true);
//
//     _scrollController = ScrollController();
//     _scrollController.addListener(() {
//       setState(() {
//         _scrollOffset = _scrollController.offset;
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   void _openMessageDetail() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       barrierColor: Colors.black.withOpacity(0.6),
//       builder: (_) {
//         return DraggableScrollableSheet(
//           initialChildSize: 0.58,
//           minChildSize: 0.58,
//           maxChildSize: 1.0,
//           snap: true,
//           snapSizes: const [0.58, 1.0],
//           expand: false,
//           builder: (ctx, sheetScrollController) {
//             return ClipRRect(
//               borderRadius: BorderRadius.vertical(
//                 top: Radius.circular(28.r),
//               ),
//               child: MessageDetailPage(
//                 index: 0,
//                 messageData: const {
//                   "name": "Taniya Agarwal",
//                   "image":
//                   "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
//                   "age": "32",
//                   "gender": "F",
//                   "city": "New Delhi",
//                   "flag": "🇮🇳",
//                 },
//                 sheetScrollController: sheetScrollController,
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final double screenHeight = MediaQuery.of(context).size.height;
//     final double screenWidth = MediaQuery.of(context).size.width;
//
//     final double imageTop =
//     (-_scrollOffset * 0.4).clamp(-(screenHeight * 0.3), 0.0);
//
//     return Scaffold(
//       backgroundColor: AppColors.bg,
//       body: Stack(
//         children: [
//
//           /// ── PARALLAX COVER IMAGE ──────────────────────────
//           Positioned(
//             top: imageTop,
//             left: 0,
//             right: 0,
//             height: screenHeight + 100,
//             child: Image.network(
//               "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
//               fit: BoxFit.cover,
//               errorBuilder: (_, __, ___) => Container(
//                 color: AppColors.cardBg,
//                 child: const Center(
//                   child: Icon(Icons.person, color: Colors.white54, size: 80),
//                 ),
//               ),
//             ),
//           ),
//
//           /// ── DARK GRADIENT ─────────────────────────────────
//           Positioned(
//             top: imageTop,
//             left: 0,
//             right: 0,
//             height: screenHeight + 100,
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   stops: const [0.0, 0.45, 0.72, 1.0],
//                   colors: [
//                     Colors.transparent,
//                     Colors.transparent,
//                     Colors.black.withOpacity(0.55),
//                     Colors.black.withOpacity(0.98),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           /// ── MAIN SCROLL ───────────────────────────────────
//           SingleChildScrollView(
//             controller: _scrollController,
//             physics: const BouncingScrollPhysics(),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//
//                 /// ── PEHLI SCREEN ──────────────────────────
//                 SizedBox(
//                   height: screenHeight,
//                   width: screenWidth,
//                   child: Stack(
//                     children: [
//                       Positioned(
//                         bottom: 36,
//                         left: 18.w,
//                         right: 18.w,
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//
//                             /// ── STATUS BADGES ROW ─────────────────
//                             Row(
//                               children: [
//                                 /// ONLINE NOW badge
//                                 _onlineBadge(),
//                                 SizedBox(width: 8.w),
//                                 /// VERIFIED badge
//                                 _verifiedBadge(),
//                               ],
//                             ),
//
//                             SizedBox(height: 12.h),
//
//                             /// ── NAME + VERIFIED ICON ──────────────
//                             Row(
//                               children: [
//                                 Text(
//                                   "Taniya Agarwal, 32",
//                                   style: GoogleFonts.poppins(
//                                     color: AppColors.textPrimary,
//                                     fontWeight: FontWeight.w700,
//                                     fontSize: 26.sp,
//                                   ),
//                                 ),
//                                 SizedBox(width: 6.w),
//                                 Icon(
//                                   Icons.verified_rounded,
//                                   color: const Color(0xFF5B9CF6),
//                                   size: 22.sp,
//                                 ),
//                               ],
//                             ),
//
//                             SizedBox(height: 6.h),
//
//                             /// ── FLAG + LOCATION ───────────────────
//                             Row(
//                               children: [
//                                 Text(
//                                   "🇮🇳",
//                                   style: TextStyle(fontSize: 16.sp),
//                                 ),
//                                 SizedBox(width: 6.w),
//                                 Text(
//                                   "New Delhi, India",
//                                   style: GoogleFonts.poppins(
//                                     color: AppColors.white,
//                                     fontWeight: FontWeight.w500,
//                                     fontSize: 14.sp,
//                                   ),
//                                 ),
//                               ],
//                             ),
//
//                             SizedBox(height: 10.h),
//
//                             /// ── JOB / EDUCATION ───────────────────
//                             Row(
//                               children: [
//
//                                 Icon(
//                                   Icons.work_outline_rounded,
//                                   color: AppColors.white,
//                                   size: 18.sp,
//                                 ),
//
//                                 SizedBox(width: 8.w),
//
//                                 Text(
//                                   "Marketer",
//                                   style: GoogleFonts.poppins(
//                                     color: AppColors.white,
//                                     fontWeight: FontWeight.w500,
//                                     fontSize: 15.sp,
//                                   ),
//                                 ),
//
//                                 const Spacer(),
//
//                                 /// 🔥 V BUTTON
//                                 GestureDetector(
//                                   onTap: () {
//                                     setState(() => isVed = !isVed);
//                                     _openMessageDetail();
//                                   },
//                                   child: AnimatedBuilder(
//                                     animation: _controller,
//                                     builder: (_, child) {
//
//                                       final scale =
//                                           1 + (_controller.value * 0.10);
//
//                                       final rotate =
//                                           sin(_controller.value * pi * 2) *
//                                               0.06;
//
//                                       return Transform.rotate(
//                                         angle: rotate,
//                                         child: Transform.scale(
//                                           scale: scale,
//                                           child: Container(
//
//                                             height: 48.h,
//                                             width: 48.w,
//
//                                             decoration: BoxDecoration(
//                                               shape: BoxShape.circle,
//                                               color: const Color(0xFF7C5CF6),
//
//                                               boxShadow: [
//                                                 BoxShadow(
//                                                   color: const Color(0xFF7C5CF6)
//                                                       .withOpacity(0.55),
//                                                   blurRadius: 12,
//                                                   spreadRadius: 1,
//                                                 ),
//                                               ],
//                                             ),
//
//                                             child: Center(
//                                               child: isVed
//                                                   ? Icon(
//                                                 Icons.send_rounded,
//                                                 color: Colors.white,
//                                                 size: 18.sp,
//                                               )
//                                                   : Text(
//                                                 "V",
//                                                 style: GoogleFonts.poppins(
//                                                   color: Colors.white,
//                                                   fontWeight: FontWeight.w800,
//                                                   fontSize: 24.sp,
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             SizedBox(height: 6.h),
//                             _detailRow(Icons.school_outlined, "Vedica 2024"),
//
//                             SizedBox(height: 14.h),
//
//                             /// ── DISTANCE + RELATIONSHIP GOAL CHIPS ─
//                             Row(
//                               children: [
//                                 _chipPill(
//                                   icon: Icons.location_on_rounded,
//                                   label: "1.2 km",
//                                   iconColor: const Color(0xFF7C5CF6),
//                                 ),
//                                 SizedBox(width: 10.w),
//                                 _chipPill(
//                                   iconWidget: _omegaIcon(),
//                                   label: "Long Term",
//                                   iconColor: const Color(0xFFE060A0),
//                                 ),
//                               ],
//                             ),
//
//                             SizedBox(height: 16.h),
//
//                             /// ── SEND MESSAGE BAR + V BUTTON ────────
//                             // Row(
//                             //   mainAxisAlignment: MainAxisAlignment.end,
//                             //   children: [
//                             //     /// Send message field
//                             //     // Expanded(
//                             //     //   child: GestureDetector(
//                             //     //     onTap: _openMessageDetail,
//                             //     //     child: Container(
//                             //     //       height: 52.h,
//                             //     //       padding: EdgeInsets.symmetric(
//                             //     //           horizontal: 18.w),
//                             //     //       decoration: BoxDecoration(
//                             //     //         color: Colors.white.withOpacity(0.15),
//                             //     //         borderRadius:
//                             //     //         BorderRadius.circular(30.r),
//                             //     //         border: Border.all(
//                             //     //           color:
//                             //     //           Colors.white.withOpacity(0.25),
//                             //     //           width: 1,
//                             //     //         ),
//                             //     //       ),
//                             //     //       child: Row(
//                             //     //         children: [
//                             //     //           Text(
//                             //     //             "Send message...",
//                             //     //             style: GoogleFonts.poppins(
//                             //     //               color: Colors.white54,
//                             //     //               fontSize: 14.sp,
//                             //     //             ),
//                             //     //           ),
//                             //     //         ],
//                             //     //       ),
//                             //     //     ),
//                             //     //   ),
//                             //     // ),
//                             //
//                             //     SizedBox(width: 12.w),
//                             //
//                             //     /// 🔥 ANIMATED V BUTTON (was Star)
//                             //     GestureDetector(
//                             //       onTap: () {
//                             //         setState(() => isVed = !isVed);
//                             //         _openMessageDetail();
//                             //       },
//                             //       child: AnimatedBuilder(
//                             //         animation: _controller,
//                             //         builder: (_, child) {
//                             //           final scale =
//                             //               1 + (_controller.value * 0.10);
//                             //           final rotate =
//                             //               sin(_controller.value * pi * 2) *
//                             //                   0.06;
//                             //           return Transform.rotate(
//                             //             angle: rotate,
//                             //             child: Transform.scale(
//                             //               scale: scale,
//                             //               child: Container(
//                             //                 height: 52.h,
//                             //                 width: 52.w,
//                             //                 decoration: BoxDecoration(
//                             //                   shape: BoxShape.circle,
//                             //                   color: const Color(0xFF7C5CF6),
//                             //                   boxShadow: [
//                             //                     BoxShadow(
//                             //                       color: const Color(0xFF7C5CF6)
//                             //                           .withOpacity(0.55),
//                             //                       blurRadius: 16,
//                             //                       spreadRadius: 2,
//                             //                     ),
//                             //                   ],
//                             //                 ),
//                             //                 child: Center(
//                             //                   child: isVed
//                             //                       ? Icon(
//                             //                     Icons.send_rounded,
//                             //                     color: Colors.white,
//                             //                     size: 22.sp,
//                             //                   )
//                             //                       : Text(
//                             //                     "V",
//                             //                     style: GoogleFonts.poppins(
//                             //                       color: Colors.white,
//                             //                       fontWeight:
//                             //                       FontWeight.w800,
//                             //                       fontSize: 22.sp,
//                             //                     ),
//                             //                   ),
//                             //                 ),
//                             //               ),
//                             //             ),
//                             //           );
//                             //         },
//                             //       ),
//                             //     ),
//                             //   ],
//                             // ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 /// ── DARK CARD ─────────────────────────────
//                 Container(
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     color: AppColors.cardBg,
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(32),
//                     ),
//                     border: Border.all(
//                       color: AppColors.cardBorder,
//                       width: 1,
//                     ),
//                   ),
//                   padding: EdgeInsets.symmetric(
//                     horizontal: 18.w,
//                     vertical: 28.h,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//
//                       /// ── STATUS ROW (Active / Verified) ───────
//                       Row(
//                         children: [
//                           Container(
//                             width: 10.w,
//                             height: 10.h,
//                             decoration: const BoxDecoration(
//                               color: Color(0xFF4ADE80),
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                           SizedBox(width: 6.w),
//                           Text(
//                             "Active",
//                             style: GoogleFonts.poppins(
//                               color: const Color(0xFF4ADE80),
//                               fontSize: 13.sp,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           SizedBox(width: 20.w),
//                           Icon(
//                             Icons.verified_user_rounded,
//                             color: const Color(0xFF5B9CF6),
//                             size: 16.sp,
//                           ),
//                           SizedBox(width: 6.w),
//                           Text(
//                             "Verified",
//                             style: GoogleFonts.poppins(
//                               color: const Color(0xFF5B9CF6),
//                               fontSize: 13.sp,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       SizedBox(height: 24.h),
//
//                       /// ── ABOUT ME ──────────────────────────────
//                       Text(
//                         "About Me",
//                         style: GoogleFonts.poppins(
//                           color: AppColors.textPrimary,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 18.sp,
//                         ),
//                       ),
//
//                       SizedBox(height: 14.h),
//
//                       Container(
//                         width: double.infinity,
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 18.w,
//                           vertical: 18.h,
//                         ),
//                         decoration: BoxDecoration(
//                           color: AppColors.surface,
//                           borderRadius: BorderRadius.circular(24.r),
//                           border: Border.all(
//                             color: AppColors.cardBorder,
//                             width: 1,
//                           ),
//                         ),
//                         child: Text(
//                           "Passionate about travel, coffee dates, deep conversations and creating meaningful connections. I love exploring new places, trying different cuisines and spending quality time with genuine people.",
//                           style: GoogleFonts.poppins(
//                             color: AppColors.textSecondary,
//                             fontSize: 14.sp,
//                             height: 1.7,
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ),
//
//                       SizedBox(height: 24.h),
//
//                       /// ── HOBBIES ───────────────────────────────
//                       Text(
//                         "Hobbies",
//                         style: GoogleFonts.poppins(
//                           color: AppColors.textPrimary,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 18.sp,
//                         ),
//                       ),
//
//                       SizedBox(height: 14.h),
//
//                       Wrap(
//                         spacing: 10.w,
//                         runSpacing: 10.h,
//                         children: [
//                           _hobbyChip("🎵 Music"),
//                           _hobbyChip("✈️ Travel"),
//                           _hobbyChip("☕ Coffee"),
//                           _hobbyChip("📸 Photography"),
//                           _hobbyChip("🏋️ Gym"),
//                           _hobbyChip("🎬 Movies"),
//                           _hobbyChip("🍕 Food"),
//                           _hobbyChip("🌙 Night Drives"),
//                         ],
//                       ),
//
//                       SizedBox(height: 28.h),
//
//                       /// MORE PHOTOS
//                       Text(
//                         "More Photos",
//                         style: GoogleFonts.poppins(
//                           color: AppColors.textPrimary,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 18.sp,
//                         ),
//                       ),
//
//                       SizedBox(height: 14.h),
//
//                       GridView.builder(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         itemCount: userPhotos.length,
//                         gridDelegate:
//                         SliverGridDelegateWithFixedCrossAxisCount(
//                           crossAxisCount: 2,
//                           crossAxisSpacing: 12.w,
//                           mainAxisSpacing: 12.h,
//                           childAspectRatio: 0.9,
//                         ),
//                         itemBuilder: (_, index) {
//                           return GestureDetector(
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => FullPhotoViewScreen(
//                                     image: userPhotos[index],
//                                   ),
//                                 ),
//                               );
//                             },
//                             child: Hero(
//                               tag: userPhotos[index],
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   borderRadius:
//                                   BorderRadius.circular(20.r),
//                                   image: DecorationImage(
//                                     image: NetworkImage(userPhotos[index]),
//                                     fit: BoxFit.cover,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//
//                       SizedBox(height: 24.h),
//
//                       /// WE HAVE THINGS IN COMMON
//                       Container(
//                         width: double.infinity,
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 18.w,
//                           vertical: 18.h,
//                         ),
//                         decoration: BoxDecoration(
//                           color: AppColors.surface,
//                           borderRadius: BorderRadius.circular(24.r),
//                           border: Border.all(
//                             color: AppColors.cardBorder,
//                             width: 1,
//                           ),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "We have things in common",
//                               style: GoogleFonts.poppins(
//                                 color: AppColors.textPrimary,
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 15.sp,
//                               ),
//                             ),
//                             SizedBox(height: 12.h),
//                             Row(
//                               children: [
//                                 Icon(
//                                   Icons.temple_hindu,
//                                   color: AppColors.textSecondary,
//                                   size: 18.sp,
//                                 ),
//                                 SizedBox(width: 8.w),
//                                 Text(
//                                   "Hindu",
//                                   style: GoogleFonts.poppins(
//                                     color: AppColors.textPrimary,
//                                     fontWeight: FontWeight.w500,
//                                     fontSize: 15.sp,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//
//                       SizedBox(height: 32.h),
//
//                       /// ── LIKE BUTTON ──
//                       GestureDetector(
//                         onTap: () {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text("Liked!"),
//                               duration: Duration(seconds: 1),
//                             ),
//                           );
//                         },
//                         child: Container(
//                           width: double.infinity,
//                           height: 56.h,
//                           decoration: BoxDecoration(
//                             gradient: const LinearGradient(
//                               colors: [Color(0xFF7C5CF6), Color(0xFFB05CF6)],
//                               begin: Alignment.centerLeft,
//                               end: Alignment.centerRight,
//                             ),
//                             borderRadius: BorderRadius.circular(16.r),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: const Color(0xFF7C5CF6).withOpacity(0.35),
//                                 blurRadius: 14,
//                                 spreadRadius: 1,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.favorite_rounded,
//                                 color: Colors.white,
//                                 size: 22.sp,
//                               ),
//                               SizedBox(width: 10.w),
//                               Text(
//                                 "Like",
//                                 style: GoogleFonts.poppins(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.w700,
//                                   fontSize: 16.sp,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//
//                       SizedBox(height: 14.h),
//
//                       /// ── BLOCK & REPORT ──
//                       Row(
//                         children: [
//                           Expanded(
//                             child: GestureDetector(
//                               onTap: () => _showBlockDialog(context),
//                               child: Container(
//                                 height: 52.h,
//                                 decoration: BoxDecoration(
//                                   color: AppColors.surface,
//                                   borderRadius: BorderRadius.circular(16.r),
//                                   border: Border.all(
//                                     color: AppColors.cardBorder,
//                                     width: 1,
//                                   ),
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.block_rounded,
//                                       color: AppColors.textSecondary,
//                                       size: 18.sp,
//                                     ),
//                                     SizedBox(width: 8.w),
//                                     Text(
//                                       "Block",
//                                       style: GoogleFonts.poppins(
//                                         color: AppColors.textSecondary,
//                                         fontWeight: FontWeight.w600,
//                                         fontSize: 15.sp,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//
//                           SizedBox(width: 12.w),
//
//                           Expanded(
//                             child: GestureDetector(
//                               onTap: () => _showReportDialog(context),
//                               child: Container(
//                                 height: 52.h,
//                                 decoration: BoxDecoration(
//                                   color: AppColors.error.withOpacity(0.08),
//                                   borderRadius: BorderRadius.circular(16.r),
//                                   border: Border.all(
//                                     color: AppColors.error.withOpacity(0.35),
//                                     width: 1,
//                                   ),
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.flag_rounded,
//                                       color: AppColors.error,
//                                       size: 18.sp,
//                                     ),
//                                     SizedBox(width: 8.w),
//                                     Text(
//                                       "Report",
//                                       style: GoogleFonts.poppins(
//                                         color: AppColors.error,
//                                         fontWeight: FontWeight.w600,
//                                         fontSize: 15.sp,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       SizedBox(height: 40.h),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           /// ── BACK BUTTON ───────────────────────────────────
//           SafeArea(
//             child: Padding(
//               padding: EdgeInsets.all(12.w),
//               child: GestureDetector(
//                 onTap: () => Navigator.pop(context),
//                 child: Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.45),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.arrow_back,
//                     color: Colors.white,
//                     size: 20,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ── ONLINE BADGE ──────────────────────────────────────────
//   Widget _onlineBadge() {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.45),
//         borderRadius: BorderRadius.circular(20.r),
//         border: Border.all(
//           color: const Color(0xFF4ADE80).withOpacity(0.5),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 8.w,
//             height: 8.h,
//             decoration: const BoxDecoration(
//               color: Color(0xFF4ADE80),
//               shape: BoxShape.circle,
//             ),
//           ),
//           SizedBox(width: 5.w),
//           Text(
//             "Online now",
//             style: GoogleFonts.poppins(
//               color: const Color(0xFF4ADE80),
//               fontWeight: FontWeight.w600,
//               fontSize: 11.sp,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ── VERIFIED BADGE ────────────────────────────────────────
//   Widget _verifiedBadge() {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.88),
//         borderRadius: BorderRadius.circular(20.r),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.verified_rounded,
//             color: const Color(0xFF5B9CF6),
//             size: 13.sp,
//           ),
//           SizedBox(width: 4.w),
//           Text(
//             "Photo verified",
//             style: GoogleFonts.poppins(
//               color: AppColors.black,
//               fontWeight: FontWeight.w600,
//               fontSize: 11.sp,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ── CHIP PILL (distance / relationship goal) ──────────────
//   Widget _chipPill({
//     IconData? icon,
//     Widget? iconWidget,
//     required String label,
//     required Color iconColor,
//   }) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.45),
//         borderRadius: BorderRadius.circular(10.r),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.2),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (iconWidget != null)
//             iconWidget
//           else
//             Icon(icon, color: iconColor, size: 14.sp),
//           SizedBox(width: 5.w),
//           Text(
//             label,
//             style: GoogleFonts.poppins(
//               color: AppColors.white,
//               fontWeight: FontWeight.w500,
//               fontSize: 12.sp,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ── OMEGA / RELATIONSHIP GOAL ICON ───────────────────────
//   Widget _omegaIcon() {
//     return Container(
//       width: 14.w,
//       height: 14.h,
//       alignment: Alignment.center,
//       child: Text(
//         "Ω",
//         style: TextStyle(
//           color: const Color(0xFFE060A0),
//           fontSize: 13.sp,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }
//
//   void _showBlockDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         backgroundColor: AppColors.cardBg,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20.r),
//           side: BorderSide(color: AppColors.cardBorder),
//         ),
//         title: Text(
//           "Block User",
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.w700,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         content: Text(
//           "Are you sure you want to block this user?",
//           style: GoogleFonts.poppins(
//             fontSize: 14.sp,
//             color: AppColors.textSecondary,
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text("Cancel",
//                 style:
//                 GoogleFonts.poppins(color: AppColors.textSecondary)),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text("Block",
//                 style: GoogleFonts.poppins(
//                     color: AppColors.error,
//                     fontWeight: FontWeight.w700)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showReportDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         backgroundColor: AppColors.cardBg,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20.r),
//           side: BorderSide(color: AppColors.cardBorder),
//         ),
//         title: Text(
//           "Report User",
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.w700,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         content: Text(
//           "Are you sure you want to report this user?",
//           style: GoogleFonts.poppins(
//             fontSize: 14.sp,
//             color: AppColors.textSecondary,
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text("Cancel",
//                 style:
//                 GoogleFonts.poppins(color: AppColors.textSecondary)),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text("Report",
//                 style: GoogleFonts.poppins(
//                     color: AppColors.error,
//                     fontWeight: FontWeight.w700)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _detailRow(IconData icon, String text) {
//     return Row(
//       children: [
//         Icon(icon, color: AppColors.white, size: 18.sp),
//         SizedBox(width: 8.w),
//         Text(
//           text,
//           style: GoogleFonts.poppins(
//             color: AppColors.white,
//             fontWeight: FontWeight.w500,
//             fontSize: 15.sp,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _hobbyChip(String text) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: 14.w,
//         vertical: 10.h,
//       ),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(18.r),
//         border: Border.all(
//           color: AppColors.cardBorder,
//           width: 1,
//         ),
//       ),
//       child: Text(
//         text,
//         style: GoogleFonts.poppins(
//           color: AppColors.textPrimary,
//           fontWeight: FontWeight.w500,
//           fontSize: 13.sp,
//         ),
//       ),
//     );
//   }
// }
//
// /// ── FULL SCREEN PHOTO VIEW ───────────────────────────────────
// class FullPhotoViewScreen extends StatelessWidget {
//   final String image;
//   const FullPhotoViewScreen({super.key, required this.image});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           InteractiveViewer(
//             minScale: 1,
//             maxScale: 5,
//             child: Center(
//               child: Hero(
//                 tag: image,
//                 child: Image.network(image, fit: BoxFit.contain),
//               ),
//             ),
//           ),
//           Positioned(
//             top: MediaQuery.of(context).padding.top + 12,
//             left: 12,
//             child: GestureDetector(
//               onTap: () => Navigator.pop(context),
//               child: Container(
//                 height: 42,
//                 width: 42,
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.5),
//                   shape: BoxShape.circle,
//                 ),
//                 child:
//                 const Icon(Icons.arrow_back, color: Colors.white),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }