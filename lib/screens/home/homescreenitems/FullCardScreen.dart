import 'dart:convert';
import 'package:boomboom/authentication/boomboom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:xml/xml.dart' as xml;

import '../../../backend/home_service.dart';
import '../../../backend/secure_storage.dart';
import '../../../constant/appsize.dart';
import '../../../constant/apptextstyle.dart';
import '../../../constant/colors.dart';

class FullCardScreen extends StatefulWidget {
  const FullCardScreen({super.key});

  @override
  State<FullCardScreen> createState() => _FullCardScreenState();
}

class _FullCardScreenState extends State<FullCardScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  Position? _currentPosition;
  final Set<String> _likedUserIds = {};

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      // 1. Get current position for distance calculation best-effort
      try {
        _currentPosition = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      // 2. Get my email
      final String myEmail = await SecureStorage().getUserEmail() ?? "";

      // 3. Call ShowAllExceptMe SOAP API
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

            // Take the last 10 users as requested
            final List last10 = rawList.length > 10
                ? rawList.sublist(rawList.length - 10)
                : rawList;

            if (mounted) {
              setState(() {
                _users = List<Map<String, dynamic>>.from(last10);
                _isLoading = false;
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("[FullCardScreen] Error fetching ShowAllExceptMe: $e");
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }

    if (_users.isEmpty) {
      return Center(
        child: Text(
          "No new users found",
          style: AppTextStyles.body.copyWith(color: AppColors.grey),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _users.length,
      padding: EdgeInsets.symmetric(horizontal: AppSize.w(10)),
      itemBuilder: (_, index) {
        final user = _users[index];

        return GestureDetector(
          onTap: () {
            Get.to(
              () => BoomProfileScreen(
                userEmail: user["EmailAddress"]?.toString() ??
                    user["email"]?.toString(),
                initialUserData: user,
              ),
              transition: Transition.rightToLeft,
            );
          },
          child: _card(user, index),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      padding: EdgeInsets.symmetric(horizontal: AppSize.w(10)),
      itemBuilder: (_, index) {
        return Container(
          width: AppSize.w(280),
          height: AppSize.h(420),
          margin: EdgeInsets.only(right: AppSize.w(12)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.r),
            color: AppColors.cardBg,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF9B59B6),
              strokeWidth: 2.5,
            ),
          ),
        );
      },
    );
  }

  /// 🎨 Card background when user has no media uploaded yet
  Widget _buildNoImageBackground(String fullName) {
    final String initial =
        fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : "U";

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF28133E),
            Color(0xFF1B1B2F),
            Color(0xFF110E1D),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSize.w(90),
              height: AppSize.w(90),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF9B59B6), Color(0xFF3498DB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9B59B6).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: AppSize.sp(36),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSize.h(12)),
            Text(
              "Profile",
              style: AppTextStyles.small.copyWith(
                color: Colors.white38,
                fontSize: AppSize.sp(11),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 USER CARD
  Widget _card(Map<String, dynamic> user, int index) {
    final String fullName = (user["FullName"] ?? "User").toString();
    final int age = _calculateAge(user["Dob"]?.toString());
    final bool isOnline =
        user["IsOnline"]?.toString().toLowerCase() == "true";
    final bool isVerified =
        user["IsVerified"]?.toString().toLowerCase() == "true";
    final String lookingFor =
        (user["Lookingfor"] ?? "Serious Love").toString();
    final String distance = _calculateDistance(
      user["Lat"]?.toString(),
      user["Lon"]?.toString(),
    );

    final String? mediaStr = user["Media"]?.toString();
    final bool hasValidImage = mediaStr != null &&
        mediaStr.isNotEmpty &&
        mediaStr.toLowerCase() != "null" &&
        (mediaStr.startsWith("http") || mediaStr.startsWith("https"));

    return Container(
      width: AppSize.w(280),
      height: AppSize.h(420),
      margin: EdgeInsets.only(right: AppSize.w(12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.r),
        color: AppColors.secondary,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25.r),
        child: Stack(
          children: [
            /// 🔥 BACKGROUND: Image only if present in API, otherwise Clean Aesthetic Gradient + Avatar
            if (hasValidImage)
              Image.network(
                mediaStr,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildNoImageBackground(fullName),
              )
            else
              _buildNoImageBackground(fullName),

            /// 🔥 TOP INFO
            Positioned(
              top: 15.h,
              left: 15.w,
              right: 15.w,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// NAME + AGE + VERIFIED
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "$fullName, $age",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.heading.copyWith(
                                  fontSize: 17.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isVerified) ...[
                              SizedBox(width: 4.w),
                              Icon(
                                Icons.verified_rounded,
                                color: Colors.cyanAccent,
                                size: 18.sp,
                              ),
                            ],
                          ],
                        ),

                        SizedBox(height: 8.h),

                        /// COUNTRY / CITY
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("🇮🇳", style: TextStyle(fontSize: 10.sp)),
                              SizedBox(width: 4.w),
                              Text(
                                "India",
                                style: AppTextStyles.small.copyWith(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 6.h),

                        /// ONLINE STATUS
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7.w,
                                height: 7.w,
                                decoration: BoxDecoration(
                                  color: isOnline
                                      ? const Color(0xFF00E676)
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                isOnline ? "Online now" : "Offline",
                                style: AppTextStyles.small.copyWith(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 10.w),

                  /// ❤️ FAVORITE / LIKE ICON (Toggleable)
                  GestureDetector(
                    onTap: () async {
                      final String userKey =
                          (user["id"] ?? user["EmailAddress"] ?? index)
                              .toString();
                      final String? actionEmail = (user["EmailAddress"] ??
                              user["email"])
                          ?.toString()
                          .trim();
                      final bool nextLiked = !_likedUserIds.contains(userKey);
                      setState(() {
                        if (!nextLiked) {
                          _likedUserIds.remove(userKey);
                        } else {
                          _likedUserIds.add(userKey);
                        }
                      });
                      if (actionEmail == null || actionEmail.isEmpty) return;
                      try {
                        final myEmail =
                            await SecureStorage().getUserEmail() ?? '';
                        final response = await HomeService()
                            .favoriteLikeViewInsert(
                              myEmail: myEmail.trim(),
                              actionEmail: actionEmail,
                              action: nextLiked ? 'like' : 'unlike',
                            );
                        if (response.statusCode < 200 ||
                            response.statusCode >= 300) {
                          throw Exception('HTTP ${response.statusCode}');
                        }
                      } catch (_) {
                        if (mounted) {
                          setState(() {
                            if (nextLiked) {
                              _likedUserIds.remove(userKey);
                            } else {
                              _likedUserIds.add(userKey);
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Like save nahi ho saka.'),
                            ),
                          );
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _likedUserIds.contains(
                                  (user["id"] ?? user["EmailAddress"] ?? index)
                                      .toString(),
                                )
                            ? const Color(0xFFFF5E62).withValues(alpha: 0.35)
                            : Colors.black.withValues(alpha: 0.45),
                        border: Border.all(
                          color: _likedUserIds.contains(
                                    (user["id"] ??
                                            user["EmailAddress"] ??
                                            index)
                                        .toString(),
                                  )
                              ? const Color(0xFFFF5E62)
                              : Colors.white24,
                          width: 1.2,
                        ),
                        boxShadow: _likedUserIds.contains(
                                  (user["id"] ?? user["EmailAddress"] ?? index)
                                      .toString(),
                                )
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFF5E62)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        _likedUserIds.contains(
                                  (user["id"] ?? user["EmailAddress"] ?? index)
                                      .toString(),
                                )
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _likedUserIds.contains(
                                  (user["id"] ?? user["EmailAddress"] ?? index)
                                      .toString(),
                                )
                            ? const Color(0xFFFF5E62)
                            : Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// 🔥 BOTTOM OVERLAY
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(AppSize.w(12)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// DISTANCE + LOOKING FOR
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.purpleAccent,
                                size: 12.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                distance,
                                style: AppTextStyles.small.copyWith(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 8.w),

                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                color: Colors.pinkAccent,
                                size: 11.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                lookingFor,
                                style: AppTextStyles.small.copyWith(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    /// MESSAGE BOX
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 45.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(30.r),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              children: [
                                /// TEXT
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 15.w),
                                    child: Text(
                                      "Send message...",
                                      style: AppTextStyles.body.copyWith(
                                        color: Colors.white70,
                                        fontSize: AppSize.sp(12),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: double.infinity,
                                  width: 42.w,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      "assets/arroriconimage.png",
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
