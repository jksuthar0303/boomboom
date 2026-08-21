import 'dart:convert';
import 'package:boomboom/authentication/boomboom.dart';
import '../../../authentication/messagedetail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:xml/xml.dart' as xml;

import '../../../backend/home_service.dart';
import '../../../backend/secure_storage.dart';
import '../../../constant/appsize.dart';
import '../../../constant/apptextstyle.dart';
import '../../../constant/colors.dart';
import '../../../controller/filter_controller.dart';
import 'newusersscreen.dart';

class FullCardScreen extends StatefulWidget {
  const FullCardScreen({super.key});

  @override
  State<FullCardScreen> createState() => _FullCardScreenState();
}

class _FullCardScreenState extends State<FullCardScreen> {
  final FilterController _filterCtrl = FilterController.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  Position? _currentPosition;
  final Set<String> _likedUserIds = {};
  static final Map<String, String> _staticCountryCache = {};
  final Set<String> _resolvingKeys = {};

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

            final mappedUsers = List<Map<String, dynamic>>.from(last10);
            for (var user in mappedUsers) {
              final c = _getUserCountry(user);
              if (c.isNotEmpty) {
                user["Country"] = c;
                user["country"] = c;
              }
            }

            if (mounted) {
              setState(() {
                _users = mappedUsers;
                _isLoading = false;
              });
              _resolveAllUserCountries(mappedUsers);
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

  void _resolveAllUserCountries(List<Map<String, dynamic>> users) {
    for (var user in users) {
      _getUserCountry(user);
    }
  }

  String _getUserCountry(Map<String, dynamic> user) {
    final String explicitCountry =
        (user["Country"] ?? user["country"] ?? user["CountryName"] ?? "")
            .toString()
            .trim();
    if (explicitCountry.isNotEmpty &&
        explicitCountry.toLowerCase() != "null" &&
        explicitCountry != "0") {
      return explicitCountry;
    }

    final key =
        (user["EmailAddress"] ??
                user["email"] ??
                user["id"] ??
                user["FullName"] ??
                "")
            .toString()
            .trim();
    if (key.isNotEmpty && _staticCountryCache.containsKey(key)) {
      return _staticCountryCache[key]!;
    }

    final lat = double.tryParse(user['Lat']?.toString() ?? '');
    final lon = double.tryParse(user['Lon']?.toString() ?? '');
    if (lat != null && lon != null && (lat != 0 || lon != 0)) {
      if (lat >= 6.0 && lat <= 37.5 && lon >= 68.0 && lon <= 98.0) {
        if (key.isNotEmpty) _staticCountryCache[key] = "India";
        return "India";
      }
      if (lat >= 4.0 && lat <= 14.0 && lon >= 2.5 && lon <= 15.0) {
        if (key.isNotEmpty) _staticCountryCache[key] = "Nigeria";
        return "Nigeria";
      }
      _resolveCountryAsync(key, lat, lon);
      return "";
    }

    final String city = (user["City"] ?? user["city"] ?? user["Location"] ?? "")
        .toString()
        .trim();
    if (city.isNotEmpty && city.toLowerCase() != "null") {
      return city;
    }

    return "";
  }

  Future<void> _resolveCountryAsync(String key, double lat, double lon) async {
    if (key.isEmpty ||
        _resolvingKeys.contains(key) ||
        _staticCountryCache.containsKey(key)) {
      return;
    }
    _resolvingKeys.add(key);
    try {
      final geocoder = geo.Geocoding();
      final placemarks = await geocoder.placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final country = (placemarks.first.country ?? '').trim();
        if (country.isNotEmpty) {
          _staticCountryCache[key] = country;
          if (mounted) {
            setState(() {});
          }
        }
      }
    } catch (e) {
      debugPrint("[FullCardScreen] Geocoding lookup error: $e");
    } finally {
      _resolvingKeys.remove(key);
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

  bool _readBool(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'online';
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

    return Obx(() {
      // Trigger on filter change
      // ignore: unused_local_variable
      final version = _filterCtrl.filterVersion.value;
      final displayUsers = _filterCtrl.applyFilterToUsers(
        _users,
        userPosition: _currentPosition,
      );

      if (displayUsers.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 18.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyanAccent.withValues(alpha: 0.10),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Icon(
                    Icons.people_alt_rounded,
                    color: Colors.cyanAccent,
                    size: 32.sp,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  "No new profiles found",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Please refresh or check back soon.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 12.sp),
                ),
                TextButton.icon(
                  onPressed: _fetchUsers,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: Colors.cyanAccent,
                    size: 17.sp,
                  ),
                  label: Text(
                    "Refresh",
                    style: TextStyle(color: Colors.cyanAccent, fontSize: 12.sp),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: displayUsers.length + 1,
        padding: EdgeInsets.symmetric(horizontal: AppSize.w(10)),
        itemBuilder: (_, index) {
          if (index == displayUsers.length) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NewUsersScreen(),
                  ),
                );
              },
              child: Container(
                width: AppSize.w(280),
                height: AppSize.h(420),
                margin: EdgeInsets.only(right: AppSize.w(12)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.r),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFF8A00),
                      Color(0xFFFF5200),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5200).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "See All",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22.sp,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      "Explore More Profiles",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 22.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 22.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Open",
                            style: TextStyle(
                              color: const Color(0xFFFF5200),
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: const Color(0xFFFF5200),
                            size: 13.sp,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final user = displayUsers[index];

          return GestureDetector(
            onTap: () {
              final userWithCountry = Map<String, dynamic>.from(user);
              final resolvedC = _getUserCountry(user);
              userWithCountry["Country"] = resolvedC;
              userWithCountry["country"] = resolvedC;

              Get.to(
                () => BoomProfileScreen(
                  userEmail:
                      user["EmailAddress"]?.toString() ??
                      user["email"]?.toString(),
                  initialUserData: userWithCountry,
                ),
                transition: Transition.rightToLeft,
              );
            },
            child: _card(user, index),
          );
        },
      );
    });
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
    final String initial = fullName.trim().isNotEmpty
        ? fullName.trim()[0].toUpperCase()
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

  Widget _card(Map<String, dynamic> user, int index) {
    final String fullName = (user["FullName"] ?? "User").toString();
    final int age = _calculateAge(user["Dob"]?.toString());
    final String rawOnlineStatus = (user["OnlineStatus"] ??
            user["onlineStatus"] ??
            user["Status"] ??
            user["status"])
        ?.toString()
        .trim() ?? "";
    final bool isOnlineVal = _readBool(
      user["IsOnline"] ?? user["isOnline"] ?? user["Online"],
    );
    final String displayOnlineStatus = rawOnlineStatus.isNotEmpty && rawOnlineStatus.toLowerCase() != "null"
        ? rawOnlineStatus
        : (isOnlineVal ? "Online" : "Offline");
    final String statusLower = displayOnlineStatus.toLowerCase();
    final bool isOnline = (statusLower == 'online' ||
        statusLower == 'online now' ||
        statusLower == 'active' ||
        statusLower == 'active now') && statusLower != 'hidden' && statusLower != 'offline';
    final bool isVerified = _readBool(user["IsVerified"] ?? user["isVerified"]);
    final String lookingFor = (user["Lookingfor"] ?? "Serious Love").toString();
    final String distance = _calculateDistance(
      user["Lat"]?.toString(),
      user["Lon"]?.toString(),
    );

    final String? mediaStr = user["Media"]?.toString();
    final bool hasValidImage =
        mediaStr != null &&
        mediaStr.isNotEmpty &&
        mediaStr.toLowerCase() != "null" &&
        (mediaStr.startsWith("http") || mediaStr.startsWith("https"));

    final String country = _getUserCountry(user);
    final String flag = countryFlag(country);

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
          BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 10),
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
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
                                color: Colors.blueAccent,
                                size: 18.sp,
                              ),
                            ],
                          ],
                        ),

                        if (country.isNotEmpty) ...[
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
                                Text(flag, style: TextStyle(fontSize: 10.sp)),
                                SizedBox(width: 4.w),
                                Text(
                                  country,
                                  style: AppTextStyles.small.copyWith(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

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
                                displayOnlineStatus,
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
                      final String? actionEmail =
                          (user["EmailAddress"] ?? user["email"])
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
                        color:
                            _likedUserIds.contains(
                              (user["id"] ?? user["EmailAddress"] ?? index)
                                  .toString(),
                            )
                            ? const Color(0xFFFF5E62).withValues(alpha: 0.35)
                            : Colors.black.withValues(alpha: 0.45),
                        border: Border.all(
                          color:
                              _likedUserIds.contains(
                                (user["id"] ?? user["EmailAddress"] ?? index)
                                    .toString(),
                              )
                              ? const Color(0xFFFF5E62)
                              : Colors.white24,
                          width: 1.2,
                        ),
                        boxShadow:
                            _likedUserIds.contains(
                              (user["id"] ?? user["EmailAddress"] ?? index)
                                  .toString(),
                            )
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF5E62,
                                  ).withValues(alpha: 0.45),
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
                        color:
                            _likedUserIds.contains(
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
                                distance.toLowerCase().contains('away')
                                    ? distance
                                    : '$distance away',
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
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final String userEmail =
                            (user["EmailAddress"] ?? user["email"] ?? "")
                                .toString()
                                .trim();
                        final String userImg = hasValidImage
                            ? mediaStr
                            : (user["Media"] ??
                                      user["media"] ??
                                      user["Image"] ??
                                      "")
                                  .toString();
                        final Map<String, String> messageMap = {
                          "name": fullName,
                          "image": userImg,
                          "age": age.toString(),
                          "gender": (user["Gender"] ?? user["gender"] ?? "M")
                              .toString(),
                          "city": (user["City"] ?? user["city"] ?? country)
                              .toString(),
                          "flag": flag,
                          "email": userEmail,
                          "EmailAddress": userEmail,
                          "ActionEmail": userEmail,
                          "OtherUser": userEmail,
                          "SenderImage": userImg,
                          "RecieverImage": userImg,
                          "isOnline": isOnline.toString(),
                          "status": displayOnlineStatus,
                          "OnlineStatus": displayOnlineStatus,
                          "chatListId":
                              (user["ChatListId"] ?? user["chatListId"] ?? "0")
                                  .toString(),
                        };

                        MessageDetailPage.show(
                          context,
                          index: index,
                          messageData: messageMap,
                        );
                      },
                      child: Row(
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
