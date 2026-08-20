import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:xml/xml.dart' as xml;
import '../../backend/home_service.dart';
import '../../backend/secure_storage.dart';
import '../../authentication/boomboom.dart';
import '../../constant/apptextstyle.dart';
import '../../constant/colors.dart';

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
  // int whoSortedCount = 18;
  // int mySortedCount = 7;

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

  final tabs = [
    "My Likes",
    "Who Liked",
    "Recently Viewed",
    "My Matches",
    // "Who Favourite Me",
    // "My Favourite",
  ];

  final List<Map<String, dynamic>> users = [
    {
      "image": "https://randomuser.me/api/portraits/women/1.jpg",
      "name": "Jyunko",
      "age": 26,
      "flag": "🇹🇭",
      "city": "Thailand",
      "distance": "50km away",
    },
    {
      "image": "https://randomuser.me/api/portraits/women/2.jpg",
      "name": "Pin107",
      "age": 25,
      "flag": "🇹🇭",
      "city": "Chiang Mai",
      "distance": "2475km away",
    },
    {
      "image": "https://randomuser.me/api/portraits/women/3.jpg",
      "name": "Namkang16TH",
      "age": 57,
      "flag": "🇹🇭",
      "city": "Bangkok",
      "distance": "29km away",
    },
    {
      "image": "https://randomuser.me/api/portraits/women/4.jpg",
      "name": "Ploy15987",
      "age": 22,
      "flag": "🇮🇳",
      "city": "India",
      "distance": "8757km away",
    },
    {
      "image": "https://randomuser.me/api/portraits/women/5.jpg",
      "name": "Sara",
      "age": 28,
      "flag": "🇹🇭",
      "city": "Phuket",
      "distance": "120km away",
    },
    {
      "image": "https://randomuser.me/api/portraits/women/6.jpg",
      "name": "Mila",
      "age": 24,
      "flag": "🇮🇳",
      "city": "Mumbai",
      "distance": "300km away",
    },
    {
      "image": "https://randomuser.me/api/portraits/women/7.jpg",
      "name": "Lena",
      "age": 30,
      "flag": "🇹🇭",
      "city": "Pattaya",
      "distance": "5km away",
    },
    {
      "image": "https://randomuser.me/api/portraits/women/8.jpg",
      "name": "Nong",
      "age": 27,
      "flag": "🇹🇭",
      "city": "Chonburi",
      "distance": "18km away",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUsersForTab(0);
    _loadAllTabCounts();
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
    } catch (_) {
      // The selected tab still loads normally; counts remain at zero on error.
    }
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

      final Map<String, dynamic> result = XmlResponseParser.parse(response.body);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          child: Column(
            children: [
              // ── TABS ──
              SizedBox(
                height: 42.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: tabs.length,
                  itemBuilder: (_, index) {
                    final tabIcons = [
                      Icons.favorite_rounded,
                      Icons.people_alt_rounded,
                      Icons.remove_red_eye_rounded,
                      Icons.compare_arrows_rounded,
                      // Icons.bookmark_rounded,
                      // Icons.sort_rounded,
                    ];

                    final tabColors = [
                      Colors.red,
                      Colors.purple,
                      Colors.blue,
                      Colors.cyan,
                      // Colors.green,
                      // Colors.amber,
                    ];

                    final isSelected = selectedTab == index;
                    final color = tabColors[index];

                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedTab = index);
                        _loadUsersForTab(index);
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 10.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.18)
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isSelected ? color : Colors.white12,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Icon circle with count badge ──
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 32.w,
                                  height: 32.w,
                                  decoration: BoxDecoration(
                                    color: color.withValues(
                                      alpha: isSelected ? 0.25 : 0.12,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    tabIcons[index],
                                    color: isSelected ? color : Colors.white60,
                                    size: 16.sp,
                                  ),
                                ),
                                // Red count badge
                                if (counts[index] > 0)
                                  Positioned(
                                    top: -6,
                                    right: -3,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: counts[index] > 9
                                            ? 4.w
                                            : 5.w,
                                        vertical: 1.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFF111111),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Text(
                                        counts[index] > 99
                                            ? '99+'
                                            : counts[index].toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 7.sp,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            SizedBox(width: 8.w),

                            // ── Label ──
                            Text(
                              tabs[index],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white60,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 12.h),

              // ── GRID ──
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? _buildMessage(_errorMessage!, true)
                    : _apiUsers.isEmpty
                    ? _buildMessage(_emptyMessage ?? 'No data found', false)
                    : GridView.builder(
                        itemCount: _apiUsers.length,
                        padding: EdgeInsets.only(
                          left: 4.w,
                          right: 4.w,
                          bottom: 100.h,
                        ),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 6.h,
                          crossAxisSpacing: 6.w,
                          childAspectRatio: 0.68,
                        ),
                        itemBuilder: (_, i) => _card(i),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
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
                color: (retry ? Colors.orangeAccent : Colors.cyanAccent)
                    .withValues(alpha: 0.10),
                border: Border.all(
                  color: (retry ? Colors.orangeAccent : Colors.cyanAccent)
                      .withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Icon(
                retry ? Icons.cloud_off_rounded : emptyIcons[tabIndex],
                color: retry ? Colors.orangeAccent : Colors.cyanAccent,
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
            SizedBox(height: 7.h),
            Text(
              retry ? message : emptySubtitles[tabIndex],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 14.h),
            TextButton.icon(
              onPressed: () => _loadUsersForTab(selectedTab),
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

  // ── DARK PILL BADGE (image style) ──
  Widget _darkPill({
    required Widget child,
    Color borderColor = const Color(0xFF2A2A2A),
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: Colors.black.withValues(alpha: 0.55),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: child,
    );
  }

  // ── CARD ──
  Widget _card(int index) {
    final apiUser = _apiUsers[index];
    final user = _mapApiUser(apiUser);

    return GestureDetector(
      onTap: () {
        Get.to(
          BoomProfileScreen(
            userEmail:
                apiUser['EmailAddress']?.toString() ??
                apiUser['ActionEmail']?.toString(),
            initialUserData: apiUser,
            isLiked: selectedTab == 0 ||
                apiUser['Action']?.toString().toLowerCase() == 'like' ||
                apiUser['action']?.toString().toLowerCase() == 'like',
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          children: [
            // ── PHOTO ──
            Image.network(
              user["image"],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, _, _) => Container(
                color: Colors.transparent,
                child: const SizedBox.shrink(),
              ),
            ),

            // ── GRADIENT ──
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.88),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // ── X BUTTON (top-left) — BLUE filled circle ──
            // ── X BUTTON (top-left) ──
            Positioned(top: 10.h, left: 10.w, child: const SizedBox.shrink()),
            /*
              child: Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: Colors.black, // Blue ki jagah black
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.4,
                      ), // Shadow bhi black
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(Icons.close, color: Colors.white, size: 16.sp),
              ),
            ),*/

            // ── HEART ICON — same as Explore screen ──
            if (selectedTab == 0)
              Positioned(
                top: 10.h,
                right: 10.w,
                child: GestureDetector(
                  onTap: () => _unlikeUser(index),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Colors.redAccent,
                    size: 26.sp,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                ),
              ),

            // ── BOTTOM INFO ──
            Positioned(
              bottom: 8.h,
              left: 8.w,
              right: 8.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Age + Verified
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          "${user["name"]}, ${user["age"]}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      if (user["isVerified"] == true)
                        Icon(
                          Icons.verified_rounded,
                          color: Colors.blueAccent,
                          size: 14.sp,
                        ),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // ── COUNTRY BADGE ──
                  _darkPill(
                    borderColor: Colors.white12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user["gender"],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (user["occupation"].toString().isNotEmpty) ...[
                          SizedBox(width: 3.w),
                          Text(
                            user["occupation"],
                            style: AppTextStyles.small.copyWith(
                              color: Colors.white70,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // ── DISTANCE BADGE ──
                  SizedBox(height: 3.h),

                  // ── ACTIVE NOW + FRIENDSHIP ROW ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Active now badge
                      _darkPill(
                        borderColor: Colors.white12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.w,
                              height: 6.w,
                              decoration: BoxDecoration(
                                color: user["isOnline"]
                                    ? const Color(0xFF2ECC71)
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              (user["onlineStatus"] ?? (user["isOnline"] ? "Online" : "Offline")).toString(),
                              style: AppTextStyles.small.copyWith(
                                color: user["isOnline"]
                                    ? const Color(0xFF00E676)
                                    : Colors.white70,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Friendship badge
                      // Friendship badge
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.r),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2216CA), Color(0xFFD8658F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(1.2),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(29.r),
                            color: Colors.black.withValues(alpha: 0.7),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF6C63FF,
                                ).withValues(alpha: 0.35),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_outline,
                                color: Colors.white,
                                size: 9.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                user["lookingFor"],
                                style: AppTextStyles.small.copyWith(
                                  color: Colors.white,
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w900,
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
    );
  }

  Map<String, dynamic> _mapApiUser(Map<String, dynamic> item) {
    final dob = item['Dob']?.toString() ?? '';
    String age = '';
    try {
      final date = DateTime.parse(dob);
      final now = DateTime.now();
      var value = now.year - date.year;
      if (now.month < date.month ||
          (now.month == date.month && now.day < date.day)) {
        value--;
      }
      age = value.toString();
    } catch (_) {}
    final image =
        item['ProfileImage'] ??
        item['Image'] ??
        item['Media'] ??
        item['Photo'] ??
        '';
    return {
      'image': image.toString(),
      'name': item['FullName'] ?? item['Name'] ?? 'Unknown',
      'age': age,
      'gender': item['Gender'] ?? 'Not specified',
      'occupation':
          item['Occupation'] == null ||
              item['Occupation'].toString().trim().toLowerCase() ==
                  'not specified'
          ? ''
          : item['Occupation'].toString(),
      'distance': '${item['Lat'] ?? ''}, ${item['Lon'] ?? ''}',
      'onlineStatus': (item['OnlineStatus'] != null && item['OnlineStatus'].toString().trim().isNotEmpty && item['OnlineStatus'].toString().toLowerCase() != 'null')
          ? item['OnlineStatus'].toString().trim()
          : (item['IsOnline'].toString().toLowerCase() == 'true' ? 'Online' : 'Offline'),
      'isOnline': (() {
        final st = (item['OnlineStatus'] != null && item['OnlineStatus'].toString().trim().isNotEmpty && item['OnlineStatus'].toString().toLowerCase() != 'null')
            ? item['OnlineStatus'].toString().trim().toLowerCase()
            : (item['IsOnline'].toString().toLowerCase() == 'true' ? 'online' : 'offline');
        return (st == 'online' || st == 'online now' || st == 'active' || st == 'active now') && st != 'hidden' && st != 'offline';
      })(),
      'isVerified': item['IsVerified'].toString().toLowerCase() == 'true',
      'lookingFor': item['Lookingfor'] ?? 'Not specified',
    };
  }

  Future<void> _unlikeUser(int index) async {
    if (index < 0 || index >= _apiUsers.length) return;
    final target = _apiUsers[index];
    final actionEmail = (target['ActionEmail'] ?? target['EmailAddress'])
        ?.toString()
        .trim();
    if (actionEmail == null || actionEmail.isEmpty) return;

    final email = await SecureStorage().getUserEmail() ?? '';
    final removed = _apiUsers.removeAt(index);
    if (mounted) {
      setState(() {
        if (selectedTab == 0) myLikesCount = _apiUsers.length;
      });
    }
    try {
      final response = await HomeService().favoriteLikeViewInsert(
        myEmail: email.trim(),
        actionEmail: actionEmail,
        action: 'unlike',
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }
      if (mounted && selectedTab == 0) {
        setState(() => myLikesCount = _apiUsers.length);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final restoreIndex = index > _apiUsers.length
            ? _apiUsers.length
            : index;
        _apiUsers.insert(restoreIndex, removed);
        if (selectedTab == 0) myLikesCount = _apiUsers.length;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unlike save nahi ho saka.')),
      );
    }
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
