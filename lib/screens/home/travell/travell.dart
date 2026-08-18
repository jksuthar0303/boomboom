import 'dart:convert';

import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:boomboom/screens/home/travell/filterscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../authentication/userdetails.dart';
import '../../../backend/routesmatch.dart';
import '../../../backend/secure_storage.dart';
import '../../../backend/registerservice.dart';
import '../../../backend/travel_service.dart';
import 'package:xml/xml.dart' as xml;
import '../../../constant/appsize.dart';
import '../../../constant/apptextstyle.dart';
import '../../../constant/colors.dart';
import '../../../widget/app_image_helper.dart';
import '../../../widget/snakbar.dart';
import '../../../controller/travel_filter_controller.dart';
import 'createtravel.dart';

class TravelAlertScreen extends StatefulWidget {
  const TravelAlertScreen({super.key});

  @override
  State<TravelAlertScreen> createState() => _TravelAlertScreenState();
}

class _TravelAlertScreenState extends State<TravelAlertScreen> {
  int selectedTab = 0;

  /// 🔥 HEART STATE — har user card ke liye alag
  final Set<int> _likedIndexes = {};

  /// TABS WITH ICONS
  final tabs = [
    {"label": "Arrivals", "icon": Icons.flight_land_rounded},
    {"label": "My Journeys", "icon": Icons.luggage_rounded},
  ];

  final TravelAlertController controller = Get.put(TravelAlertController());
  final TravelService _travelService = TravelService();

  List<Map<String, dynamic>> _myJourneys = [];
  bool _isLoadingJourneys = false;
  String? _journeyError;

  List<Map<String, dynamic>> _upcomingTrips = [];
  bool _isLoadingUpcoming = false;
  String? _upcomingError;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingTrips();
    _fetchMyJourneys();
  }

  Future<void> _fetchUpcomingTrips() async {
    if (mounted) {
      setState(() {
        _isLoadingUpcoming = true;
        _upcomingError = null;
      });
    }

    try {
      final email = await SecureStorage().getUserEmail() ?? '';
      final country = await _loadMyCountry(email);
      final list = await _travelService.showUpcomingTrips(
        myEmail: email.trim(),
        myCountry: country,
      );
      if (mounted) {
        setState(() {
          _upcomingTrips = list;
          _isLoadingUpcoming = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching upcoming trips: $e");
      if (mounted) {
        setState(() {
          _upcomingError = e.toString().replaceAll("Exception:", "").trim();
          _isLoadingUpcoming = false;
        });
      }
    }
  }

  Future<String> _loadMyCountry(String email) async {
    if (email.trim().isEmpty) return '';

    try {
      final response = await RegisterService().showProfile(email: email.trim());
      final nodes = xml.XmlDocument.parse(response.body)
          .findAllElements('ShowProfileResult');
      if (nodes.isEmpty) return '';

      final decoded = jsonDecode(nodes.first.innerText.trim());
      final data = decoded['Data'];
      if (data is List && data.isNotEmpty && data.first is Map) {
        final profile = Map<String, dynamic>.from(data.first);
        final profileCountry = (profile['Country'] ??
                profile['CountryName'] ??
                profile['country'] ??
                profile['Nationality'] ??
                '')
            .toString()
            .trim();
        if (profileCountry.isNotEmpty) return profileCountry;

        final lat = double.tryParse((profile['Lat'] ?? '').toString());
        final lon = double.tryParse((profile['Lon'] ?? '').toString());
        if (lat != null && lon != null) {
          final geocoder = geo.Geocoding();
          final places = await geocoder.placemarkFromCoordinates(lat, lon);
          if (places.isNotEmpty) {
            return (places.first.country ?? '').trim();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user country for travel API: $e');
    }

    // Last fallback: use the device's current country when profile data has
    // no country field.
    try {
      final position = await Geolocator.getCurrentPosition();
      final geocoder = geo.Geocoding();
      final places = await geocoder.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (places.isNotEmpty) return (places.first.country ?? '').trim();
    } catch (_) {}
    return '';
  }

  Future<void> _fetchMyJourneys() async {
    final email = await SecureStorage().getUserEmail();
    if (email == null || email.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _journeyError = "User not logged in";
          _isLoadingJourneys = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingJourneys = true;
        _journeyError = null;
      });
    }

    try {
      final list = await _travelService.showTravelByEmail(email: email.trim());
      if (mounted) {
        setState(() {
          _myJourneys = list;
          _isLoadingJourneys = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching my journeys: $e");
      if (mounted) {
        setState(() {
          _journeyError = e.toString().replaceAll("Exception:", "").trim();
          _isLoadingJourneys = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteJourney(int id) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF141B2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              "Delete Journey",
              style: AppTextStyles.heading.copyWith(fontSize: 18.sp),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete this journey? This action cannot be undone.",
          style: AppTextStyles.small.copyWith(
            color: Colors.white70,
            fontSize: 13.sp,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.white54, fontSize: 13.sp),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: () => Get.back(result: true),
            child: Text(
              "Delete",
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _executeDeleteJourney(id);
    }
  }

  Future<void> _executeDeleteJourney(int id) async {
    final email = await SecureStorage().getUserEmail();
    if (email == null || email.trim().isEmpty) return;

    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF8E2DE2))),
      barrierDismissible: false,
    );

    try {
      final response = await _travelService.deleteTravel(
        id: id,
        email: email.trim(),
      );
      Get.back(); // close loading dialog

      if (response.statusCode == 200) {
        NeuSnackbar.success("Journey deleted successfully!");
        _fetchMyJourneys();
      } else {
        NeuSnackbar.error(
          "Failed to delete journey: Server error ${response.statusCode}",
        );
      }
    } catch (e) {
      Get.back(); // close loading dialog
      debugPrint("Delete travel error: $e");
      NeuSnackbar.error("Error deleting journey: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.primary,

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSize.w(16)),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              /// 🔥 HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  /// LEFT TEXT
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          "Travel Alert",

                          style: AppTextStyles.heading.copyWith(
                            fontSize: AppSize.sp(23),
                          ),
                        ),

                        SizedBox(height: 4.h),

                        Text(
                          selectedTab == 1
                              ? "CREATE JOURNEY, GET DESTINATION MESSAGES."
                              : "CREATE JOURNEY",

                          style: AppTextStyles.small.copyWith(
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// RIGHT ICONS
                  Row(
                    children: [
                      _iconBox(
                        Icons.add,
                        onTap: () async {
                          final result = await Get.to(
                            () => const CreateJourneyScreen(),
                            transition: Transition.rightToLeft,
                          );
                          if (result == true) {
                            if (mounted) {
                              setState(() => selectedTab = 1);
                              _fetchMyJourneys();
                            }
                          }
                        },
                      ),

                      SizedBox(width: 8.w),

                      Obx(() {
                        final isActive =
                            TravelFilterController.instance.isFilterActive;
                        return _iconBox(
                          Icons.tune,
                          active: isActive,
                          onTap: () async {
                            final res = await Get.bottomSheet(
                              FractionallySizedBox(
                                heightFactor: 0.72,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(28),
                                  ),
                                  child: const TravelFilterScreen(),
                                ),
                              ),
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                            );
                            if (res == true || mounted) {
                              setState(() {});
                            }
                          },
                        );
                      }),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              /// 🔥 TABS WITH ICONS
              Container(
                padding: EdgeInsets.all(4.w),

                decoration: BoxDecoration(
                  color: AppColors.secondary,

                  borderRadius: BorderRadius.circular(30.r),
                ),

                child: Row(
                  children: List.generate(
                    tabs.length,

                    (index) => Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTab = index;
                          });
                          if (index == 1) {
                            _fetchMyJourneys();
                          }
                        },

                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),

                          padding: EdgeInsets.symmetric(vertical: 10.h),

                          decoration: BoxDecoration(
                            color: selectedTab == index
                                ? Colors.white
                                : Colors.transparent,

                            borderRadius: BorderRadius.circular(25.r),
                          ),

                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                /// TAB ICON
                                Icon(
                                  tabs[index]["icon"] as IconData,
                                  size: isTablet ? 16.sp : 14.sp,
                                  color: selectedTab == index
                                      ? Colors.black
                                      : AppColors.textSecondary,
                                ),

                                SizedBox(width: 6.w),

                                /// TAB LABEL
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    tabs[index]["label"] as String,
                                    style: AppTextStyles.body.copyWith(
                                      color: selectedTab == index
                                          ? Colors.black
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isTablet ? 14.sp : 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 25.h),

              Expanded(
                child: selectedTab == 0
                    ? _upcomingArrivalsView(isTablet)
                    : _myJourneysView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 UPCOMING ARRIVALS VIEW (ShowUpcomingTrips)
  Widget _upcomingArrivalsView(bool isTablet) {
    if (_isLoadingUpcoming) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8E2DE2)),
      );
    }

    if (_upcomingError != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 40.sp,
              ),
              SizedBox(height: 12.h),
              Text(
                _upcomingError!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: Colors.white70),
              ),
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: _fetchUpcomingTrips,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A5AE0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_upcomingTrips.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchUpcomingTrips,
        color: const Color(0xFF8E2DE2),
        backgroundColor: AppColors.secondary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            SizedBox(height: 70.h),
            Center(
              child: Container(
                width: 86.w,
                height: 86.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8E2DE2).withValues(alpha: 0.25),
                      const Color(0xFF4A00E0).withValues(alpha: 0.1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8E2DE2).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.flight_takeoff_rounded,
                  size: 40.sp,
                  color: const Color(0xFFB08FFF),
                ),
              ),
            ),
            SizedBox(height: 22.h),
            Center(
              child: Text(
                "No Upcoming Travels Found",
                style: AppTextStyles.heading.copyWith(fontSize: 18.sp),
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 36.w),
              child: Text(
                "There are currently no upcoming travels found.\nPull down to refresh.",
                textAlign: TextAlign.center,
                style: AppTextStyles.small.copyWith(
                  color: Colors.white54,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final filteredTrips =
        TravelFilterController.instance.applyFilterToJourneys(_upcomingTrips);

    return RefreshIndicator(
      onRefresh: _fetchUpcomingTrips,
      color: const Color(0xFF8E2DE2),
      backgroundColor: AppColors.secondary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white24)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flight_land_rounded,
                                color: Colors.white70,
                                size: 14.sp,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                "UPCOMING ARRIVALS",
                                style: AppTextStyles.subHeading.copyWith(
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            "WHO ARRIVING IN YOUR COUNTRY",
                            style: AppTextStyles.small.copyWith(
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
          if (filteredTrips.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.filter_alt_off_rounded,
                        color: Colors.white38,
                        size: 36.sp,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "No journeys match your filter",
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final user = filteredTrips[index];
                return _userCard(user, index);
              }, childCount: filteredTrips.length),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 3 : 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.62,
              ),
            ),
        ],
      ),
    );
  }

  /// 🔥 MY JOURNEYS VIEW
  Widget _myJourneysView() {
    if (_isLoadingJourneys) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8E2DE2)),
      );
    }

    if (_journeyError != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 40.sp,
              ),
              SizedBox(height: 12.h),
              Text(
                _journeyError!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: Colors.white70),
              ),
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: _fetchMyJourneys,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A5AE0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_myJourneys.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchMyJourneys,
        color: const Color(0xFF8E2DE2),
        backgroundColor: AppColors.secondary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            SizedBox(height: 70.h),
            Center(
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8E2DE2).withValues(alpha: 0.2),
                      const Color(0xFF4A00E0).withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.luggage_outlined,
                  size: 38.sp,
                  color: const Color(0xFFB08FFF),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Center(
              child: Text(
                "No Journeys Created Yet",
                style: AppTextStyles.heading.copyWith(fontSize: 18.sp),
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Text(
                "Plan your next travel journey to connect with fellow travelers.",
                textAlign: TextAlign.center,
                style: AppTextStyles.small.copyWith(
                  color: Colors.white54,
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Center(
              child: GestureDetector(
                onTap: () async {
                  final res = await Get.to(
                    () => const CreateJourneyScreen(),
                    transition: Transition.rightToLeft,
                  );
                  if (res == true) {
                    _fetchMyJourneys();
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 22.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                    ),
                    borderRadius: BorderRadius.circular(25.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8E2DE2).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Colors.white),
                      SizedBox(width: 6.w),
                      Text(
                        "Create Your Journey",
                        style: AppTextStyles.button.copyWith(fontSize: 14.sp),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final filteredMyJourneys =
        TravelFilterController.instance.applyFilterToJourneys(_myJourneys);

    if (filteredMyJourneys.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_alt_off_rounded,
                color: Colors.white38,
                size: 36.sp,
              ),
              SizedBox(height: 8.h),
              Text(
                "No journeys match your filter",
                style: AppTextStyles.body.copyWith(
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyJourneys,
      color: const Color(0xFF8E2DE2),
      backgroundColor: AppColors.secondary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(bottom: 24.h, top: 4.h),
        itemCount: filteredMyJourneys.length,
        separatorBuilder: (_, __) => SizedBox(height: 14.h),
        itemBuilder: (context, index) {
          final item = filteredMyJourneys[index];
          return _myJourneyCard(item);
        },
      ),
    );
  }

  /// 🔥 MY JOURNEY CARD
  Widget _myJourneyCard(Map<String, dynamic> item) {
    final fromCity = (item["FromCity"] ?? "").toString().trim();
    final fromCountry = (item["FromCountry"] ?? "").toString().trim();
    final toCity = (item["ToCity"] ?? "").toString().trim();
    final toCountry = (item["ToCountry"] ?? "").toString().trim();
    final fromDate = (item["FromDate"] ?? "").toString().trim();
    final toDate = (item["ToDate"] ?? "").toString().trim();
    final journeyType = (item["JourneyType"] ?? "Trip").toString().trim();
    final travelStyle = (item["TravelStyle"] ?? "").toString().trim();
    final travelCompanion = (item["TravelCompanion"] ?? "").toString().trim();
    final isHide =
        item["ishide"]?.toString().toLowerCase() == "true" ||
        item["ishide"]?.toString() == "1";
    final description = (item["Description"] ?? "").toString().trim();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF141B2D),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP ROW (Tags on left in responsive Wrap, Actions on right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Chips in a responsive Wrap
              Expanded(
                child: Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Journey Type
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8E2DE2), Color(0xFF6A5AE0)],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        journeyType,
                        style: AppTextStyles.small.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),

                    // Travel Style
                    if (travelStyle.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 9.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          travelStyle,
                          style: AppTextStyles.small.copyWith(
                            color: Colors.white70,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),

                    // Companion
                    if (travelCompanion.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 9.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFB14DFF,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          travelCompanion,
                          style: AppTextStyles.small.copyWith(
                            color: const Color(0xFFD4A5FF),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(width: 8.w),

              // Right: Hidden Badge & Delete Button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isHide) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: const Color(0xFFFFB800),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_off_rounded,
                            color: const Color(0xFFFFB800),
                            size: 11.sp,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            "Hidden",
                            style: AppTextStyles.small.copyWith(
                              color: const Color(0xFFFFB800),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                  ],

                  /// 🗑️ DELETE BUTTON
                  GestureDetector(
                    onTap: () {
                      final id = int.tryParse(
                        (item["id"] ?? item["Id"] ?? "").toString(),
                      );
                      if (id != null) {
                        _confirmDeleteJourney(id);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(5.w),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 15.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 14.h),

          /// ROUTE DISPLAY: Departure -> Destination
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1524),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.flight_takeoff_rounded,
                            color: const Color(0xFF8E2DE2),
                            size: 14.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            "FROM",
                            style: AppTextStyles.small.copyWith(
                              fontSize: 10.sp,
                              color: Colors.white38,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        fromCity.isNotEmpty ? fromCity : "Any City",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subHeading.copyWith(
                          fontSize: 15.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        fromCountry,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.small.copyWith(
                          fontSize: 12.sp,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Column(
                    children: [
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: const Color(0xFFB14DFF),
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "TO",
                            style: AppTextStyles.small.copyWith(
                              fontSize: 10.sp,
                              color: Colors.white38,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.flight_land_rounded,
                            color: const Color(0xFFB14DFF),
                            size: 14.sp,
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        toCity.isNotEmpty ? toCity : "Any City",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: AppTextStyles.subHeading.copyWith(
                          fontSize: 15.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        toCountry,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: AppTextStyles.small.copyWith(
                          fontSize: 12.sp,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          /// DATES ROW
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: const Color(0xFF6A5AE0),
                size: 14.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                _formatDisplayDates(fromDate, toDate),
                style: AppTextStyles.small.copyWith(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          /// DESCRIPTION
          if (description.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: Colors.white30,
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      description,
                      style: AppTextStyles.small.copyWith(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🔥 ICON BOX
  Widget _iconBox(IconData icon, {VoidCallback? onTap, bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFFF3D6D).withValues(alpha: 0.25)
              : AppColors.secondary,
          borderRadius: BorderRadius.circular(10.r),
          border: active
              ? Border.all(color: const Color(0xFFFF3D6D), width: 1.2)
              : null,
        ),
        child: Icon(
          icon,
          color: active ? const Color(0xFFFF3D6D) : Colors.white,
          size: 18.sp,
        ),
      ),
    );
  }

  /// 🔥 ROUTE CARD
  // Widget _routeCard() {

  //   return Container(

  //     height: 240.h,
  //     width: double.infinity,

  //     decoration: BoxDecoration(

  //       color: const Color(0xFFDCD4F5),

  //       borderRadius:
  //       BorderRadius.circular(28.r),
  //     ),

  //     child: Stack(
  //       children: [

  //         /// 🔥 MAP IMAGE
  //         Positioned.fill(
  //           child: ClipRRect(

  //             borderRadius:
  //             BorderRadius.circular(28.r),

  //             child: Opacity(

  //               opacity: 0.10,

  //               child: Image.network(
  //                 "https://upload.wikimedia.org/wikipedia/commons/8/80/World_map_-_low_resolution.svg",

  //                 fit: BoxFit.cover,
  //               ),
  //             ),
  //           ),
  //         ),

  //         /// 🔥 CURVE LINE
  //         Positioned.fill(
  //           child: CustomPaint(
  //             painter: RoutePainter(),
  //           ),
  //         ),

  //         /// 🔥 CENTER GLOW DOT
  //         Positioned(
  //           top: 62.h,
  //           left: 165.w,

  //           child: Container(

  //             height: 24.h,
  //             width: 24.w,

  //             decoration: BoxDecoration(

  //               color: Colors.purple,

  //               shape: BoxShape.circle,

  //               border: Border.all(
  //                 color: Colors.white,
  //                 width: 3,
  //               ),

  //               boxShadow: [

  //                 BoxShadow(
  //                   color:
  //                   Colors.purple.withValues(alpha: 0.45),

  //                   blurRadius: 16,
  //                   spreadRadius: 3,
  //                 ),
  //               ],
  //             ),

  //             child: Center(
  //               child: Container(

  //                 height: 8.h,
  //                 width: 8.w,

  //                 decoration: const BoxDecoration(
  //                   color: Colors.white,
  //                   shape: BoxShape.circle,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),

  //         /// 🔥 LEFT USER
  //         Positioned(
  //           left: 20.w,
  //           top: 25.h,

  //           child: Column(
  //             children: [

  //               CircleAvatar(
  //                 radius: 30.r,

  //                 backgroundImage:
  //                 const NetworkImage(
  //                   "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
  //                 ),
  //               ),

  //               SizedBox(height: 8.h),

  //               Text(
  //                 "Alex, 27",

  //                 style:
  //                 AppTextStyles.body.copyWith(
  //                   color: Colors.black,
  //                   fontWeight:
  //                   FontWeight.w600,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),

  //         /// 🔥 RIGHT USER
  //         Positioned(
  //           right: 20.w,
  //           top: 25.h,

  //           child: Column(
  //             children: [

  //               CircleAvatar(
  //                 radius: 30.r,

  //                 backgroundImage:
  //                 const NetworkImage(
  //                   "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
  //                 ),
  //               ),

  //               SizedBox(height: 8.h),

  //               Text(
  //                 "Maya, 25",

  //                 style:
  //                 AppTextStyles.body.copyWith(
  //                   color: Colors.black,
  //                   fontWeight:
  //                   FontWeight.w600,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),

  //         /// 🔥 BOTTOM TEXT
  //         Positioned(
  //           bottom: 36.h,
  //           left: 0,
  //           right: 0,

  //           child: Column(
  //             children: [

  //               Text(
  //                 "From  →  Destination",

  //                 style:
  //                 AppTextStyles.subHeading
  //                     .copyWith(
  //                   color: Colors.black,
  //                   fontSize: 11.sp,
  //                   fontWeight:
  //                   FontWeight.w900,

  //                 ),
  //               ),

  //               SizedBox(height: 4.h),

  //               Text(
  //                 "Journey",

  //                 style:
  //                 AppTextStyles.body.copyWith(
  //                   color: Colors.black54,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  String _getCountryFlag(String country) {
    if (country.isEmpty) return "";
    final c = country.toLowerCase().trim();
    const map = {
      "india": "🇮🇳",
      "pakistan": "🇵🇰",
      "belgium": "🇧🇪",
      "austria": "🇦🇹",
      "afghanistan": "🇦🇫",
      "australia": "🇦🇺",
      "united states": "🇺🇸",
      "usa": "🇺🇸",
      "united kingdom": "🇬🇧",
      "uk": "🇬🇧",
      "canada": "🇨🇦",
      "germany": "🇩🇪",
      "france": "🇫🇷",
      "italy": "🇮🇹",
      "spain": "🇪🇸",
      "thailand": "🇹🇭",
      "albania": "🇦🇱",
      "andorra": "🇦🇩",
      "aland islands": "🇦🇽",
      "china": "🇨🇳",
      "japan": "🇯🇵",
      "brazil": "🇧🇷",
      "russia": "🇷🇺",
      "mexico": "🇲🇽",
      "uae": "🇦🇪",
      "dubai": "🇦🇪",
      "turkey": "🇹🇷",
      "netherlands": "🇳🇱",
      "switzerland": "🇨🇭",
      "sweden": "🇸🇪",
    };
    return map[c] ?? "";
  }

  String _formatLandingBadge(Map<String, dynamic> user) {
    final fromDateStr = (user["FromDate"] ?? user["status"] ?? "").toString().trim();
    if (fromDateStr.isEmpty) return "Upcoming";
    try {
      final date = DateTime.parse(fromDateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tripDate = DateTime(date.year, date.month, date.day);
      final diff = tripDate.difference(today).inDays;
      if (diff == 0) return "Today";
      if (diff > 0) return "$diff days";
      return "${diff.abs()}d landed";
    } catch (_) {
      return fromDateStr;
    }
  }

  String _formatDisplayDates(String? fromDateStr, String? toDateStr) {
    if ((fromDateStr == null || fromDateStr.trim().isEmpty) &&
        (toDateStr == null || toDateStr.trim().isEmpty)) {
      return "Upcoming Trip";
    }
    try {
      DateTime? from;
      DateTime? to;
      if (fromDateStr != null && fromDateStr.trim().isNotEmpty) {
        from = DateTime.parse(fromDateStr.trim());
      }
      if (toDateStr != null && toDateStr.trim().isNotEmpty) {
        to = DateTime.parse(toDateStr.trim());
      }

      if (from != null && to != null) {
        final fDay = DateFormat('d MMM').format(from);
        final tDay = DateFormat('d MMM, yyyy').format(to);
        if (from.year != to.year) {
          final fDayFull = DateFormat('d MMM, yyyy').format(from);
          return "$fDayFull  ➔  $tDay";
        }
        return "$fDay  ➔  $tDay";
      } else if (from != null) {
        return DateFormat('d MMM, yyyy').format(from);
      } else if (to != null) {
        return DateFormat('d MMM, yyyy').format(to);
      }
    } catch (_) {}

    return "${fromDateStr ?? ''} ${toDateStr != null && toDateStr.isNotEmpty ? '➔ $toDateStr' : ''}".trim();
  }

  String _calculateAgeFromDob(dynamic dobVal, dynamic ageVal) {
    if (ageVal != null && ageVal.toString().trim().isNotEmpty && ageVal.toString().trim() != "null") {
      return ageVal.toString().trim();
    }
    if (dobVal == null) return "";
    final String str = dobVal.toString().trim();
    if (str.isEmpty || str == "null") return "";
    try {
      final dob = DateTime.parse(str);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age > 0 ? "$age" : "";
    } catch (_) {
      return "";
    }
  }

  /// 🔥 USER CARD — pixel-perfect matching reference design
  Widget _userCard(Map<String, dynamic> user, int index) {
    final bool isLiked = _likedIndexes.contains(index);

    final String rawName =
        (user["FullName"] ?? user["name"] ?? user["Name"] ?? "").toString().trim();
    final String email = (user["Email"] ?? user["EmailAddress"] ?? user["email"] ?? "").toString().trim();
    final String name = rawName.isNotEmpty
        ? rawName
        : (email.isNotEmpty ? email.split('@').first : "Traveler");

    final String age = _calculateAgeFromDob(user["Dob"], user["Age"] ?? user["age"]);
    final String nameDisplay = age.isNotEmpty ? "$name, $age" : name;

    final String image = (user["ProfileImage"] ??
            user["image"] ??
            user["Media"] ??
            user["profileImage"] ??
            "")
        .toString()
        .trim();

    final String fromCountry = (user["FromCountry"] ?? user["from"] ?? "").toString().trim();
    final String toCountry = (user["ToCountry"] ?? user["to"] ?? "").toString().trim();
    final String fromCity = (user["FromCity"] ?? "").toString().trim();
    final String toCity = (user["ToCity"] ?? "").toString().trim();

    final String fromDisp = fromCountry.isNotEmpty ? fromCountry : fromCity;
    final String toDisp = toCountry.isNotEmpty ? toCountry : toCity;
    final String routeDisplay = (fromDisp.isNotEmpty || toDisp.isNotEmpty)
        ? "$fromDisp ➜ $toDisp"
        : (user["route"] ?? "Upcoming Trip").toString();

    final String tag = (user["JourneyType"] ?? user["tag"] ?? user["TravelStyle"] ?? "Travel").toString().trim();
    final String badgeText = _formatLandingBadge(user);

    String flag = (user["flag"] ?? "").toString().trim();
    if (flag.isEmpty || flag == "✈️") {
      flag = _getCountryFlag(toCountry.isNotEmpty ? toCountry : fromCountry);
    }

    return GestureDetector(
      onTap: () {
        Get.to(
          () => UserDetailScreen(user: user),
          transition: Transition.rightToLeft,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            /// 1. IMAGE BACKGROUND
            Positioned.fill(
              child: AppNetworkImage(
                imageUrl: image,
                borderRadius: BorderRadius.circular(20.r),
                fit: BoxFit.cover,
                fallbackIcon: Icons.person,
                backgroundColor: const Color(0xFF161E31),
              ),
            ),

            /// 2. GRADIENT OVERLAY
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.3, 0.65, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.92),
                    ],
                  ),
                ),
              ),
            ),

            /// 3. STATUS BADGE — TOP LEFT (Green pill with check)
            if (badgeText.isNotEmpty)
              Positioned(
                top: 8.h,
                left: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 11.sp,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        badgeText,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            /// 4. HEART ICON — TOP RIGHT
            Positioned(
              top: 6.h,
              right: 6.w,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isLiked) {
                      _likedIndexes.remove(index);
                    } else {
                      _likedIndexes.add(index);
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  child: Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isLiked ? Colors.redAccent : Colors.white,
                    size: 22.sp,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ),

            /// 5. BOTTOM INFO
            Positioned(
              left: 10.w,
              right: 10.w,
              bottom: 10.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Name + Age + Flag
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          nameDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5.sp,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      if (flag.isNotEmpty) ...[
                        SizedBox(width: 4.w),
                        Text(flag, style: TextStyle(fontSize: 13.sp)),
                      ],
                    ],
                  ),

                  SizedBox(height: 3.h),

                  /// Route (📍 Aland Islands ➜ Albania)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 11.sp,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          routeDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                            fontSize: 9.5.sp,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 6.h),

                  /// Journey Type White Pill Tag (🏷️ Business)
                  if (tag.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sell_outlined,
                            size: 11.sp,
                            color: Colors.black,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            tag,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔥 ROUTE LINE
class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.purple, Colors.pink],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    path.moveTo(70, 85);

    path.cubicTo(
      size.width * 0.28,
      20,

      size.width * 0.60,
      145,

      size.width - 70,
      85,
    );

    canvas.drawPath(path, paint);

    canvas.drawCircle(
      Offset(size.width * 0.50, 85),

      10,

      Paint()..color = Colors.purple,
    );

    canvas.drawCircle(
      Offset(size.width * 0.50, 85),

      5,

      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
