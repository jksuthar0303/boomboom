import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart' as xml;

import '../../../../authentication/boomboom.dart';
import '../../../../backend/home_service.dart';

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  double _searchRadius = 33;
  int _selectedCategory = 0;

  LatLng currentLocation = const LatLng(28.0229, 73.3119);
  List<Marker> markers = [];

  List<Map<String, dynamic>> _nearbyUsers = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<Map<String, dynamic>> categories = [
    {"label": "All", "icon": Icons.grid_view_rounded},
    {"label": "Crosspath", "icon": Icons.compare_arrows_rounded},
    {"label": "Free Tonight", "icon": Icons.nights_stay_rounded},
    {"label": "Nearby", "icon": Icons.near_me_rounded},
  ];

  List<Map<String, dynamic>> get filteredProfiles {
    List<Map<String, dynamic>> list = _nearbyUsers;

    // ── NEARBY TAB (Index 3): Show Only Online Users ──
    if (_selectedCategory == 3) {
      list = list.where((u) {
        final onlineStr =
            (u["IsOnline"] ?? u["isOnline"] ?? "").toString().toLowerCase();
        return onlineStr == "true" || onlineStr == "1";
      }).toList();
      return list;
    }

    if (_selectedCategory == 0) return list;

    final selectedCatName =
        categories[_selectedCategory]["label"].toString().toLowerCase();

    return list.where((u) {
      final userCat =
          (u["Category"] ?? u["category"] ?? "").toString().toLowerCase();
      if (userCat.isEmpty) return true;
      return userCat.contains(selectedCatName) ||
          selectedCatName.contains(userCat);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _sheetController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(currentLocation, 14);
      _fetchNearbyUsers();
    } catch (e) {
      debugPrint("Location error: $e");
      _fetchNearbyUsers();
    }
  }

  Future<void> _fetchNearbyUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await HomeService().showNearbyUsers(
        lat: currentLocation.latitude.toString(),
        lon: currentLocation.longitude.toString(),
        radius: _searchRadius.toInt().toString(),
      );

      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        final res = doc.findAllElements('ShowNearbyUsersResult');
        if (res.isNotEmpty) {
          final Map<String, dynamic> jsonResult = jsonDecode(
            res.first.innerText,
          );
          if (jsonResult["Status"] == 1 && jsonResult["Data"] is List) {
            final List list = jsonResult["Data"];
            if (mounted) {
              setState(() {
                _nearbyUsers =
                    list.map((e) => Map<String, dynamic>.from(e)).toList();
                _isLoading = false;
                _errorMessage = null;
                _updateMarkers();
              });
            }
            return;
          } else {
            if (mounted) {
              setState(() {
                _nearbyUsers = [];
                _isLoading = false;
                _errorMessage = jsonResult["Message"]?.toString() ??
                    "No nearby users found in this radius";
                _updateMarkers();
              });
            }
            return;
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Unable to fetch nearby users. Please try again.";
          _updateMarkers();
        });
      }
    } catch (e) {
      debugPrint("[NearbyMap] Error loading nearby users: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Network connection issue. Please retry.";
          _updateMarkers();
        });
      }
    }
  }

  void _updateMarkers() {
    final List<Marker> newMarkers = [];

    // 1. Current user GPS Marker
    newMarkers.add(
      Marker(
        point: currentLocation,
        width: 80,
        height: 80,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.cyanAccent.withValues(alpha: 0.25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.50),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.cyanAccent,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyanAccent, width: 0.8),
                ),
                child: Text(
                  "You",
                  style: GoogleFonts.poppins(
                    color: Colors.cyanAccent,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 2. Nearby users markers with radial dispersion for overlapping coordinates
    final List<Map<String, dynamic>> currentProfiles = filteredProfiles;
    final int userCount = currentProfiles.length;
    for (int index = 0; index < userCount; index++) {
      final user = currentProfiles[index];
      double? uLat = double.tryParse(user["Lat"]?.toString() ?? "");
      double? uLon = double.tryParse(user["Lon"]?.toString() ?? "");

      if (uLat == null || uLon == null || (uLat == 0.0 && uLon == 0.0)) {
        uLat = currentLocation.latitude;
        uLon = currentLocation.longitude;
      }

      // Check if coordinate overlaps with GPS location or another user
      bool isOverlapping = false;
      if ((uLat - currentLocation.latitude).abs() < 0.0009 &&
          (uLon - currentLocation.longitude).abs() < 0.0009) {
        isOverlapping = true;
      } else {
        for (int j = 0; j < index; j++) {
          final pLat = double.tryParse(currentProfiles[j]["Lat"]?.toString() ?? "");
          final pLon = double.tryParse(currentProfiles[j]["Lon"]?.toString() ?? "");
          if (pLat != null && pLon != null) {
            if ((uLat - pLat).abs() < 0.0009 && (uLon - pLon).abs() < 0.0009) {
              isOverlapping = true;
              break;
            }
          }
        }
      }

      // If overlapping, distribute radially around center point (~350m apart)
      if (isOverlapping) {
        final double angle = (2 * math.pi * index) / (userCount > 1 ? userCount : 4) + 0.6;
        const double radiusOffset = 0.0035;
        uLat = uLat + (radiusOffset * math.cos(angle));
        uLon = uLon + (radiusOffset * math.sin(angle));
      }

      final point = LatLng(uLat, uLon);
      final String name = (user["FullName"] ?? user["name"] ?? "User").toString();
      final String initial =
          name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "U";
      final String? media = user["Media"]?.toString();
      final bool isOnline = user["IsOnline"]?.toString().toLowerCase() == "true";

      Uint8List? imageBytes;
      bool hasHttp = false;

      if (media != null && media.isNotEmpty && media.toLowerCase() != "null") {
        final m = media.trim();
        if (m.startsWith("http://") || m.startsWith("https://")) {
          hasHttp = true;
        } else if (m.length > 50) {
          try {
            final cleanB64 = m.contains(",") ? m.split(",").last.trim() : m;
            imageBytes = base64Decode(cleanB64);
          } catch (_) {}
        }
      }

      newMarkers.add(
        Marker(
          point: point,
          width: 80,
          height: 80,
          child: GestureDetector(
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
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF5E62),
                            width: 2.2,
                          ),
                          gradient: const RadialGradient(
                            colors: [Color(0xFF8E44AD), Color(0xFF14142B)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5E62).withValues(
                                alpha: 0.50,
                              ),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: imageBytes != null
                              ? Image.memory(
                                  imageBytes,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _avatarFallback(name),
                                )
                              : hasHttp
                                  ? Image.network(
                                      media!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          _avatarFallback(name),
                                    )
                                  : Center(
                                      child: Text(
                                        initial,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C28).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      name.split(" ").first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    setState(() {
      markers = newMarkers;
    });
  }

  Future<void> _searchLocation() async {
    final address = _searchController.text.trim();
    if (address.isEmpty) return;

    try {
      final geocoder = geo.Geocoding();
      final List<geo.Location> locations = await geocoder.locationFromAddress(
        address,
      );

      if (locations.isEmpty) return;
      final loc = locations.first;
      final searched = LatLng(loc.latitude, loc.longitude);

      if (!mounted) return;
      setState(() {
        currentLocation = searched;
      });
      _mapController.move(searched, 14);
      _fetchNearbyUsers();
    } catch (e) {
      debugPrint('Location search error: $e');
    }
  }

  String _formatDistance(Map<String, dynamic> user) {
    if (user["Distance"] != null &&
        user["Distance"].toString().trim().isNotEmpty) {
      return user["Distance"].toString();
    }
    final double? uLat = double.tryParse(user["Lat"]?.toString() ?? "");
    final double? uLon = double.tryParse(user["Lon"]?.toString() ?? "");
    if (uLat != null && uLon != null && (uLat != 0.0 || uLon != 0.0)) {
      final distMeters = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        uLat,
        uLon,
      );
      final km = distMeters / 1000.0;
      return "${km.toStringAsFixed(1)} km";
    }
    return "0.1 km";
  }

  Widget _avatarFallback(String name) {
    final String initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(0.0, -0.2),
          radius: 0.85,
          colors: [Color(0xFF8E44AD), Color(0xFF2C3E50), Color(0xFF14142B)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Stack(
          children: [
            // ── INTERACTIVE MAP ──────────────────────────────
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: currentLocation,
                  initialZoom: 14,
                  minZoom: 3,
                  maxZoom: 18,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.yourapp.nearby',
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: currentLocation,
                        radius: _searchRadius * 1000,
                        useRadiusInMeter: true,
                        color: Colors.cyanAccent.withValues(alpha: 0.10),
                        borderColor: Colors.cyanAccent.withValues(alpha: 0.60),
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),

            // ── TOP SEARCH BAR ───────────────────────────────
            Positioned(
              top: 16,
              left: 14,
              right: 14,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF181828).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(30.r),
                        border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        onSubmitted: (_) => _searchLocation(),
                        decoration: InputDecoration(
                          hintText: "Search for places...",
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14.sp,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.cyanAccent,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 14.h,
                            horizontal: 14.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  GestureDetector(
                    onTap: _getCurrentLocation,
                    child: Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF181828).withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.15),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── ZOOM CONTROLS (Floating Right Buttons) ────────
            Positioned(
              right: 16,
              top: 90,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(
                        _mapController.camera.center,
                        (currentZoom + 1).clamp(3.0, 18.0),
                      );
                    },
                    child: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF181828).withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(
                        _mapController.camera.center,
                        (currentZoom - 1).clamp(3.0, 18.0),
                      );
                    },
                    child: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF181828).withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.remove,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── DRAGGABLE BOTTOM SHEET (10% to 90%, Default 50%) ──
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.50,
              minChildSize: 0.10,
              maxChildSize: 0.90,
              snap: true,
              snapSizes: const [0.10, 0.50, 0.90],
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 20,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ListView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      // ── TOP DRAG HANDLE (Tappable & Draggable) ──
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (_sheetController.size < 0.35) {
                            _sheetController.animateTo(
                              0.50,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          } else if (_sheetController.size < 0.70) {
                            _sheetController.animateTo(
                              0.90,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          } else {
                            _sheetController.animateTo(
                              0.50,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          color: Colors.transparent,
                          child: Center(
                            child: Container(
                              width: 48,
                              height: 5,
                              decoration: BoxDecoration(
                                color: const Color(0xFF666666),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── CATEGORY ROW ──────────────────────
                      _CategoryRow(
                        categories: categories,
                        selected: _selectedCategory,
                        sheetSize: _sheetController.isAttached
                            ? _sheetController.size
                            : 0.50,
                        onSelect: (i) {
                          setState(() {
                            _selectedCategory = i;
                            if (i == 1) {
                              _searchRadius = 1;
                            } else if (i == 3) {
                              _searchRadius = 5;
                            }
                            _updateMarkers();
                          });
                          if (i == 1 || i == 3) {
                            _fetchNearbyUsers();
                          }
                        },
                      ),

                      const SizedBox(height: 10),

                      // ── SEARCH RADIUS OR PRESET BADGES (Crosspath / Nearby) ──
                      if (_selectedCategory == 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22222E),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: Colors.cyanAccent.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent.withValues(
                                      alpha: 0.15,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.compare_arrows_rounded,
                                    color: Colors.cyanAccent,
                                    size: 20.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Crosspath Active",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        "Automatically showing people within 1 km",
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: Colors.cyanAccent.withValues(
                                        alpha: 0.4,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    "1 km",
                                    style: TextStyle(
                                      color: Colors.cyanAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_selectedCategory == 3)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22222E),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: const Color(0xFFFF5E62).withValues(
                                  alpha: 0.35,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5E62).withValues(
                                      alpha: 0.15,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.near_me_rounded,
                                    color: const Color(0xFFFF5E62),
                                    size: 20.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Nearby Active",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        "Automatically showing people within 5 km",
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5E62).withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: const Color(0xFFFF5E62).withValues(
                                        alpha: 0.4,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    "5 km",
                                    style: TextStyle(
                                      color: const Color(0xFFFF5E62),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Search Radius",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        "${filteredProfiles.length} people within ${_searchRadius.toInt()} km",
                                        style: TextStyle(
                                          color: Colors.cyanAccent,
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.cyanAccent.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(
                                        color: Colors.cyanAccent.withValues(
                                          alpha: 0.4,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.radar_rounded,
                                          color: Colors.cyanAccent,
                                          size: 14.sp,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          "${_searchRadius.toInt()} km",
                                          style: TextStyle(
                                            color: Colors.cyanAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  activeTrackColor: Colors.cyanAccent,
                                  inactiveTrackColor: Colors.white12,
                                  thumbColor: Colors.white,
                                  overlayColor: Colors.cyanAccent.withValues(
                                    alpha: 0.2,
                                  ),
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 9,
                                  ),
                                ),
                                child: Slider(
                                  value: _searchRadius,
                                  min: 1,
                                  max: 150,
                                  divisions: 149,
                                  label: "${_searchRadius.toInt()} km",
                                  onChanged: (v) {
                                    setState(() => _searchRadius = v);
                                  },
                                  onChangeEnd: (v) {
                                    _fetchNearbyUsers();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 10),

                      // ── CONTENT AREA ──
                      if (_isLoading)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.h),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.cyanAccent,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                "Searching nearby users...",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_errorMessage != null &&
                          filteredProfiles.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 30.h,
                            horizontal: 20.w,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.location_off_rounded,
                                color: Colors.white38,
                                size: 42.sp,
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13.sp,
                                ),
                              ),
                              SizedBox(height: 14.h),
                              ElevatedButton.icon(
                                onPressed: _fetchNearbyUsers,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                ),
                                label: const Text("Retry"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyanAccent,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (filteredProfiles.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.h),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                color: Colors.white38,
                                size: 44.sp,
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                "No users found in this radius",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13.sp,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              TextButton.icon(
                                onPressed: _fetchNearbyUsers,
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.cyanAccent,
                                ),
                                label: const Text(
                                  "Refresh",
                                  style: TextStyle(
                                    color: Colors.cyanAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          itemCount: filteredProfiles.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.70,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 12,
                              ),
                          itemBuilder: (context, index) {
                            final user = filteredProfiles[index];
                            final String name = (user["FullName"] ??
                                    user["name"] ??
                                    "User")
                                .toString();
                            final String? media = user["Media"]?.toString();
                            final isOnline = user["IsOnline"]
                                    ?.toString()
                                    .toLowerCase() ==
                                "true";

                            Uint8List? imageBytes;
                            bool hasHttp = false;

                            if (media != null &&
                                media.isNotEmpty &&
                                media.toLowerCase() != "null") {
                              final m = media.trim();
                              if (m.startsWith("http://") ||
                                  m.startsWith("https://")) {
                                hasHttp = true;
                              } else if (m.length > 50) {
                                try {
                                  final cleanB64 = m.contains(",")
                                      ? m.split(",").last.trim()
                                      : m;
                                  imageBytes = base64Decode(cleanB64);
                                } catch (_) {}
                              }
                            }

                            return GestureDetector(
                              onTap: () {
                                Get.to(
                                  () => BoomProfileScreen(
                                    userEmail: user["EmailAddress"]
                                            ?.toString() ??
                                        user["email"]?.toString(),
                                    initialUserData: user,
                                  ),
                                  transition: Transition.rightToLeft,
                                );
                              },
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.white12,
                                          width: 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            imageBytes != null
                                                ? Image.memory(
                                                    imageBytes,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, _, _) =>
                                                        _avatarFallback(name),
                                                  )
                                                : hasHttp
                                                    ? Image.network(
                                                        media!,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (_, _, _) =>
                                                                _avatarFallback(
                                                                  name,
                                                                ),
                                                      )
                                                    : _avatarFallback(name),
                                            if (isOnline)
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    color: Colors.greenAccent,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors
                                                            .greenAccent
                                                            .withValues(
                                                              alpha: 0.8,
                                                            ),
                                                        blurRadius: 6,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    name.split(" ").first,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 13,
                                      ),
                                      Text(
                                        _formatDistance(user),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 120),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Category Row — Segmented Tabs
// ════════════════════════════════════════════════════════════════
class _CategoryRow extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final int selected;
  final double sheetSize;
  final ValueChanged<int> onSelect;

  const _CategoryRow({
    required this.categories,
    required this.selected,
    required this.sheetSize,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: const Color(0xFF22222E),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: List.generate(categories.length, (i) {
            final isSel = selected == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isSel
                        ? const Color(0xFFFF5E62)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF5E62).withValues(
                                alpha: 0.45,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Icon(
                      categories[i]["icon"],
                      color: isSel ? Colors.white : Colors.white60,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
