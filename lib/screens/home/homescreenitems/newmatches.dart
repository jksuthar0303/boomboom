import 'dart:convert';
import 'package:boomboom/backend/home_service.dart';
import 'package:boomboom/backend/secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:xml/xml.dart' as xml;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import '../../../authentication/boomboom.dart';
import '../../../constant/apptextstyle.dart';
import '../../../controller/filter_controller.dart';

class YourMatchesSection extends StatelessWidget {
  const YourMatchesSection({super.key});

  final List<Map<String, String>> data = const [
    {
      "name": "Ava",
      "age": "24",
      "country": "Thailand",
      "distance": "2km",
      "time": "55 Seconds Ago",
      "img": "https://images.unsplash.com/photo-1544005313-94ddf0286df2",
    },

    {
      "name": "Emma",
      "age": "22",
      "country": "India",
      "distance": "5km",
      "time": "55 Seconds Ago",
      "img": "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e",
    },

    {
      "name": "Sophia",
      "age": "25",
      "country": "USA",
      "distance": "7km",
      "time": "55 Seconds Ago",
      "img": "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
    },

    {
      "name": "Olivia",
      "age": "23",
      "country": "Japan",
      "distance": "9km",
      "time": "55 Seconds Ago",
      "img": "https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91",
    },

    {
      "name": "Isabella",
      "age": "21",
      "country": "China",
      "distance": "11km",
      "time": "55 Seconds Ago",
      "img": "https://images.unsplash.com/photo-1517841905240-472988babdf9",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return SizedBox(
      height: isTablet ? 180.h : 140.h,

      child: ListView(
        scrollDirection: Axis.horizontal,

        padding: EdgeInsets.symmetric(horizontal: 12.w),

        children: [
          ...data.map((e) => smallCard(e, isTablet)),

          seeAllCard(context, isTablet),
        ],
      ),
    );
  }

  Widget smallCard(Map<String, dynamic> e, bool isTablet) {
    final name = e["name"]?.toString() ?? "";
    final age = e["age"]?.toString() ?? "";
    final image = e["img"]?.toString() ?? "";
    return GestureDetector(
      onTap: () {
        Get.to(
          () => BoomProfileScreen(
            userEmail: e["EmailAddress"]?.toString() ?? e["email"]?.toString(),
            initialUserData: e,
          ),
          transition: Transition.rightToLeft,
        );
      },

      child: Container(
        width: isTablet ? 160.w : 120.w,

        margin: EdgeInsets.only(right: 12.w),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),

              blurRadius: 10,

              offset: const Offset(4, 6),
            ),
          ],

          image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
        ),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),

          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,

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
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      "$name, $age",

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: AppTextStyles.small.copyWith(
                        color: Colors.white,

                        fontWeight: FontWeight.bold,

                        fontSize: isTablet ? 14.sp : 12.sp,
                      ),
                    ),

                    SizedBox(height: 2.h),

                    Text(
                      "55 Seconds Ago",

                      style: AppTextStyles.small.copyWith(
                        color: Colors.white70,

                        fontSize: isTablet ? 11.sp : 9.sp,
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
  Widget seeAllCard(BuildContext context, bool isTablet) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,

          MaterialPageRoute(builder: (_) => const MatchesScreen()),
        );
      },

      child: Container(
        width: isTablet ? 140.w : 100.w,

        margin: EdgeInsets.only(right: 12.w),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),

          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.15),

              Colors.white.withValues(alpha: 0.05),
            ],
          ),

          border: Border.all(color: Colors.amber, width: 1.5),

          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.4),

              blurRadius: 12,
            ),
          ],
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 14.w : 10.w),

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                gradient: const LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                ),
              ),

              child: Icon(
                Icons.arrow_forward,

                color: Colors.black,

                size: isTablet ? 22.sp : 18.sp,
              ),
            ),

            SizedBox(height: 10.h),

            Text(
              "See All",

              style: AppTextStyles.small.copyWith(
                color: Colors.white,

                fontWeight: FontWeight.w600,

                fontSize: isTablet ? 14.sp : 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =====================================================
/// FULL MATCH SCREEN (EVERYONE - ALL USERS)
/// =====================================================

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final TextEditingController searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    try {
      try {
        _currentPosition = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      final String myEmail = await SecureStorage().getUserEmail() ?? "";
      final response = await HomeService().showAllExceptMe(
        myEmail: myEmail.trim(),
      );

      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        final res = doc.findAllElements('ShowAllExceptMeResult');
        if (res.isNotEmpty) {
          final Map<String, dynamic> jsonResult = jsonDecode(
            res.first.innerText,
          );
          if (jsonResult["Status"] == 1 && jsonResult["Data"] is List) {
            final List rawList = jsonResult["Data"];

            final List<Map<String, dynamic>> mapped = [];
            for (var u in rawList) {
              final Map<String, dynamic> rawMap = u is Map
                  ? Map<String, dynamic>.from(u)
                  : {};
              final String name =
                  (rawMap["FullName"] ?? rawMap["name"] ?? "User").toString();
              final String dob = (rawMap["Dob"] ?? rawMap["dob"] ?? "")
                  .toString();
              final int age = _calculateAge(dob);
              final String rawOnlineStatus =
                  (rawMap["OnlineStatus"] ??
                          rawMap["onlineStatus"] ??
                          rawMap["Status"] ??
                          rawMap["status"])
                      ?.toString()
                      .trim() ??
                  "";
              final String onlineValue =
                  (rawMap["IsOnline"] ??
                          rawMap["isOnline"] ??
                          rawMap["Online"] ??
                          "")
                      .toString()
                      .toLowerCase()
                      .trim();
              final bool isOnlineVal =
                  onlineValue == "true" ||
                  onlineValue == "1" ||
                  onlineValue == "yes" ||
                  onlineValue == "online";
              final String onlineStatus =
                  rawOnlineStatus.isNotEmpty &&
                      rawOnlineStatus.toLowerCase() != "null"
                  ? rawOnlineStatus
                  : (isOnlineVal ? "Online" : "Offline");
              final String sLower = onlineStatus.toLowerCase();
              final bool isOnline =
                  (sLower == "online" ||
                      sLower == "online now" ||
                      sLower == "active" ||
                      sLower == "active now") &&
                  sLower != "hidden" &&
                  sLower != "offline";
              final bool isVerified =
                  rawMap["IsVerified"]?.toString().toLowerCase() == "true";
              final String lookingFor =
                  (rawMap["Lookingfor"] ??
                          rawMap["lookingFor"] ??
                          "Serious Love")
                      .toString();
              final String distance = _calculateDistance(
                rawMap["Lat"]?.toString(),
                rawMap["Lon"]?.toString(),
              );
              final String media =
                  (rawMap["Media"] ?? rawMap["media"] ?? rawMap["Photo"] ?? "")
                      .toString();

              final Map<String, dynamic> item = Map<String, dynamic>.from(
                rawMap,
              );
              item.addAll({
                "name": name,
                "FullName": name,
                "age": "$age",
                "isOnline": isOnline,
                "onlineStatus": onlineStatus,
                "isVerified": isVerified,
                "lookingFor": lookingFor,
                "distance": distance,
                "img": media,
                "Media": media,
                "country":
                    (rawMap["Country"] ??
                            rawMap["country"] ??
                            rawMap["CountryName"] ??
                            "India")
                        .toString(),
                "liked": false,
                "raw": rawMap,
              });
              mapped.add(item);
            }

            if (mounted) {
              setState(() {
                allUsers = mapped;
                filteredUsers = List.from(mapped);
                _isLoading = false;
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("[MatchesScreen] Error fetching ShowAllExceptMe: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _calculateAge(String? dobStr) {
    if (dobStr == null || dobStr.isEmpty) return 24;
    try {
      final dob = DateTime.parse(dobStr);
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month ||
          (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age > 0 ? age : 24;
    } catch (_) {
      return 24;
    }
  }

  String _calculateDistance(String? latStr, String? lonStr) {
    if (latStr == null ||
        lonStr == null ||
        latStr.isEmpty ||
        lonStr.isEmpty ||
        latStr == "0.0" ||
        lonStr == "0.0" ||
        _currentPosition == null) {
      return "1.2 km";
    }

    try {
      final double lat = double.parse(latStr);
      final double lon = double.parse(lonStr);
      final double meters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        lat,
        lon,
      );
      final double km = meters / 1000;
      if (km < 1) {
        return "${meters.toStringAsFixed(0)} m";
      } else {
        return "${km.toStringAsFixed(1)} km";
      }
    } catch (_) {
      return "1.2 km";
    }
  }

  void searchUsers(String value) {
    setState(() {
      filteredUsers = allUsers.where((user) {
        final name = user["name"].toString().toLowerCase();
        final lookingFor = user["lookingFor"].toString().toLowerCase();
        final age = user["age"].toString().toLowerCase();
        final search = value.toLowerCase().trim();

        return name.contains(search) ||
            lookingFor.contains(search) ||
            age.contains(search);
      }).toList();
    });
  }

  Future<void> toggleLike(int index) async {
    final user = filteredUsers[index];
    final actionEmail =
        (user["EmailAddress"] ??
                user["email"] ??
                user["raw"]?["EmailAddress"] ??
                user["raw"]?["email"])
            ?.toString()
            .trim();
    if (actionEmail == null || actionEmail.isEmpty) return;

    final bool nextLiked = !(user["liked"] == true);
    setState(() {
      user["liked"] = nextLiked;
    });

    try {
      final myEmail = await SecureStorage().getUserEmail() ?? '';
      final response = await HomeService().favoriteLikeViewInsert(
        myEmail: myEmail.trim(),
        actionEmail: actionEmail,
        action: nextLiked ? 'like' : 'unlike',
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => user["liked"] = !nextLiked);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Like save nahi ho saka.')),
        );
      }
    }
  }

  Widget _buildNoImageBackground(String name) {
    final String initial = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : "U";

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF28133E), Color(0xFF1B1B2F), Color(0xFF110E1D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF9B59B6), Color(0xFF3498DB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9B59B6).withValues(alpha: 0.35),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: Column(
          children: [
            /// SEARCH BAR WITH BACK BUTTON
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 8.w, 0),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Container(
                      height: 44.h,
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Center(
                        child: TextField(
                          controller: searchController,
                          onChanged: searchUsers,
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5.sp,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10.h,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white70,
                              size: 20,
                            ),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 30.w,
                              minHeight: 20,
                            ),
                            hintText: "Search by Country, Name or Age",
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6.h),

            /// GRID
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF9B59B6),
                        strokeWidth: 2.5,
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        final displayList = FilterController.instance
                            .applyFilterToUsers(
                              searchController.text.trim().isEmpty
                                  ? allUsers
                                  : allUsers.where((user) {
                                      final q = searchController.text
                                          .toLowerCase()
                                          .trim();
                                      final name =
                                          (user["FullName"] ??
                                                  user["name"] ??
                                                  "")
                                              .toString()
                                              .toLowerCase();
                                      final lookingFor =
                                          (user["Lookingfor"] ??
                                                  user["lookingFor"] ??
                                                  "")
                                              .toString()
                                              .toLowerCase();
                                      final age = (user["age"] ?? "")
                                          .toString()
                                          .toLowerCase();
                                      final country =
                                          (user["Country"] ??
                                                  user["country"] ??
                                                  "")
                                              .toString()
                                              .toLowerCase();
                                      final city =
                                          (user["City"] ?? user["city"] ?? "")
                                              .toString()
                                              .toLowerCase();
                                      final district =
                                          (user["District"] ??
                                                  user["district"] ??
                                                  "")
                                              .toString()
                                              .toLowerCase();

                                      return name.contains(q) ||
                                          lookingFor.contains(q) ||
                                          age.contains(q) ||
                                          country.contains(q) ||
                                          city.contains(q) ||
                                          district.contains(q);
                                    }).toList(),
                              userPosition: _currentPosition,
                            );

                        if (displayList.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 28.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 78.w,
                                    height: 78.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.cyanAccent.withValues(
                                        alpha: 0.10,
                                      ),
                                      border: Border.all(
                                        color: Colors.cyanAccent.withValues(
                                          alpha: 0.35,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.people_alt_rounded,
                                      color: Colors.cyanAccent,
                                      size: 40.sp,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    "No matches yet",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 7.h),
                                  Text(
                                    "New people will appear here as they join.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13.sp,
                                      height: 1.4,
                                    ),
                                  ),
                                  SizedBox(height: 14.h),
                                  TextButton.icon(
                                    onPressed: _fetchAllUsers,
                                    icon: Icon(
                                      Icons.refresh_rounded,
                                      color: Colors.cyanAccent,
                                      size: 18.sp,
                                    ),
                                    label: Text(
                                      "Refresh",
                                      style: TextStyle(
                                        color: Colors.cyanAccent,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: EdgeInsets.only(
                            left: 6.w,
                            right: 6.w,
                            bottom: 100.h,
                          ),
                          itemCount: displayList.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8.w,
                                mainAxisSpacing: 8.h,
                                childAspectRatio: 0.58,
                              ),
                          itemBuilder: (_, index) {
                            final user = displayList[index];
                            final String img = (user["img"] ?? "").toString();
                            final bool hasValidImg =
                                img.isNotEmpty &&
                                img.toLowerCase() != "null" &&
                                (img.startsWith("http") ||
                                    img.startsWith("https"));
                            final bool isOnline = user["isOnline"] == true;
                            final bool isVerified = user["isVerified"] == true;
                            final String country = (user["country"] ?? "India")
                                .toString();

                            return GestureDetector(
                              onTap: () {
                                final rawMap = (user["raw"] is Map)
                                    ? Map<String, dynamic>.from(user["raw"])
                                    : Map<String, dynamic>.from(user);
                                final email =
                                    rawMap["EmailAddress"]?.toString() ??
                                    rawMap["email"]?.toString() ??
                                    user["EmailAddress"]?.toString() ??
                                    user["email"]?.toString();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BoomProfileScreen(
                                      userEmail: email,
                                      initialUserData: rawMap,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18.r),
                                  color: const Color(0xFF151515),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.45,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18.r),
                                  child: Stack(
                                    children: [
                                      /// BACKGROUND IMAGE / AVATAR
                                      Positioned.fill(
                                        child: hasValidImg
                                            ? Image.network(
                                                img,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    _buildNoImageBackground(
                                                      user["name"],
                                                    ),
                                              )
                                            : _buildNoImageBackground(
                                                user["name"],
                                              ),
                                      ),

                                      /// DARK GRADIENT OVERLAY
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.black.withValues(
                                                  alpha: 0.95,
                                                ),
                                                Colors.black.withValues(
                                                  alpha: 0.2,
                                                ),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      /// TOP LEFT STATUS
                                      Positioned(
                                        top: 10.h,
                                        left: 10.w,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                            vertical: 4.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.5,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20.r,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6.w,
                                                height: 6.w,
                                                decoration: BoxDecoration(
                                                  color: isOnline
                                                      ? const Color(0xFF00E676)
                                                      : Colors.grey,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              SizedBox(width: 4.w),
                                              Text(
                                                (user["onlineStatus"] ??
                                                        (isOnline
                                                            ? "Online"
                                                            : "Offline"))
                                                    .toString(),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 9.sp,
                                                ),
                                              ),
                                            ],
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
                                          child: Icon(
                                            user["liked"]
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            color: user["liked"]
                                                ? Colors.red
                                                : Colors.white,
                                            size: 22.sp,
                                          ),
                                        ),
                                      ),

                                      /// BOTTOM DETAILS
                                      Positioned(
                                        left: 8.w,
                                        right: 8.w,
                                        bottom: 8.h,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            /// NAME & AGE
                                            Row(
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
                                                if (isVerified) ...[
                                                  SizedBox(width: 3.w),
                                                  Icon(
                                                    Icons.verified_rounded,
                                                    color: Colors.cyanAccent,
                                                    size: 13.sp,
                                                  ),
                                                ],
                                              ],
                                            ),

                                            SizedBox(height: 4.h),

                                            /// COUNTRY
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 6.w,
                                                vertical: 2.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.45,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    countryFlag(country),
                                                    style: TextStyle(
                                                      fontSize: 9.sp,
                                                    ),
                                                  ),
                                                  SizedBox(width: 3.w),
                                                  Text(
                                                    country,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9.sp,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            SizedBox(height: 3.h),

                                            /// DISTANCE & LOOKING FOR ROW
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                /// Left: Distance
                                                Flexible(
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 6.w,
                                                          vertical: 2.h,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.45,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12.r,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.location_on,
                                                          color: Colors
                                                              .purpleAccent,
                                                          size: 9.sp,
                                                        ),
                                                        SizedBox(width: 2.w),
                                                        Flexible(
                                                          child: Text(
                                                            "${user["distance"]}"
                                                                    .toLowerCase()
                                                                    .contains(
                                                                      "away",
                                                                    )
                                                                ? "${user["distance"]}"
                                                                : "${user["distance"]} away",
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .white70,
                                                              fontSize: 9.sp,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 4.w),

                                                /// Right: Relationship Goal Chip (Truncated with Ellipsis)
                                                Flexible(
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 6.w,
                                                          vertical: 2.h,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.45,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12.r,
                                                          ),
                                                      border: Border.all(
                                                        color: const Color(
                                                          0xFF2563EB,
                                                        ),
                                                        width: 1.0,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "${user["lookingFor"]}",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 8.5.sp,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
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
                              ),
                            );
                          },
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
