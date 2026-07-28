// // lib/screens/home/homescreenitems/travel_alert_card.dart
// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
//
// class TravelAlertCard extends StatefulWidget {
//   final String videoPath; // local video path
//   final String title;
//   final String subtitle;
//   final VoidCallback onTap;
//
//   const TravelAlertCard({
//     required this.videoPath,
//     required this.title,
//     required this.subtitle,
//     required this.onTap,
//     Key? key,
//   }) : super(key: key);
//
//   @override
//   _TravelAlertCardState createState() => _TravelAlertCardState();
// }
//
// class _TravelAlertCardState extends State<TravelAlertCard> {
//   late VideoPlayerController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _controller = VideoPlayerController.asset(widget.videoPath)
//       ..initialize().then((_) {
//         setState(() {});
//         _controller.setLooping(true);
//         _controller.setVolume(0); // muted
//         _controller.play(); // autoplay
//       });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: widget.onTap,
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20.r),
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             _controller.value.isInitialized
//                 ? VideoPlayer(_controller)
//                 : Container(color: Colors.black12), // placeholder
//
//             // dark gradient overlay
//             Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     Colors.transparent,
//                     Colors.black.withOpacity(0.75),
//                   ],
//                 ),
//               ),
//             ),
//
//             // title & subtitle
//             Positioned(
//               bottom: 24.h,
//               left: 0,
//               right: 0,
//               child: Column(
//                 children: [
//                   Text(
//                     widget.title,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 26.sp,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   SizedBox(height: 6.h),
//                   Text(
//                     widget.subtitle,
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 14.sp,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }