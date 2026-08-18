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
  final int initialTab; // 0 = Active, 1 = Verified
  const Activeuser({super.key, this.initialTab = 0});

  @override
  State<Activeuser> createState() => _ActiveuserState();
}

class _ActiveuserState extends State<Activeuser> {
  final TextEditingController searchController = TextEditingController();
  late int selectedTab;
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
          final currentList = selectedTab == 0 ? activeUsers : verifiedUsers;
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
      final bool isOnline =
          rawMap["IsOnline"]?.toString().toLowerCase() == "true" ||
          defaultOnline;
      final bool isVerified =
          rawMap["IsVerified"]?.toString().toLowerCase() == "true" ||
          defaultVerified;
      final String lookingFor =
          (rawMap["Lookingfor"] ?? rawMap["lookingFor"] ?? "Serious Love")
              .toString();
      final String distance = _calculateDistance(
        rawMap["Lat"]?.toString(),
        rawMap["Lon"]?.toString(),
      );
      final String media =
          (rawMap["Media"] ?? rawMap["media"] ?? rawMap["Photo"] ?? "")
              .toString();

      final Map<String, dynamic> item = Map<String, dynamic>.from(rawMap);
      item.addAll({
        "name": name,
        "FullName": name,
        "age": "$age",
        "isOnline": isOnline,
        "isVerified": isVerified,
        "lookingFor": lookingFor,
        "distance": distance,
        "img": media,
        "Media": media,
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
    final list = selectedTab == 0 ? activeUsers : verifiedUsers;
    final filtered = FilterController.instance.applyFilterToUsers(
      list,
      userPosition: _currentPosition,
    );
    setState(() {
      final search = value.toLowerCase().trim();
      if (search.isEmpty) {
        filteredUsers = filtered;
      } else {
        filteredUsers = filtered.where((user) {
          final name = user["name"].toString().toLowerCase();
          final lookingFor = user["lookingFor"].toString().toLowerCase();
          final age = user["age"].toString().toLowerCase();

          return name.contains(search) ||
              lookingFor.contains(search) ||
              age.contains(search);
        }).toList();
      }
    });
  }

  void toggleLike(int index) {
    setState(() {
      filteredUsers[index]["liked"] = !filteredUsers[index]["liked"];
    });
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
            SizedBox(height: 10.h),

            /// SEARCH BAR
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Container(
                      height: 46.h,
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: searchUsers,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.white70),
                          hintText: "Search name, age, looking for...",
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            /// TAB SELECTOR
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
                          searchController.clear();
                          filteredUsers = FilterController.instance
                              .applyFilterToUsers(
                                activeUsers,
                                userPosition: _currentPosition,
                              );
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: selectedTab == 0
                              ? const Color(0xFF00E676)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                "Active Profiles",
                                style: TextStyle(
                                  color: selectedTab == 0
                                      ? Colors.black
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
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
                          searchController.clear();
                          filteredUsers = FilterController.instance
                              .applyFilterToUsers(
                                verifiedUsers,
                                userPosition: _currentPosition,
                              );
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: selectedTab == 1
                              ? const Color(0xFF2D7DFF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 14.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                "Verified Profiles",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 15.h),

            /// GRID
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF9B59B6),
                        strokeWidth: 2.5,
                      ),
                    )
                  : filteredUsers.isEmpty
                  ? Center(
                      child: Text(
                        selectedTab == 0
                            ? "No active users found"
                            : "No verified users found",
                        style: const TextStyle(color: Colors.white60),
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      itemCount: filteredUsers.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 6.w,
                        mainAxisSpacing: 6.h,
                        childAspectRatio: 0.62,
                      ),
                      itemBuilder: (_, index) {
                        final user = filteredUsers[index];
                        final String img = (user["img"] ?? "").toString();
                        final bool hasValidImg =
                            img.isNotEmpty &&
                            img.toLowerCase() != "null" &&
                            (img.startsWith("http") || img.startsWith("https"));
                        final bool isOnline = user["isOnline"] == true;
                        final bool isVerified = user["isVerified"] == true;

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
                                  color: Colors.black.withValues(alpha: 0.45),
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
                                            Colors.black.withValues(alpha: 0.2),
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
                                            isOnline ? "Online" : "Offline",
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
                                    bottom: 10.h,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        /// NAME & AGE
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                "${user["name"]}, ${user["age"]}",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
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

                                        /// DISTANCE & LOOKING FOR
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
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
                                                  Icon(
                                                    Icons.location_on,
                                                    color: Colors.purpleAccent,
                                                    size: 9.sp,
                                                  ),
                                                  SizedBox(width: 2.w),
                                                  Text(
                                                    "${user["distance"]}",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9.sp,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
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
                                                border: Border.all(
                                                  color: Colors.cyanAccent
                                                      .withValues(alpha: 0.4),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Text(
                                                "${user["lookingFor"]}",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.cyanAccent,
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
