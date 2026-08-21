import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:xml/xml.dart' as xml;
import '../../backend/home_service.dart';
import '../../backend/secure_storage.dart';
import '../../authentication/boomboom.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  int myLikesCount = 0;
  int whoLikedCount = 0;
  int whoViewedCount = 0;
  int myMatchesCount = 0;

  static final Map<String, String> _staticCountryCache = {};
  static final Set<String> _resolvingKeys = {};

  List<int> get counts => [
    myLikesCount,
    whoLikedCount,
    whoViewedCount,
    myMatchesCount,
  ];

  int selectedTab = 0;
  bool _isLoading = true;
  String? _errorMessage;
  String? _emptyMessage;
  List<Map<String, dynamic>> _apiUsers = [];
  Position? _currentPosition;

  final tabs = ["My Likes", "Who Liked", "Who Viewed", "My Matches"];

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadUsersForTab(0);
    _loadAllTabCounts();
  }

  Future<void> _loadLocation() async {
    try {
      _currentPosition = await Geolocator.getLastKnownPosition();
      _currentPosition ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _loadAllTabCounts() async {
    try {
      final email = await SecureStorage().getUserEmail() ?? '';
      final results = await Future.wait(
        List.generate(4, (index) async {
          final response = index == 1
              ? await HomeService().favoriteLikeViewShowByActionEmail(
                  actionEmail: email.trim(),
                  action: 'like',
                )
              : await HomeService().favoriteLikeViewShowByMyEmail(
                  myEmail: email.trim(),
                  action: _actionForTab(index),
                );
          if (response.statusCode < 200 || response.statusCode >= 300) {
            return 0;
          }
          final result = XmlResponseParser.parse(response.body);
          final data = result['Data'] is List ? result['Data'] as List : [];
          return data.whereType<Map>().length;
        }),
      );
      if (!mounted) return;
      setState(() {
        myLikesCount = results[0];
        whoLikedCount = results[1];
        whoViewedCount = results[2];
        myMatchesCount = results[3];
      });
    } catch (_) {}
  }

  String _actionForTab(int index) {
    switch (index) {
      case 1:
        return 'like';
      case 2:
        return 'view';
      case 3:
        return 'match';
      default:
        return 'like';
    }
  }

  Future<void> _loadUsersForTab(int tabIndex) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _emptyMessage = null;
      });
    }
    try {
      final email = await SecureStorage().getUserEmail() ?? '';
      final response = tabIndex == 1
          ? await HomeService().favoriteLikeViewShowByActionEmail(
              actionEmail: email.trim(),
              action: 'like',
            )
          : await HomeService().favoriteLikeViewShowByMyEmail(
              myEmail: email.trim(),
              action: _actionForTab(tabIndex),
            );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final Map<String, dynamic> result = XmlResponseParser.parse(
        response.body,
      );
      if (result['Status'].toString() != '1') {
        if (!mounted) return;
        setState(() {
          _apiUsers = [];
          _isLoading = false;
          _emptyMessage = 'No data found';
        });
        return;
      }
      final data = result['Data'] is List
          ? (result['Data'] as List)
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _apiUsers = data;
        _emptyMessage = data.isEmpty ? 'No data found' : null;
        if (tabIndex == 0) myLikesCount = data.length;
        if (tabIndex == 1) whoLikedCount = data.length;
        if (tabIndex == 2) whoViewedCount = data.length;
        if (tabIndex == 3) myMatchesCount = data.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiUsers = [];
        _isLoading = false;
        _emptyMessage = null;
        _errorMessage = 'Data load nahi ho saka. Retry karein.';
      });
    }
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
      debugPrint("[LikesScreen] Geocoding lookup error: $e");
    } finally {
      _resolvingKeys.remove(key);
    }
  }

  String _resolveCountryName(Map<String, dynamic> rawMap) {
    // 1. Direct explicit field check
    final String c =
        (rawMap["Country"] ??
                rawMap["country"] ??
                rawMap["CountryName"] ??
                rawMap["countryName"] ??
                rawMap["Country_Name"] ??
                "")
            .toString()
            .trim();

    if (c.isNotEmpty &&
        c.toLowerCase() != "null" &&
        c.toLowerCase() != "not specified" &&
        c != "0") {
      return c;
    }

    final key =
        (rawMap["EmailAddress"] ??
                rawMap["email"] ??
                rawMap["id"] ??
                rawMap["FullName"] ??
                "")
            .toString()
            .trim();
    if (key.isNotEmpty && _staticCountryCache.containsKey(key)) {
      return _staticCountryCache[key]!;
    }

    // 2. Coordinate check with bounding boxes + live Geocoder
    final double? lat = double.tryParse(
      rawMap["Lat"]?.toString() ?? rawMap["lat"]?.toString() ?? "",
    );
    final double? lon = double.tryParse(
      rawMap["Lon"]?.toString() ?? rawMap["lon"]?.toString() ?? "",
    );
    if (lat != null && lon != null && (lat != 0 || lon != 0)) {
      // USA / North America (Lon: -170 to -50, Lat: 24 to 71.5)
      if (lat >= 24.0 && lat <= 71.5 && lon >= -170.0 && lon <= -50.0) {
        if (key.isNotEmpty) _staticCountryCache[key] = "USA";
        return "USA";
      }
      // India (Lon: 68 to 98, Lat: 6 to 37.5)
      if (lat >= 6.0 && lat <= 37.5 && lon >= 68.0 && lon <= 98.0) {
        if (key.isNotEmpty) _staticCountryCache[key] = "India";
        return "India";
      }
      // Thailand (Lon: 97.3 to 105.7, Lat: 5.6 to 20.5)
      if (lat >= 5.6 && lat <= 20.5 && lon >= 97.3 && lon <= 105.7) {
        if (key.isNotEmpty) _staticCountryCache[key] = "Thailand";
        return "Thailand";
      }
      // UK
      if (lat >= 49.8 && lat <= 60.9 && lon >= -8.6 && lon <= 1.8) {
        if (key.isNotEmpty) _staticCountryCache[key] = "United Kingdom";
        return "United Kingdom";
      }
      // Canada
      if (lat >= 41.6 && lat <= 83.0 && lon >= -141.0 && lon <= -52.6) {
        if (key.isNotEmpty) _staticCountryCache[key] = "Canada";
        return "Canada";
      }
      // Australia
      if (lat >= -44.0 && lat <= -10.0 && lon >= 113.0 && lon <= 154.0) {
        if (key.isNotEmpty) _staticCountryCache[key] = "Australia";
        return "Australia";
      }

      // Live async geocode lookup
      _resolveCountryAsync(key, lat, lon);
    }

    // 3. City / State
    final String city =
        (rawMap["City"] ??
                rawMap["city"] ??
                rawMap["District"] ??
                rawMap["district"] ??
                rawMap["State"] ??
                rawMap["state"] ??
                "")
            .toString()
            .trim();
    if (city.isNotEmpty &&
        city.toLowerCase() != "null" &&
        city.toLowerCase() != "not specified") {
      return city;
    }

    return "India";
  }

  static const Map<String, String> _countryNameToCode = {
    // Americas
    "united states": "US", "usa": "US", "america": "US", "canada": "CA",
    "mexico": "MX", "brazil": "BR", "argentina": "AR", "colombia": "CO",
    "chile": "CL", "peru": "PE", "venezuela": "VE", "cuba": "CU",
    // Europe
    "united kingdom": "GB", "uk": "GB", "england": "GB", "great britain": "GB",
    "germany": "DE", "france": "FR", "italy": "IT", "spain": "ES",
    "portugal": "PT", "netherlands": "NL", "holland": "NL", "belgium": "BE",
    "switzerland": "CH", "sweden": "SE", "norway": "NO", "denmark": "DK",
    "finland": "FI", "poland": "PL", "russia": "RU", "ukraine": "UA",
    "austria": "AT", "greece": "GR", "ireland": "IE", "turkey": "TR",
    "czech republic": "CZ", "czechia": "CZ", "hungary": "HU", "romania": "RO",
    // Asia
    "india": "IN", "thailand": "TH", "china": "CN", "japan": "JP",
    "south korea": "KR", "korea": "KR", "indonesia": "ID", "philippines": "PH",
    "vietnam": "VN", "malaysia": "MY", "singapore": "SG", "pakistan": "PK",
    "bangladesh": "BD", "nepal": "NP", "sri lanka": "LK", "taiwan": "TW",
    "hong kong": "HK", "myanmar": "MM", "cambodia": "KH", "laos": "LA",
    "kazakhstan": "KZ", "uzbekistan": "UZ",
    // Middle East
    "united arab emirates": "AE",
    "uae": "AE",
    "dubai": "AE",
    "saudi arabia": "SA",
    "qatar": "QA", "kuwait": "KW", "oman": "OM", "bahrain": "BH",
    "israel": "IL", "iran": "IR", "iraq": "IQ", "jordan": "JO", "lebanon": "LB",
    // Africa
    "nigeria": "NG", "south africa": "ZA", "kenya": "KE", "ghana": "GH",
    "egypt": "EG",
    "ethiopia": "ET",
    "morocco": "MA",
    "tanzania": "TZ",
    "uganda": "UG",
    // Oceania
    "australia": "AU", "new zealand": "NZ", "fiji": "FJ",
  };

  String countryFlag(String? countryName) {
    if (countryName == null || countryName.trim().isEmpty) return "🇮🇳";
    final clean = countryName.trim();
    if (clean.length == 2 && RegExp(r'^[A-Za-z]{2}$').hasMatch(clean)) {
      return clean
          .toUpperCase()
          .runes
          .map((r) => String.fromCharCode(127397 + r))
          .join();
    }
    final lower = clean.toLowerCase();
    for (final entry in _countryNameToCode.entries) {
      if (lower.contains(entry.key)) {
        return entry.value
            .toUpperCase()
            .runes
            .map((r) => String.fromCharCode(127397 + r))
            .join();
      }
    }
    return "🌍";
  }

  String _formatDistance(dynamic latVal, dynamic lonVal, dynamic fallbackDist) {
    if (_currentPosition != null && latVal != null && lonVal != null) {
      try {
        final double? userLat = double.tryParse(latVal.toString());
        final double? userLon = double.tryParse(lonVal.toString());
        if (userLat != null &&
            userLon != null &&
            userLat != 0 &&
            userLon != 0) {
          final double distanceInMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            userLat,
            userLon,
          );
          final double distanceInKm = distanceInMeters / 1000;
          if (distanceInKm < 1) {
            return "Less than 1km away";
          } else {
            return "${distanceInKm.toStringAsFixed(distanceInKm >= 10 ? 0 : 1)}km away";
          }
        }
      } catch (_) {}
    }
    if (fallbackDist != null && fallbackDist.toString().trim().isNotEmpty) {
      final str = fallbackDist.toString().trim();
      if (str.toLowerCase().contains("away")) return str;
      if (str.toLowerCase().contains("km")) return "$str away";
      return "$str km away";
    }
    return "Nearby";
  }

  int _calculateAge(String? dob) {
    if (dob == null || dob.trim().isEmpty) return 24;
    try {
      final parsed = DateTime.tryParse(dob.trim());
      if (parsed != null) {
        final now = DateTime.now();
        int age = now.year - parsed.year;
        if (now.month < parsed.month ||
            (now.month == parsed.month && now.day < parsed.day)) {
          age--;
        }
        return age > 0 ? age : 24;
      }
    } catch (_) {}
    return 24;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 2.h),

            // ── TOP TABS ──
            SizedBox(
              height: 42.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                itemCount: tabs.length,
                itemBuilder: (_, index) {
                  final tabIcons = [
                    Icons.favorite_rounded,
                    Icons.people_alt_rounded,
                    Icons.remove_red_eye_rounded,
                    Icons.compare_arrows_rounded,
                  ];

                  final isSelected = selectedTab == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedTab = index);
                      _loadUsersForTab(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: 8.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF281014)
                            : const Color(0xFF161618),
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF3B5C)
                              : Colors.white.withValues(alpha: 0.08),
                          width: isSelected ? 1.4 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF3B5C,
                                  ).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon with Badge
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                tabIcons[index],
                                color: isSelected
                                    ? const Color(0xFFFF3B5C)
                                    : Colors.white70,
                                size: 18.sp,
                              ),
                              if (counts[index] > 0)
                                Positioned(
                                  top: -6,
                                  right: -8,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4.w,
                                      vertical: 1.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF3B5C),
                                      borderRadius: BorderRadius.circular(10.r),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      counts[index] > 99
                                          ? '99+'
                                          : counts[index].toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 7.5.sp,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          SizedBox(width: 8.w),

                          // Label
                          Text(
                            tabs[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white60,
                              fontSize: 12.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 6.h),

            // ── 2-COLUMN GRID ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF3B5C),
                        strokeWidth: 2.5,
                      ),
                    )
                  : _errorMessage != null
                  ? _buildMessage(_errorMessage!, true)
                  : _apiUsers.isEmpty
                  ? _buildMessage(_emptyMessage ?? 'No data found', false)
                  : GridView.builder(
                      itemCount: _apiUsers.length,
                      padding: EdgeInsets.only(
                        left: 5.w,
                        right: 5.w,
                        bottom: 100.h,
                      ),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 5.h,
                        crossAxisSpacing: 5.w,
                        childAspectRatio: 0.58,
                      ),
                      itemBuilder: (_, i) => _card(i),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(int index) {
    final apiUser = _apiUsers[index];
    final rawMap = (apiUser["raw"] is Map)
        ? Map<String, dynamic>.from(apiUser["raw"])
        : Map<String, dynamic>.from(apiUser);

    final String name =
        (rawMap["FullName"] ?? rawMap["name"] ?? rawMap["Name"] ?? "User")
            .toString();
    final String dob = (rawMap["Dob"] ?? rawMap["dob"] ?? "").toString();
    final int age = _calculateAge(dob);
    final bool isVerified =
        rawMap["IsVerified"]?.toString().toLowerCase() == "true";

    final String country = _resolveCountryName(rawMap);
    final String distance = _formatDistance(
      rawMap["Lat"] ?? rawMap["lat"],
      rawMap["Lon"] ?? rawMap["lon"],
      rawMap["distance"] ?? rawMap["Distance"],
    );

    final String rawOnlineStatus =
        (rawMap["OnlineStatus"] ??
                rawMap["onlineStatus"] ??
                rawMap["Status"] ??
                "")
            .toString()
            .trim();
    final String isOnlineVal = (rawMap["IsOnline"] ?? rawMap["isOnline"] ?? "")
        .toString()
        .toLowerCase()
        .trim();
    final bool isOnline =
        (rawOnlineStatus.toLowerCase() == "online" ||
            rawOnlineStatus.toLowerCase() == "active" ||
            rawOnlineStatus.toLowerCase() == "active now" ||
            isOnlineVal == "true" ||
            isOnlineVal == "1") &&
        rawOnlineStatus.toLowerCase() != "offline" &&
        rawOnlineStatus.toLowerCase() != "hidden";
    final String displayStatus = isOnline ? "Active now" : "Offline";

    final String lookingFor =
        (rawMap["Lookingfor"] ??
                rawMap["lookingFor"] ??
                rawMap["lookingfor"] ??
                "Friendship")
            .toString();

    final String img =
        (rawMap["ProfileImage"] ??
                rawMap["Image"] ??
                rawMap["Media"] ??
                rawMap["Photos"] ??
                rawMap["Photo"] ??
                rawMap["img"] ??
                "")
            .toString();
    final bool hasValidImg =
        img.isNotEmpty &&
        img.toLowerCase() != "null" &&
        (img.startsWith("http") || img.startsWith("https"));

    final bool isLiked =
        selectedTab == 0 ||
        rawMap["liked"] == true ||
        rawMap["Action"]?.toString().toLowerCase() == "like" ||
        rawMap["action"]?.toString().toLowerCase() == "like";

    return GestureDetector(
      onTap: () {
        final email =
            rawMap["EmailAddress"]?.toString() ??
            rawMap["email"]?.toString() ??
            rawMap["ActionEmail"]?.toString();
        Get.to(
          () => BoomProfileScreen(
            userEmail: email,
            initialUserData: rawMap,
            isLiked: isLiked,
          ),
          transition: Transition.rightToLeft,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: const Color(0xFF141416),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.07),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            children: [
              // ── PHOTO ──
              Positioned.fill(
                child: hasValidImg
                    ? Image.network(
                        img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarFallback(name),
                      )
                    : _avatarFallback(name),
              ),

              // ── DARK GRADIENT OVERLAY ──
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.20),
                        Colors.black.withValues(alpha: 0.95),
                      ],
                      stops: const [0.35, 0.65, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // ── TOP RIGHT HEART BUTTON (Hidden in Who Liked & Who Viewed) ──
              if (selectedTab != 1 && selectedTab != 2)
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: GestureDetector(
                    onTap: () => _toggleLike(index),
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.40),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isLiked ? const Color(0xFFFF3B5C) : Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),

              // ── BOTTOM OVERLAY DETAILS ──
              Positioned(
                bottom: 8.h,
                left: 8.w,
                right: 8.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name & Age + Verified Checkmark
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            "$name, $age",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5.sp,
                            ),
                          ),
                        ),
                        if (isVerified) ...[
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.verified_rounded,
                            color: const Color(0xFF2563EB),
                            size: 14.sp,
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: 3.h),

                    // Country / City Pill
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            countryFlag(country),
                            style: TextStyle(fontSize: 9.sp),
                          ),
                          SizedBox(width: 3.w),
                          Flexible(
                            child: Text(
                              country,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Distance Pill
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12.r),
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
                          Flexible(
                            child: Text(
                              distance,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Bottom Row: Status + Relationship Goal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Status (Active now / Offline)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(12.r),
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
                                  boxShadow: isOnline
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF00E676,
                                            ).withValues(alpha: 0.8),
                                            blurRadius: 4,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                displayStatus,
                                style: TextStyle(
                                  color: isOnline
                                      ? const Color(0xFF00E676)
                                      : Colors.white60,
                                  fontSize: 8.5.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 4.w),

                        // Relationship Goal Chip (Purple border)
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: const Color(0xFF6C63FF),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  color: Colors.white70,
                                  size: 9.sp,
                                ),
                                SizedBox(width: 3.w),
                                Flexible(
                                  child: Text(
                                    lookingFor,
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
  }

  Widget _avatarFallback(String name) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "U";
    return Container(
      color: const Color(0xFF1A1A24),
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

  Future<void> _toggleLike(int index) async {
    if (index < 0 || index >= _apiUsers.length) return;
    final target = _apiUsers[index];
    final actionEmail =
        (target['ActionEmail'] ?? target['EmailAddress'] ?? target['email'])
            ?.toString()
            .trim();
    if (actionEmail == null || actionEmail.isEmpty) return;

    final email = await SecureStorage().getUserEmail() ?? '';
    final bool currentLiked = target['liked'] == true || selectedTab == 0;
    final bool nextLiked = !currentLiked;

    setState(() {
      target['liked'] = nextLiked;
      if (selectedTab == 0 && !nextLiked) {
        _apiUsers.removeAt(index);
        myLikesCount = _apiUsers.length;
      }
    });

    try {
      final response = await HomeService().favoriteLikeViewInsert(
        myEmail: email.trim(),
        actionEmail: actionEmail,
        action: nextLiked ? 'like' : 'unlike',
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          target['liked'] = currentLiked;
        });
      }
    }
  }

  Widget _buildMessage(String message, bool retry) {
    final emptyTitles = [
      "No liked profiles yet",
      "No one has liked you yet",
      "No recent views yet",
      "No matches yet",
    ];
    final emptySubtitles = [
      "Profiles you like will appear here.",
      "Your new likes will appear here.",
      "Profiles you view will appear here.",
      "Your mutual matches will appear here.",
    ];
    final emptyIcons = [
      Icons.favorite_rounded,
      Icons.people_alt_rounded,
      Icons.visibility_rounded,
      Icons.compare_arrows_rounded,
    ];
    final int tabIndex = selectedTab.clamp(0, 3).toInt();

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78.w,
              height: 78.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (retry ? Colors.orangeAccent : const Color(0xFFFF3B5C))
                    .withValues(alpha: 0.10),
                border: Border.all(
                  color: (retry ? Colors.orangeAccent : const Color(0xFFFF3B5C))
                      .withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Icon(
                retry ? Icons.cloud_off_rounded : emptyIcons[tabIndex],
                color: retry ? Colors.orangeAccent : const Color(0xFFFF3B5C),
                size: 40.sp,
              ),
            ),
            SizedBox(height: 15.h),
            Text(
              retry ? "Unable to load data" : emptyTitles[tabIndex],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              retry ? message : emptySubtitles[tabIndex],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13.sp,
                height: 1.4,
              ),
            ),
            if (retry) ...[
              SizedBox(height: 16.h),
              TextButton.icon(
                onPressed: () => _loadUsersForTab(selectedTab),
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFFFF3B5C),
                ),
                label: const Text(
                  "Retry",
                  style: TextStyle(
                    color: Color(0xFFFF3B5C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class XmlResponseParser {
  static Map<String, dynamic> parse(String body) {
    try {
      final document = xml.XmlDocument.parse(body);
      final nodes = document.findAllElements(
        'FavoriteLikeView_ShowByMyEmailResult',
      );
      final actionNodes = document.findAllElements(
        'FavoriteLikeView_ShowByActionEmailResult',
      );
      final resultNodes = nodes.isNotEmpty ? nodes : actionNodes;
      if (resultNodes.isEmpty) return const {};
      return Map<String, dynamic>.from(
        jsonDecode(resultNodes.first.innerText) as Map,
      );
    } catch (_) {
      final start = body.indexOf('{');
      final end = body.lastIndexOf('}');
      if (start < 0 || end < start) return const {};
      return Map<String, dynamic>.from(
        jsonDecode(body.substring(start, end + 1)) as Map,
      );
    }
  }
}
