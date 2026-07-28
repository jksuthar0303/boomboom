import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';

import '../../../authentication/boomboom.dart';
import '../../../constant/apptextstyle.dart';

class verifyuser extends StatelessWidget {
  const verifyuser({super.key});

  final List<Map<String, String>> data = const [

    {
      "name": "Ava",
      "age": "24",
      "country": "Thailand",
      "distance": "2km",
      "time": "55 Seconds Ago",
      "img":
      "https://images.unsplash.com/photo-1544005313-94ddf0286df2"
    },

    {
      "name": "Emma",
      "age": "22",
      "country": "India",
      "distance": "5km",
      "time": "55 Seconds Ago",
      "img":
      "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e"
    },

    {
      "name": "Sophia",
      "age": "25",
      "country": "USA",
      "distance": "7km",
      "time": "55 Seconds Ago",
      "img":
      "https://images.unsplash.com/photo-1494790108377-be9c29b29330"
    },

    {
      "name": "Olivia",
      "age": "23",
      "country": "Japan",
      "distance": "9km",
      "time": "55 Seconds Ago",
      "img":
      "https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91"
    },

    {
      "name": "Isabella",
      "age": "21",
      "country": "China",
      "distance": "11km",
      "time": "55 Seconds Ago",
      "img":
      "https://images.unsplash.com/photo-1517841905240-472988babdf9"
    },
  ];

  @override
  Widget build(BuildContext context) {

    final isTablet =
        MediaQuery.of(context).size.width > 600;

    return SizedBox(

      height: isTablet ? 180.h : 140.h,

      child: ListView(
        scrollDirection: Axis.horizontal,

        padding:
        EdgeInsets.symmetric(horizontal: 12.w),

        children: [

          ...data.map(
                (e) => smallCard(
              e["name"]!,
              e["age"]!,
              e["img"]!,
              isTablet,
            ),
          ),

          seeAllCard(context, isTablet),
        ],
      ),
    );
  }

  /// SMALL CARD
  Widget smallCard(
      String name,
      String age,
      String image,
      bool isTablet,
      ){
    return  GestureDetector(

      onTap: () {

        Get.to(
              () =>  BoomProfileScreen(),
          transition: Transition.rightToLeft,
        );
      },

      child: Container(

        width: isTablet ? 160.w : 120.w,

        margin: EdgeInsets.only(right: 12.w),

        decoration: BoxDecoration(

          borderRadius:
          BorderRadius.circular(16.r),

          boxShadow: [

            BoxShadow(
              color:
              Colors.black.withValues(alpha: 0.5),

              blurRadius: 10,

              offset: const Offset(4, 6),
            ),
          ],

          image: DecorationImage(
            image: NetworkImage(image),
            fit: BoxFit.cover,
          ),
        ),

        child: ClipRRect(

          borderRadius:
          BorderRadius.circular(16.r),

          child: Stack(
            children: [

              Container(
                decoration: BoxDecoration(

                  gradient: LinearGradient(
                    begin:
                    Alignment.bottomCenter,

                    end: Alignment.topCenter,

                    colors: [
                      Colors.black.withValues(alpha: 0.9),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: 10,
                left: 10,
                right: 10,

                child: Column(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Text(
                      "$name, $age",

                      maxLines: 1,

                      overflow:
                      TextOverflow.ellipsis,

                      style:
                      AppTextStyles.small.copyWith(
                        color: Colors.white,

                        fontWeight:
                        FontWeight.bold,

                        fontSize:
                        isTablet
                            ? 14.sp
                            : 12.sp,
                      ),
                    ),

                    SizedBox(height: 2.h),

                    Text(
                      "55 Seconds Ago",

                      style:
                      AppTextStyles.small.copyWith(
                        color: Colors.white70,

                        fontSize:
                        isTablet
                            ? 11.sp
                            : 9.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }

  /// SEE ALL CARD
  Widget seeAllCard(
      BuildContext context,
      bool isTablet,
      ) {

    return GestureDetector(

      onTap: () {

        Navigator.push(
          context,

          MaterialPageRoute(
            builder: (_) =>
            const Activeuser(),
          ),
        );
      },

      child: Container(

        width: isTablet ? 140.w : 100.w,

        margin: EdgeInsets.only(right: 12.w),

        decoration: BoxDecoration(

          borderRadius:
          BorderRadius.circular(16.r),

          gradient: LinearGradient(
            colors: [

              Colors.white.withValues(alpha: 0.15),

              Colors.white.withValues(alpha: 0.05),
            ],
          ),

          border: Border.all(
            color: Colors.amber,
            width: 1.5,
          ),

          boxShadow: [

            BoxShadow(
              color:
              Colors.amber.withValues(alpha: 0.4),

              blurRadius: 12,
            )
          ],
        ),

        child: Column(

          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [

            Container(

              padding: EdgeInsets.all(
                  isTablet ? 14.w : 10.w),

              decoration: BoxDecoration(

                shape: BoxShape.circle,

                gradient: const LinearGradient(
                  colors: [
                    Colors.amber,
                    Colors.orange,
                  ],
                ),
              ),

              child: Icon(
                Icons.arrow_forward,

                color: Colors.black,

                size:
                isTablet ? 22.sp : 18.sp,
              ),
            ),

            SizedBox(height: 10.h),

            Text(
              "See All",

              style:
              AppTextStyles.small.copyWith(
                color: Colors.white,

                fontWeight:
                FontWeight.w600,

                fontSize:
                isTablet ? 14.sp : 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =====================================================
/// FULL MATCH SCREEN
/// =====================================================

class Activeuser extends StatefulWidget {
  const Activeuser({super.key});

  @override
  State<Activeuser> createState() => _ActiveuserState();
}

class _ActiveuserState extends State<Activeuser> {

  //List<Map<String, dynamic>> allUsers = [
    // saara user data
 // ];

  List<Map<String, dynamic>> filteredUsers = [];

  List<Map<String, dynamic>> verifiedUsers = [];
  List<Map<String, dynamic>> activeUsers = [];

  int selectedTab = 0;
  List<Map<String, dynamic>> allUsers = [

    {
      "name": "Jyunko",
      "age": "26",
      "country": "Thailand",
      "distance": "50km",
      "liked": false,
      "img":
      "https://images.unsplash.com/photo-1544005313-94ddf0286df2"
    },

    {
      "name": "Pin107",
      "age": "25",
      "country": "Chiang Mai",
      "distance": "2475km",
      "liked": false,
      "img":
      "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e"
    },

    {
      "name": "Namkang16TH",
      "age": "57",
      "country": "Bangkok",
      "distance": "29km",
      "liked": false,
      "img":
      "https://images.unsplash.com/photo-1494790108377-be9c29b29330"
    },

    {
      "name": "Ploy15987",
      "age": "22",
      "country": "India",
      "distance": "8757km",
      "liked": false,
      "img":
      "https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91",
      "district": "Pattaya",
    },

    {
      "name": "Rose",
      "age": "21",
      "country": "Japan",
      "distance": "18km",
      "liked": false,
      "img":
      "https://images.unsplash.com/photo-1517841905240-472988babdf9",
      "district": "Pattaya",
    },

    {
      "name": "Lina",
      "age": "24",
      "country": "Korea",
      "distance": "90km",
      "liked": false,
      "img":
      "https://images.unsplash.com/photo-1488426862026-3ee34a7d66df",
      "district": "Pattaya",
    },

    {
      "name": "Anya",
      "age": "20",
      "country": "Russia",
      "distance": "120km",
      "liked": false,
      "img":
      "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
      "district": "Pattaya",
    },

    {
      "name": "Mika",
      "age": "27",
      "country": "Tokyo",
      "distance": "77km",
      "liked": false,
      "img":
      "https://images.unsplash.com/photo-1524504388940-b1c1722653e1",
      "district": "Pattaya",
    },
  ];

  //List<Map<String, dynamic>> filteredUsers = [];

  //int selectedTab = 0;

  // List<Map<String, dynamic>> get activeUsers => null;
  // List<Map<String, dynamic>> activeUsers = [];

  @override
  void initState() {
    super.initState();

    verifiedUsers = allUsers.take(4).toList();
    activeUsers = allUsers.skip(4).toList();

    filteredUsers = verifiedUsers;
  }
  // void searchUsers(String value) {
  //
  //   setState(() {
  //
  //     filteredUsers =
  //         allUsers.where((user) {
  //
  //           final name =
  //           user["name"]
  //               .toString()
  //               .toLowerCase();
  //
  //           final country =
  //           user["country"]
  //               .toString()
  //               .toLowerCase();
  //
  //           final age =
  //           user["age"]
  //               .toString()
  //               .toLowerCase();
  //
  //           final district =
  //           user["district"]
  //               .toString()
  //               .toLowerCase();
  //
  //           final search =
  //           value.toLowerCase();
  //
  //           return name.contains(search) ||
  //               country.contains(search) ||
  //               district.contains(search) ||
  //               age.contains(search);
  //         }).toList();
  //   });
  // }

  void removeUser(int index) {

    setState(() {

      final user = filteredUsers[index];

      allUsers.remove(user);

      filteredUsers.removeAt(index);
    });
  }

  void toggleLike(int index) {

    setState(() {

      filteredUsers[index]["liked"] =
      !filteredUsers[index]["liked"];
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      body: SafeArea(

        child: Column(
          children: [
            SizedBox(height: 10.h),

            Container(
              margin: EdgeInsets.symmetric(horizontal: 12.w),
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTab = 0;
                          filteredUsers = verifiedUsers;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: selectedTab == 0
                              ? const Color(0xFF2D7DFF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        child: Center(
                          child: Text(
                            "Verified Profiles",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTab = 1;
                          filteredUsers = activeUsers;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: selectedTab == 1
                              ? const Color(0xFF00E676)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        child: Center(
                          child: Text(
                            "Active Profiles",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18.sp
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.h),
            //SizedBox(height: 15.h),

            /// GRID
            Expanded(

              child: GridView.builder(

                padding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                ),

                itemCount:
                filteredUsers.length,

                gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(

                  crossAxisCount: 2,

                  crossAxisSpacing: 5.w,

                  mainAxisSpacing: 5.h,

                  childAspectRatio: 0.62,
                ),

                itemBuilder: (_, index) {

                  final user = filteredUsers[index];

                  return GestureDetector(

                    onTap: () {

                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) =>
                         BoomProfileScreen(),
                        ),
                      );
                    },

                    child: Container(

                      decoration: BoxDecoration(

                        borderRadius:
                        BorderRadius.circular(18.r),

                        color: const Color(0xFF151515),

                        boxShadow: [

                          BoxShadow(
                            color:
                            Colors.black.withValues(alpha: 0.45),

                            blurRadius: 20,

                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),

                      child: ClipRRect(

                        borderRadius:
                        BorderRadius.circular(24.r),

                        child: Stack(
                          children: [

                            /// IMAGE
                            Positioned.fill(

                              child: Image.network(
                                user["img"],
                                fit: BoxFit.cover,
                              ),
                            ),

                            /// DARK OVERLAY
                            Positioned.fill(

                              child: Container(

                                decoration: BoxDecoration(

                                  gradient: LinearGradient(

                                    begin:
                                    Alignment.bottomCenter,

                                    end:
                                    Alignment.topCenter,

                                    colors: [

                                      Colors.black
                                          .withValues(alpha: 0.95),

                                      Colors.black
                                          .withValues(alpha: 0.1),

                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),


                            /// BOTTOM DETAILS
                            /// TOP LEFT NEW TAG
                            Positioned(
                              top: 10.h,
                              left: 10.w,

                              child: Container(

                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 5.h,
                                ),

                                decoration: BoxDecoration(

                                  borderRadius:
                                  BorderRadius.circular(20.r),

                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2563EB),
                                      Color(0xFF1D4ED8),
                                    ],
                                  ),
                                ),

                                child: Text(

                                  "NEW",

                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ),
                            ),

                            /// TOP RIGHT HEART
                            Positioned(
                              top: 10.h,
                              right: 10.w,
                              child: GestureDetector(
                                onTap: () {
                                  toggleLike(index);
                                },
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(
                                        scale: anim,
                                        child: child,
                                      ),
                                  child: Icon(
                                    user["liked"]
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    key: ValueKey(user["liked"]),
                                    color: user["liked"]
                                        ? Colors.red
                                        : Colors.white,
                                    size: 26.sp,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            /// BOTTOM DETAILS

                            Positioned(
                              top: 10.h,
                              left: 10.w,

                              child: Container(

                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),

                                decoration: BoxDecoration(

                                  borderRadius:
                                  BorderRadius.circular(20.r),

                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2563EB),
                                      Color(0xFF1D4ED8),
                                    ],
                                  ),
                                ),

                                child: Text(

                                  "NEW",

                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ),
                            ),

                            /// TOP RIGHT HEART
                            // Positioned(
                            //   top: 10.h,
                            //   right: 10.w,
                            //
                            //   child: GestureDetector(
                            //
                            //     onTap: () {
                            //       toggleLike(index);
                            //     },
                            //
                            //     child: Container(
                            //
                            //       width: 34.w,
                            //       height: 34.w,
                            //
                            //       decoration: BoxDecoration(
                            //
                            //         shape: BoxShape.circle,
                            //
                            //         color: Colors.black.withOpacity(0.35),
                            //
                            //         border: Border.all(
                            //           color: Colors.white24,
                            //         ),
                            //       ),
                            //
                            //       child: Icon(
                            //
                            //         user["liked"]
                            //             ? Icons.favorite
                            //             : Icons.favorite_border,
                            //
                            //         color: Colors.white,
                            //
                            //         size: 18.sp,
                            //       ),
                            //     ),
                            //   ),
                            // ),

                            /// BOTTOM DETAILS
                            Positioned(

                              left: 4.w,
                              right: 4.w,
                              bottom: 13.h,

                              child: Column(

                                crossAxisAlignment:
                                CrossAxisAlignment.start,

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

                                                overflow:
                                                TextOverflow.ellipsis,

                                                style: TextStyle(

                                                  color: Colors.white,

                                                  fontWeight:
                                                  FontWeight.w900,

                                                  fontSize: 13.sp,
                                                ),
                                              ),
                                            ),

                                            SizedBox(width: 1.w),

                                            Icon(
                                              Icons.verified_rounded,
                                              color: Colors.blueAccent,
                                              size: 11.sp,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 3.h),

                                  /// LOCATION
                                  Container(

                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 2.h,
                                    ),

                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(
                                        color: const Color(0xFF3A3A3A),
                                        width: 1,
                                      ),
                                    ),

                                    child: Row(

                                      mainAxisSize: MainAxisSize.min,

                                      children: [

                                        Text(
                                          "🇮🇳",
                                          style: TextStyle(fontSize: 9.sp),
                                        ),

                                        SizedBox(width: 2.w),

                                        Text(

                                          "${user["country"]}",

                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.w900
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 2.h),

                                  /// DISTANCE
                                  Container(

                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 3.h,
                                    ),

                                    decoration: BoxDecoration(

                                      color: Colors.black.withValues(alpha: 0.35),

                                      borderRadius:
                                      BorderRadius.circular(20.r),
                                    ),

                                    child: Row(

                                      mainAxisSize: MainAxisSize.min,

                                      children: [

                                        Icon(
                                          Icons.location_on_outlined,
                                          color: Colors.white,
                                          size: 8.sp,
                                        ),

                                        SizedBox(width: 1.w),

                                        Text(

                                          "${user["distance"]} away",

                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w900
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 2.h),

                                  /// ONLINE NOW
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
                                                  fontWeight: FontWeight.w900
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.w,
                                          vertical: 3.h,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(30.r),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black.withValues(alpha: 0.55),
                                              Colors.black.withValues(alpha: 0.55),
                                            ],
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF2D7DFF),
                                            width: 1.3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF2D7DFF).withValues(alpha: 0.35),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [

                                            // Icon(
                                            //   Icons.people_outline,
                                            //   color: Colors.white,
                                            //   size: 7.sp,
                                            // ),

                                            //SizedBox(width: 2.w),

                                            Text(
                                              index % 2 == 0
                                                  ? "Friendship"
                                                  : "Casual",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9.sp,
                                                  fontWeight: FontWeight.w900
                                              ),
                                            ),
                                          ],
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
            ),
          ],
        ),
      ),
    );
  }
}