import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:xml/xml.dart' as xml;
import '../../../authentication/boomboom.dart';
import '../../../backend/home_service.dart';
import '../../../backend/secure_storage.dart';
import '../../../controller/filter_controller.dart';

// ignore: camel_case_types
class verifyuser extends StatelessWidget {
  const verifyuser({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// =====================================================
/// FULL ACTIVE / VERIFIED MATCH SCREEN
/// =====================================================

class Activeuser extends StatefulWidget {
  final int initialTab; // 0 = Verified, 1 = Active
  const Activeuser({super.key, this.initialTab = 0});

  @override
  State<Activeuser> createState() => _ActiveuserState();
}

class _ActiveuserState extends State<Activeuser> {
  late int selectedTab; // 0 = Verified, 1 = Active
  bool _isLoading = true;

  List<Map<String, dynamic>> activeUsers = [];
  List<Map<String, dynamic>> verifiedUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab;
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    try {
      try {
        _currentPosition = await Geolocator.getLastKnownPosition();
        _currentPosition ??= await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      } catch (_) {}

      final String myEmail = await SecureStorage().getUserEmail() ?? "";

      // 1. Fetch Online Users
      final onlineFuture = HomeService().showOnlineUsers(
        myEmail: myEmail.trim(),
      );

      // 2. Fetch Verified Users
      final verifiedFuture = HomeService().showVerifiedUsers(
        myEmail: myEmail.trim(),
      );

      final results = await Future.wait([onlineFuture, verifiedFuture]);
      final onlineRes = results[0];
      final verifiedRes = results[1];

      List<Map<String, dynamic>> parsedActive = [];
      List<Map<String, dynamic>> parsedVerified = [];

      if (onlineRes.statusCode == 200) {
        final doc = xml.XmlDocument.parse(onlineRes.body);
        final res = doc.findAllElements('ShowOnlineUsersResult');
        if (res.isNotEmpty) {
          final Map<String, dynamic> jsonResult = jsonDecode(
            res.first.innerText,
          );
          if (jsonResult["Status"] == 1 && jsonResult["Data"] is List) {
            parsedActive = _mapUserList(
              jsonResult["Data"],
              defaultOnline: true,
            );
          }
        }
      }

      if (verifiedRes.statusCode == 200) {
        final doc = xml.XmlDocument.parse(verifiedRes.body);
        final res = doc.findAllElements('ShowVerifiedUsersResult');
        if (res.isNotEmpty) {
          final Map<String, dynamic> jsonResult = jsonDecode(
            res.first.innerText,
          );
          if (jsonResult["Status"] == 1 && jsonResult["Data"] is List) {
            parsedVerified = _mapUserList(
              jsonResult["Data"],
              defaultVerified: true,
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          activeUsers = parsedActive;
          verifiedUsers = parsedVerified;
          final currentList = selectedTab == 0 ? verifiedUsers : activeUsers;
          filteredUsers = FilterController.instance.applyFilterToUsers(
            currentList,
            userPosition: _currentPosition,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("[Activeuser] Error fetching data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _mapUserList(
    List rawList, {
    bool defaultOnline = false,
    bool defaultVerified = false,
  }) {
    final List<Map<String, dynamic>> mapped = [];
    for (var u in rawList) {
      final Map<String, dynamic> rawMap = u is Map
          ? Map<String, dynamic>.from(u)
          : {};
      final String name = (rawMap["FullName"] ?? rawMap["name"] ?? "User")
          .toString();
      final String dob = (rawMap["Dob"] ?? rawMap["dob"] ?? "").toString();
      final int age = _calculateAge(dob);

      final String rawOnlineStatus = (rawMap["OnlineStatus"] ??
              rawMap["onlineStatus"] ??
              rawMap["Status"] ??
              rawMap["status"])
          ?.toString()
          .trim()
          .toLowerCase() ??
          "";

      final String onlineValue = (rawMap["IsOnline"] ??
              rawMap["isOnline"] ??
              rawMap["Online"] ??
              "")
          .toString()
          .toLowerCase()
          .trim();

      final bool isOnlineVal = onlineValue == "true" ||
          onlineValue == "1" ||
          onlineValue == "yes" ||
          onlineValue == "online" ||
          defaultOnline;

      String displayStatus = "Offline";
      bool isActiveNow = false;

      if (rawOnlineStatus == "hidden" || rawOnlineStatus == "hide") {
        displayStatus = "Offline";
        isActiveNow = false;
      } else if (rawOnlineStatus == "online" ||
          rawOnlineStatus == "online now" ||
          rawOnlineStatus == "active" ||
          rawOnlineStatus == "active now" ||
          isOnlineVal) {
        displayStatus = "Active now";
        isActiveNow = true;
      } else {
        displayStatus = "Offline";
        isActiveNow = false;
      }

      final bool isVerified =
          rawMap["IsVerified"]?.toString().toLowerCase() == "true" ||
          rawMap["IsVerified"]?.toString() == "1" ||
          defaultVerified;

      final String lookingFor = (rawMap["Lookingfor"] ??
              rawMap["lookingFor"] ??
              rawMap["LookingFor"] ??
              "Friendship")
          .toString();

      final String distance = _calculateDistance(
        rawMap["Lat"]?.toString(),
        rawMap["Lon"]?.toString(),
      );

      final String media =
          (rawMap["Media"] ?? rawMap["media"] ?? rawMap["Photo"] ?? "")
              .toString();

      final String country = (rawMap["Country"] ??
              rawMap["country"] ??
              rawMap["CountryName"] ??
              "India")
          .toString();

      final Map<String, dynamic> item = Map<String, dynamic>.from(rawMap);
      item.addAll({
        "name": name,
        "FullName": name,
        "age": "$age",
        "isActiveNow": isActiveNow,
        "displayStatus": displayStatus,
        "isVerified": isVerified,
        "lookingFor": lookingFor,
        "distance": distance,
        "img": media,
        "Media": media,
        "country": country,
        "liked": false,
        "raw": rawMap,
      });
      mapped.add(item);
    }
    return mapped;
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
      return "50km";
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
        return "${meters.toStringAsFixed(0)}m";
      } else {
        return "${km.toStringAsFixed(0)}km";
      }
    } catch (_) {
      return "50km";
    }
  }

  String _getCountryFlag(String country) {
    final c = country.trim().toLowerCase();
    if (c.contains("thailand") ||
        c.contains("thai") ||
        c.contains("bangkok") ||
        c.contains("chiang mai")) {
      return "🇹🇭";
    }
    if (c.contains("india") || c.contains("ind")) return "🇮🇳";
    if (c.contains("usa") ||
        c.contains("united states") ||
        c.contains("america")) {
      return "🇺🇸";
    }
    if (c.contains("uk") ||
        c.contains("united kingdom") ||
        c.contains("england")) {
      return "🇬🇧";
    }
    if (c.contains("canada")) return "🇨🇦";
    if (c.contains("australia")) return "🇦🇺";
    if (c.contains("germany")) return "🇩🇪";
    if (c.contains("france")) return "🇫🇷";
    if (c.contains("spain")) return "🇪🇸";
    if (c.contains("italy")) return "🇮🇹";
    if (c.contains("japan") || c.contains("tokyo")) return "🇯🇵";
    if (c.contains("china")) return "🇨🇳";
    if (c.contains("russia")) return "🇷🇺";
    if (c.contains("brazil")) return "🇧🇷";
    if (c.contains("vietnam")) return "🇻🇳";
    if (c.contains("indonesia") || c.contains("bali")) return "🇮🇩";
    if (c.contains("philippines")) return "🇵🇭";
    if (c.contains("singapore")) return "🇸🇬";
    if (c.contains("malaysia")) return "🇲🇾";
    if (c.contains("dubai") || c.contains("uae")) return "🇦🇪";
    return "🌍";
  }

  Widget _buildNoImageBackground(String? name) {
    final initial = (name != null && name.trim().isNotEmpty)
        ? name.trim()[0].toUpperCase()
        : "U";

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C3E50), Color(0xFF000000)],
        ),
      ),
      child: Center(
        child: Container(
          width: 55.w,
          height: 55.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
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
            SizedBox(height: 2.h),

            /// ── TOP TAB SELECTOR (Verified Profiles / Active Profiles) ──
            Container(
              margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: const Color(0xFF141416),
                borderRadius: BorderRadius.circular(35.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTab = 0;
                          filteredUsers = FilterController.instance
                              .applyFilterToUsers(
                                verifiedUsers,
                                userPosition: _currentPosition,
                              );
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: selectedTab == 0
                              ? const Color(0xFF2563EB)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Center(
                          child: Text(
                            "Verified Profiles",
                            style: TextStyle(
                              color: selectedTab == 0
                                  ? Colors.white
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5.sp,
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
                          filteredUsers = FilterController.instance
                              .applyFilterToUsers(
                                activeUsers,
                                userPosition: _currentPosition,
                              );
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: selectedTab == 1
                              ? const Color(0xFF2563EB)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Center(
                          child: Text(
                            "Active Profiles",
                            style: TextStyle(
                              color: selectedTab == 1
                                  ? Colors.white
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8.h),

            /// ── 2-COLUMN GRID ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                        strokeWidth: 2.5,
                      ),
                    )
                  : filteredUsers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Text(
                          selectedTab == 0
                              ? "No verified profiles available right now."
                              : "No active profiles available right now.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      itemCount: filteredUsers.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.w,
                        mainAxisSpacing: 10.h,
                        childAspectRatio: 0.58,
                      ),
                      itemBuilder: (_, index) {
                        final user = filteredUsers[index];
                        final String img = (user["img"] ?? "").toString();
                        final bool hasValidImg =
                            img.isNotEmpty &&
                            img.toLowerCase() != "null" &&
                            (img.startsWith("http") || img.startsWith("https"));
                        final bool isActiveNow = user["isActiveNow"] == true;
                        final String displayStatus =
                            (user["displayStatus"] ?? "Offline").toString();
                        final bool isVerified = user["isVerified"] == true;
                        final bool isLiked = user["liked"] == true;
                        final String country =
                            (user["country"] ?? "India").toString();
                        final String flag = _getCountryFlag(country);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BoomProfileScreen(
                                  userEmail:
                                      user["EmailAddress"]?.toString() ??
                                      user["email"]?.toString(),
                                  initialUserData: user,
                                  showLike: false,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22.r),
                              color: const Color(0xFF151515),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22.r),
                              child: Stack(
                                fit: StackFit.expand,
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
                                        : _buildNoImageBackground(user["name"]),
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
                                              alpha: 0.35,
                                            ),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 0.5, 0.85],
                                        ),
                                      ),
                                    ),
                                  ),

                                  /// TOP-LEFT "NEW" BADGE
                                  Positioned(
                                    top: 10.h,
                                    left: 10.w,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 3.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF2563EB),
                                            Color(0xFF1D4ED8),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF2563EB,
                                            ).withValues(alpha: 0.5),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        "NEW",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 9.sp,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),

                                  /// TOP-RIGHT HEART/LIKE BUTTON
                                  Positioned(
                                    top: 10.h,
                                    right: 10.w,
                                    child: GestureDetector(
                                      onTap: () async {
                                        setState(() {
                                          user["liked"] = !isLiked;
                                        });
                                        try {
                                          final myEmail =
                                              await SecureStorage()
                                                  .getUserEmail() ??
                                              "";
                                          final otherEmail =
                                              user["EmailAddress"]?.toString() ??
                                              user["email"]?.toString() ??
                                              "";
                                          if (myEmail.isNotEmpty &&
                                              otherEmail.isNotEmpty) {
                                            HomeService().favoriteLikeViewInsert(
                                              myEmail: myEmail.trim(),
                                              actionEmail: otherEmail.trim(),
                                              action: "like",
                                            );
                                          }
                                        } catch (_) {}
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(4.w),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                        child: Icon(
                                          isLiked
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          color: isLiked
                                              ? Colors.redAccent
                                              : Colors.white,
                                          size: 22.sp,
                                        ),
                                      ),
                                    ),
                                  ),

                                  /// BOTTOM DETAILS
                                  Positioned(
                                    left: 8.w,
                                    right: 8.w,
                                    bottom: 10.h,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        /// NAME + AGE + VERIFIED BADGE
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                "${user["name"]}, ${user["age"]}",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13.sp,
                                                ),
                                              ),
                                            ),
                                            if (isVerified) ...[
                                              SizedBox(width: 4.w),
                                              Icon(
                                                Icons.verified_rounded,
                                                color: Colors.blueAccent,
                                                size: 13.sp,
                                              ),
                                            ],
                                          ],
                                        ),

                                        SizedBox(height: 4.h),

                                        /// COUNTRY PILL
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6.w,
                                            vertical: 2.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.5,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                          ),
                                          child: Text(
                                            "$flag $country",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),

                                        SizedBox(height: 3.h),

                                        /// DISTANCE PILL
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6.w,
                                            vertical: 2.h,
                                              ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.5,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                color: Colors.white70,
                                                size: 9.sp,
                                              ),
                                              SizedBox(width: 2.w),
                                              Text(
                                                "${user["distance"]} away",
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 9.sp,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        SizedBox(height: 4.h),

                                        /// STATUS + RELATIONSHIP GOAL
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            /// STATUS (Active now / Offline)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 6.w,
                                                  height: 6.w,
                                                  decoration: BoxDecoration(
                                                    color: isActiveNow
                                                        ? const Color(
                                                            0xFF00E676,
                                                          )
                                                        : Colors.grey,
                                                    shape: BoxShape.circle,
                                                    boxShadow: isActiveNow
                                                        ? [
                                                            BoxShadow(
                                                              color:
                                                                  const Color(
                                                                    0xFF00E676,
                                                                  ).withValues(
                                                                    alpha: 0.6,
                                                                  ),
                                                              blurRadius: 6,
                                                            ),
                                                          ]
                                                        : null,
                                                  ),
                                                ),
                                                SizedBox(width: 4.w),
                                                Text(
                                                  displayStatus,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 8.5.sp,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            /// RELATIONSHIP GOAL CHIP (Solid Blue Border)
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 7.w,
                                                vertical: 2.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF2563EB,
                                                  ),
                                                  width: 1.2,
                                                ),
                                              ),
                                              child: Text(
                                                "${user["lookingFor"]}",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8.5.sp,
                                                  fontWeight: FontWeight.w700,
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
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
