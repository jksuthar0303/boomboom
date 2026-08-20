import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../backend/secure_storage.dart';
import '../../../../backend/tonight_service.dart';
import '../../../../widget/app_image_helper.dart';
import 'createeventscreen.dart';
import 'eventprofile.dart';

class FreeTonightScreen extends StatefulWidget {
  const FreeTonightScreen({super.key});

  @override
  State<FreeTonightScreen> createState() => _FreeTonightScreenState();
}

class _FreeTonightScreenState extends State<FreeTonightScreen> {
  final TonightService _tonightService = TonightService();

  String selectedCategory = "All";
  RangeValues _distanceRange = const RangeValues(0, 50);
  final Set<int> _likedIndexes = {};

  List<Map<String, dynamic>> _tonightList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTonightData();
  }

  // ─────────────────────────────────────────────────────────────
  // 📡 FETCH TONIGHT DATA VIA API
  // ─────────────────────────────────────────────────────────────

  Future<void> _fetchTonightData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = await SecureStorage().getUserEmail() ?? "";

      // Clean category filter (remove leading emojis e.g. "🍽 Dinner" -> "Dinner")
      String planningFilter = selectedCategory;
      if (planningFilter == "All") {
        planningFilter = "";
      } else {
        planningFilter = planningFilter
            .replaceAll(RegExp(r'^[^\w]+'), '')
            .trim();
      }

      final result = await _tonightService.showTonight(
        email: email.trim(),
        radius: _distanceRange.end,
        planning: planningFilter,
      );

      if (mounted) {
        setState(() {
          _tonightList = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _calculateAgeFromDob(dynamic dobVal, dynamic ageVal) {
    if (ageVal != null &&
        ageVal.toString().trim().isNotEmpty &&
        ageVal.toString().trim() != "null") {
      return ageVal.toString().trim();
    }
    if (dobVal == null) return "";
    final String str = dobVal.toString().trim();
    if (str.isEmpty || str == "null") return "";
    try {
      final dob = DateTime.parse(str);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age > 0 ? "$age" : "";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    bool isTablet = size.width > 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 28.w : 16.w,
        vertical: 12.h,
      ),
      child: Column(
        children: [
          /// 1. CATEGORY CHIPS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                categoryChip(
                  title: "All",
                  selected: selectedCategory == "All",
                  onTap: () {
                    if (selectedCategory != "All") {
                      setState(() => selectedCategory = "All");
                      _fetchTonightData();
                    }
                  },
                ),
                categoryChip(
                  title: "🍽 Dinner",
                  selected: selectedCategory == "🍽 Dinner",
                  onTap: () {
                    if (selectedCategory != "🍽 Dinner") {
                      setState(() => selectedCategory = "🍽 Dinner");
                      _fetchTonightData();
                    }
                  },
                ),
                categoryChip(
                  title: "🎉 Party",
                  selected: selectedCategory == "🎉 Party",
                  onTap: () {
                    if (selectedCategory != "🎉 Party") {
                      setState(() => selectedCategory = "🎉 Party");
                      _fetchTonightData();
                    }
                  },
                ),
                categoryChip(
                  title: "Drinks Tonight",
                  selected: selectedCategory == "Drinks Tonight",
                  onTap: () {
                    if (selectedCategory != "Drinks Tonight") {
                      setState(() => selectedCategory = "Drinks Tonight");
                      _fetchTonightData();
                    }
                  },
                ),
                categoryChip(
                  title: "Party Buddy",
                  selected: selectedCategory == "Party Buddy",
                  onTap: () {
                    if (selectedCategory != "Party Buddy") {
                      setState(() => selectedCategory = "Party Buddy");
                      _fetchTonightData();
                    }
                  },
                ),
                categoryChip(
                  title: "Spontaneous Plans",
                  selected: selectedCategory == "Spontaneous Plans",
                  onTap: () {
                    if (selectedCategory != "Spontaneous Plans") {
                      setState(() => selectedCategory = "Spontaneous Plans");
                      _fetchTonightData();
                    }
                  },
                ),
                categoryChip(
                  title: "Nightout",
                  selected: selectedCategory == "Nightout",
                  onTap: () {
                    if (selectedCategory != "Nightout") {
                      setState(() => selectedCategory = "Nightout");
                      _fetchTonightData();
                    }
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 14.h),

          /// 2. DISTANCE RANGE SLIDER
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFF11182B),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.pink,
                          size: 16.sp,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          "Distance",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${_distanceRange.start.toStringAsFixed(0)} km – ${_distanceRange.end.toStringAsFixed(0)} km",
                      style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.pinkAccent,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: Colors.pinkAccent,
                    overlayColor: Colors.pinkAccent.withValues(alpha: 0.2),
                    rangeThumbShape: const RoundRangeSliderThumbShape(
                      enabledThumbRadius: 11,
                    ),
                    showValueIndicator: ShowValueIndicator.onDrag,
                    valueIndicatorColor: Colors.pinkAccent,
                    valueIndicatorTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                    ),
                  ),
                  child: RangeSlider(
                    values: _distanceRange,
                    min: 0,
                    max: 150,
                    labels: RangeLabels(
                      "${_distanceRange.start.toStringAsFixed(0)} km",
                      "${_distanceRange.end.toStringAsFixed(0)} km",
                    ),
                    onChanged: (v) => setState(() => _distanceRange = v),
                    onChangeEnd: (_) => _fetchTonightData(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "0 km",
                      style: TextStyle(color: Colors.white38, fontSize: 11.sp),
                    ),
                    Text(
                      "150 km",
                      style: TextStyle(color: Colors.white38, fontSize: 11.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 14.h),

          /// 3. BODY (LOADING / ERROR / EMPTY / GRID)
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.pinkAccent,
                      strokeWidth: 2,
                    ),
                  )
                : _errorMessage != null
                ? _buildErrorState()
                : _tonightList.isEmpty
                ? _buildEmptyState(isTablet)
                : RefreshIndicator(
                    color: Colors.pinkAccent,
                    backgroundColor: const Color(0xFF131A2A),
                    onRefresh: _fetchTonightData,
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      scrollCacheExtent: ScrollCacheExtent.pixels(1000),
                      itemCount: _tonightList.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isTablet ? 3 : 2,
                        crossAxisSpacing: 8.w,
                        mainAxisSpacing: 8.h,
                        childAspectRatio: isTablet ? 0.78 : 0.68,
                      ),
                      itemBuilder: (context, index) =>
                          _personCard(_tonightList[index], isTablet, index),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 🔘 CATEGORY CHIP
  // ─────────────────────────────────────────────────────────────

  Widget categoryChip({
    required String title,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 10.w),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFFF3DA1), Color(0xFFFF007A)],
                )
              : null,
          color: selected ? null : const Color(0xFF101726),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 📭 EMPTY STATE
  // ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState(bool isTablet) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90.w,
                height: 90.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF3DA1).withValues(alpha: 0.18),
                      const Color(0xFF6A5AE0).withValues(alpha: 0.18),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFFF3DA1).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.nightlife_rounded,
                  size: 44.sp,
                  color: const Color(0xFFFF3DA1),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "No Tonight Plans Found",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  "No one has added a Free Tonight plan in your area yet.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12.5.sp,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: () async {
                  final res = await Get.to(() => const CreateEventScreen());
                  if (res == true) {
                    _fetchTonightData();
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 22.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF3DA1), Color(0xFFFF007A)],
                    ),
                    borderRadius: BorderRadius.circular(25.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF007A).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 18.sp),
                      SizedBox(width: 6.w),
                      Text(
                        "Create Your Tonight",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ⚠️ ERROR STATE
  // ─────────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.pinkAccent,
              size: 48.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              "Unable to load Tonight plans",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              _errorMessage ?? "Something went wrong",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12.sp),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3DA1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              onPressed: _fetchTonightData,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text("Retry", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 👤 USER CARD
  // ─────────────────────────────────────────────────────────────

  Widget _personCard(Map<String, dynamic> item, bool isTablet, int index) {
    final rawName = (item["FullName"] ?? item["Name"] ?? item["name"] ?? "")
        .toString()
        .trim();
    final email = (item["Email"] ?? item["EmailAddress"] ?? item["email"] ?? "")
        .toString()
        .trim();
    final name = rawName.isNotEmpty
        ? rawName
        : (email.isNotEmpty ? email.split('@').first : "Traveler");

    final age = _calculateAgeFromDob(item["Dob"], item["Age"] ?? item["age"]);
    final nameDisplay = age.isNotEmpty ? "$name, $age" : name;

    (item["TonightImage"] ?? item["tonightImage"] ?? "").toString().trim();
    final profileImg =
        (item["Image"] ??
                item["ProfileImage"] ??
                item["image"] ??
                item["Media"] ??
                "")
            .toString()
            .trim();

    final planning =
        (item["Planning"] ?? item["tag"] ?? item["type"] ?? "Tonight")
            .toString()
            .trim();
    final location =
        (item["Location"] ?? item["FromCity"] ?? item["location"] ?? "Nearby")
            .toString()
            .trim();
    final timeStr = (item["Time"] ?? item["Date"] ?? "Tonight")
        .toString()
        .trim();

    final String rawDistanceKM =
        (item["DistanceKM"] ??
                item["Distance"] ??
                item["distance"] ??
                item["DistanceKm"] ??
                "")
            .toString()
            .trim();
    String distanceText = "Nearby";
    if (rawDistanceKM.isNotEmpty && rawDistanceKM.toLowerCase() != "null") {
      final cleanNum = rawDistanceKM.replaceAll(RegExp(r'[^\d.]'), '');
      final d = double.tryParse(cleanNum);
      if (d != null) {
        if (d < 1.0) {
          distanceText = "1 km away";
        } else {
          distanceText = "${d.toStringAsFixed(1)} km away";
        }
      } else {
        distanceText = rawDistanceKM.contains("away")
            ? rawDistanceKM
            : "$rawDistanceKM km away";
      }
    }

    return GestureDetector(
      onTap: () {
        Get.to(
          () => ProfileDetailsScreen(data: item),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 350),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            /// 📸 IMAGE VIA GLOBAL HELPER
            AppNetworkImage(
              imageUrl: profileImg,
              fit: BoxFit.cover,
              fallbackIcon: Icons.person,
              fallbackIconSize: 48.sp,
              backgroundColor: const Color(0xFF161E31),
            ),

            /// 🎨 GRADIENT OVERLAY
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.35, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.03),
                    Colors.black.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),

            /// SUBTLE BORDER
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),

            /// 🏷️ TOP — PLANNING TAG + HEART
            Positioned(
              top: 8.h,
              left: 9.w,
              right: 9.w,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.r),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2216CA), Color(0xFFD8658F)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Container(
                      margin: EdgeInsets.all(1.2.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            planning,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 9.5.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      if (_likedIndexes.contains(index)) {
                        _likedIndexes.remove(index);
                      } else {
                        _likedIndexes.add(index);
                      }
                    }),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        _likedIndexes.contains(index)
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        key: ValueKey(_likedIndexes.contains(index)),
                        color: _likedIndexes.contains(index)
                            ? Colors.red
                            : Colors.white,
                        size: 26.sp,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// 👤 BOTTOM INFO
            Positioned(
              bottom: 8.h,
              left: 7.w,
              right: 7.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          nameDisplay,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 17.sp : 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Icon(Icons.verified, color: Colors.blue, size: 14.sp),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      profileBadge(location, Icons.location_on),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Flexible(
                            child: profileBadge(distanceText, Icons.near_me),
                          ),
                          SizedBox(width: 3.w),
                          Flexible(
                            child: profileBadge(timeStr, Icons.access_time),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget profileBadge(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.5.w, vertical: 2.5.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 7.5.sp, color: Colors.white70),
          SizedBox(width: 2.w),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 8.5.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
