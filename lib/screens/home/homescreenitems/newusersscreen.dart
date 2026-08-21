import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:xml/xml.dart' as xml;
import '../../../authentication/boomboom.dart';
import '../../../backend/home_service.dart';
import '../../../backend/secure_storage.dart';

class NewUsersScreen extends StatefulWidget {
  const NewUsersScreen({super.key});

  @override
  State<NewUsersScreen> createState() => _NewUsersScreenState();
}

class _NewUsersScreenState extends State<NewUsersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> allUsers = [];
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchNewUsers();
  }

  Future<void> _fetchNewUsers() async {
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

            // Take the last 10 users from ShowAllExceptMe (newest first)
            final List last10 = rawList.length > 10
                ? rawList.sublist(rawList.length - 10).reversed.toList()
                : rawList.reversed.toList();

            final List<Map<String, dynamic>> mapped = [];
            for (var u in last10) {
              final Map<String, dynamic> rawMap = u is Map
                  ? Map<String, dynamic>.from(u)
                  : {};
              final String name =
                  (rawMap["FullName"] ?? rawMap["name"] ?? "User").toString();
              final String dob = (rawMap["Dob"] ?? rawMap["dob"] ?? "")
                  .toString();
              final int age = _calculateAge(dob);

              // ── Status check (Active now, Offline, Hidden) ──
              final String rawOnlineStatus =
                  (rawMap["OnlineStatus"] ??
                          rawMap["onlineStatus"] ??
                          rawMap["Status"] ??
                          rawMap["status"])
                      ?.toString()
                      .trim()
                      .toLowerCase() ??
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
                  rawMap["IsVerified"]?.toString().toLowerCase() == "true";

              final String lookingFor =
                  (rawMap["Lookingfor"] ??
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

              final String country =
                  (rawMap["Country"] ??
                          rawMap["country"] ??
                          rawMap["CountryName"] ??
                          "India")
                      .toString();

              final Map<String, dynamic> item = Map<String, dynamic>.from(
                rawMap,
              );
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

            if (mounted) {
              setState(() {
                allUsers = mapped;
                _isLoading = false;
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("[NewUsersScreen] Error fetching ShowAllExceptMe: $e");
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
      return "2 km away";
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
        return "${meters.toStringAsFixed(0)} m away";
      } else {
        return "${km.toStringAsFixed(0)} km away";
      }
    } catch (_) {
      return "2 km away";
    }
  }

  Future<void> toggleLike(int index) async {
    final user = allUsers[index];
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
          const SnackBar(content: Text('Like could not be saved.')),
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
          width: 54.w,
          height: 54.w,
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
                fontSize: 22.sp,
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Explore Users",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
                strokeWidth: 2.5,
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchNewUsers,
              color: const Color(0xFF2563EB),
              backgroundColor: const Color(0xFF1C1C1E),
              child: allUsers.isEmpty
                  ? Center(
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
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF2563EB,
                                  ).withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.people_alt_rounded,
                                color: const Color(0xFF2563EB),
                                size: 40.sp,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              "No users found",
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
                              onPressed: _fetchNewUsers,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Color(0xFF2563EB),
                                size: 18,
                              ),
                              label: const Text(
                                "Refresh",
                                style: TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 6.h,
                      ),
                      itemCount: allUsers.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.w,
                        mainAxisSpacing: 8.h,
                        childAspectRatio: 0.60,
                      ),
                      itemBuilder: (_, index) {
                        final user = allUsers[index];
                        final String img = (user["img"] ?? "").toString();
                        final bool hasValidImg =
                            img.isNotEmpty &&
                            img.toLowerCase() != "null" &&
                            (img.startsWith("http://") ||
                                img.startsWith("https://"));
                        final bool isVerified = user["isVerified"] == true;
                        final bool isActiveNow = user["isActiveNow"] == true;
                        final String displayStatus =
                            (user["displayStatus"] ?? "Offline").toString();
                        final String country = (user["country"] ?? "India")
                            .toString();
                        final String lookingFor =
                            (user["lookingFor"] ?? "Friendship").toString();
                        final String distance =
                            (user["distance"] ?? "2 km away").toString();

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
                              borderRadius: BorderRadius.circular(22.r),
                              color: const Color(0xFF151515),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22.r),
                              child: Stack(
                                children: [
                                  /// 🔥 BACKGROUND IMAGE
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

                                  /// 🔥 DARK GRADIENT OVERLAY
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(
                                              alpha: 0.15,
                                            ),
                                            Colors.black.withValues(
                                              alpha: 0.85,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  /// 🔥 NEW PILL BADGE (TOP LEFT)
                                  Positioned(
                                    top: 10.h,
                                    left: 10.w,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 3.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF2563EB),
                                            Color(0xFF1D4ED8),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF2563EB,
                                            ).withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            spreadRadius: 0.5,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        "NEW",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9.sp,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),

                                  /// 🔥 HEART ICON (TOP RIGHT)
                                  Positioned(
                                    top: 10.h,
                                    right: 10.w,
                                    child: GestureDetector(
                                      onTap: () => toggleLike(index),
                                      child: Icon(
                                        user["liked"] == true
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: user["liked"] == true
                                            ? Colors.red
                                            : Colors.white,
                                        size: 24.sp,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black54,
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  /// 🔥 BOTTOM INFO SECTION
                                  Positioned(
                                    left: 8.w,
                                    right: 8.w,
                                    bottom: 8.h,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        /// 1. NAME & AGE + VERIFIED BADGE
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
                                                color: Colors.blueAccent,
                                                size: 12.sp,
                                              ),
                                            ],
                                          ],
                                        ),

                                        SizedBox(height: 3.h),

                                        /// 2. COUNTRY BADGE
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 5.w,
                                            vertical: 1.5.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.40,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              14.r,
                                            ),
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
                                              Flexible(
                                                child: Text(
                                                  country,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9.sp,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        SizedBox(height: 3.h),

                                        /// 3. DISTANCE
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 5.w,
                                            vertical: 1.5.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.40,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              14.r,
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
                                              Flexible(
                                                child: Text(
                                                  distance,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9.sp,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        SizedBox(height: 4.h),

                                        /// 4. STATUS (Active now / Offline) & LOOKING FOR TAG
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            /// Status indicator
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 6.w,
                                                vertical: 3.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.40,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20.r),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 5.5.w,
                                                    height: 5.5.w,
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
                                                                      alpha:
                                                                          0.6,
                                                                    ),
                                                                blurRadius: 4,
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
                                                      fontSize: 8.5.sp,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            /// Relationship tag with solid blue border
                                            Flexible(
                                              child: Container(
                                                margin: EdgeInsets.only(
                                                  left: 4.w,
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 7.w,
                                                  vertical: 3.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        20.r,
                                                      ),
                                                  color: Colors.black
                                                      .withValues(alpha: 0.6),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF2563EB,
                                                    ),
                                                    width: 1.2,
                                                  ),
                                                ),
                                                child: Text(
                                                  lookingFor,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8.5.sp,
                                                    fontWeight: FontWeight.w900,
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
                    ),
            ),
    );
  }
}
