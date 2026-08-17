import 'package:boomboom/authentication/boomboom.dart';
import 'package:boomboom/authentication/messagescreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constant/appsize.dart';
import '../constant/colors.dart';
import 'favourite/favourite.dart';
import 'home/home.dart';
import 'home/location/location.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  int get totalUnreadUsers {
    return MessagePageState.messageList
        .where((e) => e.unreadCount > 0)
        .length;
  }

  int index = 0;

  List<Widget> get pages => [
    const HomeScreen(),
    NearbyMapScreen(),
    const BoomProfileScreen(
      isOwnProfile: false,
      showStar: true,
      showMore: true,
    ),
    LikesScreen(),
    MessagePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          Positioned.fill(child: pages[index]),
          // Positioned(
          //   bottom: 1.h,
          //   left: 12.w,
          //   right: 12.w,
          //   child: _customNavBar(),
          // ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _customNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _customNavBar() {
    return Container(

      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        // borderRadius: BorderRadius.circular(30),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.r),
          topRight: Radius.circular(30.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(5, 5),
          ),
          const BoxShadow(
            color: Colors.white10,
            blurRadius: 10,
            offset: Offset(-5, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          nav(Icons.home, 0, AppColors.navHome),
          nav(Icons.location_on, 1, AppColors.navLocation),
          navImage("assets/logos.png", 2, AppColors.navBoomBoom),
          navWithBadge(
            Icons.favorite,
            3,
            5,
            AppColors.navFavourite,
          ),
          navWithBadge(
            Icons.forum_rounded,
            4,
            totalUnreadUsers,
            AppColors.navMessages,
          ),
        ],
      ),
    );
  }

  void _changeTab(int i) {
    setState(() {
      index = i;
    });
    if (i == 0) {
      HomeScreen.refreshProfile();
    }
  }

  Widget nav(IconData icon, int i, Color activeColor) {
    final bool active = index == i;

    return GestureDetector(
      onTap: () => _changeTab(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(AppSize.w(10)),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? activeColor.withValues(alpha: 0.5) : Colors.transparent,
          boxShadow: active
              ? [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.65),
              blurRadius: 2,
              spreadRadius: 0,
            ),
          ]
              : [],
        ),
        child: Icon(
          icon,
          color: active ? Colors.white : Colors.grey,
        ),
      ),
    );
  }

  Widget navWithBadge(IconData icon,
      int i,
      int count,
      Color activeColor,) {
    final bool active = index == i;

    return GestureDetector(
      onTap: () => _changeTab(i),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.all(AppSize.w(10)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? activeColor.withValues(alpha: 0.5) : Colors.transparent,
              boxShadow: active
                  ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.65),
                  blurRadius: 2,
                  spreadRadius: 0,
                ),
              ]
                  : [],
            ),
            child: Icon(
              icon,
              color: active ? Colors.white : Colors.grey,
            ),
          ),

          if (count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: EdgeInsets.all(5.w),
                constraints: BoxConstraints(
                  minWidth: 18.w,
                  minHeight: 18.w,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.secondary,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget navImage(String imagePath,
      int i,
      Color activeColor,) {
    final bool active = index == i;

    return GestureDetector(
      onTap: () => _changeTab(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(AppSize.w(10)),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? activeColor.withValues(alpha: 0.5): Colors.transparent,
          boxShadow: active
              ? [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.65),
              blurRadius: 2,
              spreadRadius: 0,
            ),
          ]
              : [],
        ),
        child: ClipOval(
          child: Image.asset(
            imagePath,
            width: 24.w,
            height: 24.h,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
//
// import 'package:boomboom/authentication/boomboom.dart';
// import 'package:boomboom/authentication/messagescreen.dart';
// import 'package:boomboom/screens/profile/profile.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
//
// import '../constant/colors.dart';
// import 'favourite/favourite.dart';
// import 'home/home.dart';
// import 'home/location/location.dart';
//
// class MainScreen extends StatefulWidget {
//   const MainScreen({super.key});
//
//   @override
//   State<MainScreen> createState() => _MainScreenState();
// }
//
// class _MainScreenState extends State<MainScreen> {
//   int index = 0;
//
//   int get totalUnreadUsers {
//     return MessagePageState.messageList
//         .where((e) => e.unreadCount > 0)
//         .length;
//   }
//
//   final pages = [
//     const HomeScreen(),
//     NearbyMapScreen(),
//     BoomProfileScreen(),
//     LikesScreen(),
//     MessagePage(),
//   ];
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBody: true,
//       backgroundColor: Colors.white10,
//       body: pages[index],
//       bottomNavigationBar: Theme(
//         data: Theme.of(context).copyWith(
//           splashColor: Colors.transparent,
//           highlightColor: Colors.transparent,
//           splashFactory: NoSplash.splashFactory,
//         ),
//         child: BottomNavigationBar(
//           backgroundColor: AppColors.secondary,
//           currentIndex: index,
//           onTap: (i) => setState(() => index = i),
//           type: BottomNavigationBarType.fixed,
//           showSelectedLabels: false,
//           showUnselectedLabels: false,
//           elevation: 0,
//           items: [
//             BottomNavigationBarItem(icon: _navIcon(Icons.home, 0, AppColors.navHome), label: ''),
//             BottomNavigationBarItem(icon: _navIcon(Icons.location_on, 1, AppColors.navLocation), label: ''),
//             BottomNavigationBarItem(icon: _navLogo(2, AppColors.navBoomBoom), label: ''),
//             BottomNavigationBarItem(icon: _navBadge(Icons.favorite, 3, 5, AppColors.navFavourite), label: ''),
//             BottomNavigationBarItem(icon: _navBadge(Icons.forum_rounded, 4, totalUnreadUsers, AppColors.navMessages), label: ''),
//           ],
//         ),
//       ),
//     );
//   }
//   Widget _navIcon(IconData icon, int i, Color activeColor) {
//     final bool active = index == i;
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 250),
//       padding: EdgeInsets.all(10.w), // ✅ Padding kam
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: active ? activeColor : Colors.transparent,
//         boxShadow: active
//             ? [BoxShadow(color: activeColor.withOpacity(0.35), blurRadius: 8, spreadRadius: 0)]
//             : [],
//       ),
//       child: Icon(icon, color: active ? Colors.white : Colors.grey, size: 24.sp),
//     );
//   }
//
//   Widget _navLogo(int i, Color activeColor) {
//     final bool active = index == i;
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 250),
//       padding: EdgeInsets.all(8.w),
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: active ? activeColor : Colors.transparent,
//         boxShadow: active
//             ? [BoxShadow(color: activeColor.withOpacity(0.35), blurRadius: 8, spreadRadius: 0)]
//             : [],
//       ),
//       child: ClipOval(
//         child: Image.asset(
//           "assets/logo.png",
//           width: 24.w,
//           height: 24.h,
//           fit: BoxFit.cover,
//         ),
//       ),
//     );
//   }
//
//   Widget _navBadge(IconData icon, int i, int count, Color activeColor) {
//     final bool active = index == i;
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         AnimatedContainer(
//
//           duration: const Duration(milliseconds: 250),
//           padding: EdgeInsets.all(6.w),
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: active ? activeColor : Colors.transparent,
//             boxShadow: active
//                 ? [BoxShadow(color: activeColor.withOpacity(0.35), blurRadius: 8, spreadRadius: 0)]
//                 : [],
//           ),
//           child: Icon(icon, color: active ? Colors.white : Colors.grey, size: 24.sp),
//         ),
//         if (count > 0)
//           Positioned(
//             right: -2,
//             top: -2,
//             child: Container(
//               padding: EdgeInsets.all(3.w),
//               constraints: BoxConstraints(minWidth: 15.w, minHeight: 15.w),
//               decoration: BoxDecoration(
//                 color: Colors.red,
//                 shape: BoxShape.circle,
//                 border: Border.all(color: AppColors.secondary, width: 1.5),
//               ),
//               child: Center(
//                 child: Text(
//                   '$count',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 9.sp,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }}