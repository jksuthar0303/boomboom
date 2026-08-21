import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:boomboom/authentication/messagescreen.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart' as xml;
import 'package:boomboom/screens/home/homescreenitems/verifyiuser.dart';
import 'package:boomboom/screens/home/travell/travell.dart';
import 'package:boomboom/screens/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../backend/home_service.dart';
import '../../backend/permission_service.dart';
import '../../backend/registerservice.dart';
import '../../backend/secure_storage.dart';
import '../../controller/auth_controller.dart';
import '../../authentication/welcomscreens.dart';
import '../../authentication/boomboom.dart';
import '../../constant/appsize.dart';
import '../../constant/apptextstyle.dart';
import '../../constant/colors.dart';
import '../../widget/lotteewidgets.dart';
import '../../widget/topcards.dart';
import '../../widget/videobackground.dart';
import 'homescreenitems/FullCardScreen.dart';
import 'homescreenitems/eventscreens/eventscreens.dart';
import 'homescreenitems/homefilterscreen.dart';
import 'homescreenitems/newmatches.dart';
import 'homescreenitems/newusersscreen.dart';
import 'homescreenitems/notificationscreen.dart';
import '../../controller/filter_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // ignore: library_private_types_in_public_api
  static _HomeScreenState? state;

  static void refreshProfile() {
    state?._checkLoginAndLoadProfile();
  }

  static void refreshHomeData() {
    state?._fetchEveryoneUsers();
    state?._fetchOnlineUsers();
    state?._fetchVerifiedUsers();
    state?._fetchAndUpdateLocation(requestIfNeeded: false);
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final PageController _pageController = PageController();
  late final AuthController authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController(), permanent: true);

  String _profileImageUrl =
      "https://images.unsplash.com/photo-1502685104226-ee32379fefbe";
  String _currentCityName = "Pattaya City";
  Position? _currentPosition;

  int _currentPage = 0;
  Timer? _autoSlideTimer;

  late TabController _tabController;

  bool _isEveryoneLoading = true;
  List<Map<String, dynamic>> _everyoneUsers = [];

  bool _isOnlineLoading = true;
  bool _isVerifiedLoading = true;
  List<Map<String, dynamic>> _onlineUsers = [];
  List<Map<String, dynamic>> _verifiedUsers = [];

  Future<void> _fetchEveryoneUsers() async {
    try {
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
            if (mounted) {
              setState(() {
                _everyoneUsers = List<Map<String, dynamic>>.from(rawList);
                _isEveryoneLoading = false;
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("[Home] Error fetching everyone users: $e");
    }
    if (mounted) {
      setState(() {
        _isEveryoneLoading = false;
      });
    }
  }

  Future<void> _fetchOnlineUsers() async {
    try {
      final String myEmail = await SecureStorage().getUserEmail() ?? "";
      final response = await HomeService().showOnlineUsers(
        myEmail: myEmail.trim(),
      );
      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        final res = doc.findAllElements('ShowOnlineUsersResult');
        if (res.isNotEmpty) {
          final Map<String, dynamic> jsonResult = jsonDecode(
            res.first.innerText,
          );
          if (jsonResult["Status"] == 1 && jsonResult["Data"] is List) {
            if (mounted) {
              setState(() {
                _onlineUsers = List<Map<String, dynamic>>.from(
                  jsonResult["Data"],
                );
                _isOnlineLoading = false;
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("[Home] Error fetching online users: $e");
    }
    if (mounted) {
      setState(() {
        _isOnlineLoading = false;
      });
    }
  }

  Future<void> _fetchVerifiedUsers() async {
    try {
      final String myEmail = await SecureStorage().getUserEmail() ?? "";
      final response = await HomeService().showVerifiedUsers(
        myEmail: myEmail.trim(),
      );
      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        final res = doc.findAllElements('ShowVerifiedUsersResult');
        if (res.isNotEmpty) {
          final Map<String, dynamic> jsonResult = jsonDecode(
            res.first.innerText,
          );
          if (jsonResult["Status"] == 1 && jsonResult["Data"] is List) {
            if (mounted) {
              setState(() {
                _verifiedUsers = List<Map<String, dynamic>>.from(
                  jsonResult["Data"],
                );
                _isVerifiedLoading = false;
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("[Home] Error fetching verified users: $e");
    }
    if (mounted) {
      setState(() {
        _isVerifiedLoading = false;
      });
    }
  }

  final List<Map<String, dynamic>> activeUsers = [
    {
      "name": "Ava",
      "age": 29,
      "flag": "🇮🇳",
      "height": "5'5\"",
      "city": "Mumbai, India",
      "distance": "2 km away",
      "image": "https://images.unsplash.com/photo-1544005313-94ddf0286df2",
      "hasChatted": true,
    },
    {
      "name": "Emma",
      "age": 32,
      "flag": "🇮🇳",
      "height": "5'4\"",
      "city": "New Delhi, India",
      "distance": "5 km away",
      "image": "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e",
      "hasChatted": false,
    },
    {
      "name": "Sophia",
      "age": 27,
      "flag": "🇮🇳",
      "height": "5'6\"",
      "city": "Bangalore, India",
      "distance": "8 km away",
      "image": "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
      "hasChatted": true,
    },
    {
      "name": "Olivia",
      "age": 26,
      "flag": "🇮🇳",
      "height": "5'3\"",
      "city": "Hyderabad, India",
      "distance": "15 km away",
      "image": "https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91",
      "hasChatted": false,
    },
    {
      "name": "Rose",
      "age": 24,
      "flag": "🇮🇳",
      "height": "5'4\"",
      "city": "Pune, India",
      "distance": "10 km away",
      "image": "https://images.unsplash.com/photo-1517841905240-472988babdf9",
      "hasChatted": false,
    },
    {
      "name": "Lina",
      "age": 28,
      "flag": "🇮🇳",
      "height": "5'5\"",
      "city": "Chennai, India",
      "distance": "18 km away",
      "image": "https://images.unsplash.com/photo-1488426862026-3ee34a7d66df",
      "hasChatted": true,
    },
  ];

  final List<Map<String, dynamic>> verifiedUsers = [
    {
      "name": "Mika",
      "age": 25,
      "flag": "🇮🇳",
      "height": "5'6\"",
      "city": "Kolkata, India",
      "distance": "20 km away",
      "image": "https://images.unsplash.com/photo-1524504388940-b1c1722653e1",
      "hasChatted": false,
    },
    {
      "name": "Anya",
      "age": 23,
      "flag": "🇮🇳",
      "height": "5'3\"",
      "city": "Ahmedabad, India",
      "distance": "22 km away",
      "image": "https://images.unsplash.com/photo-1438761681033-6461ffad8d80",
      "hasChatted": false,
    },
    {
      "name": "Zoe",
      "age": 30,
      "flag": "🇮🇳",
      "height": "5'5\"",
      "city": "Jaipur, India",
      "distance": "25 km away",
      "image": "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e",
      "hasChatted": true,
    },
    {
      "name": "Sara",
      "age": 27,
      "flag": "🇮🇳",
      "height": "5'4\"",
      "city": "Surat, India",
      "distance": "30 km away",
      "image": "https://images.unsplash.com/photo-1517841905240-472988babdf9",
      "hasChatted": false,
    },
    {
      "name": "Nila",
      "age": 31,
      "flag": "🇮🇳",
      "height": "5'6\"",
      "city": "Lucknow, India",
      "distance": "35 km away",
      "image": "https://images.unsplash.com/photo-1544005313-94ddf0286df2",
      "hasChatted": false,
    },
  ];

  final List<Map<String, dynamic>> _topCards = [
    {
      "image": "https://images.unsplash.com/photo-1501785888041-af3ef285b470",
      "title": "Travel Alert",
      "subtitle": "Upcoming Traveller meet",
      "buttonText": "Travel Alert",
      "screen": "travel",
      "isTravelAlert": true,
    },
    {
      "image": "assets/freetonight.jpeg",
      "title": "Free Tonight 🌙",
      "subtitle": "People available now",
      "buttonText": "Join Now",
      "screen": "events",
      "isTravelAlert": false,
    },
  ];

  Future<void> _fetchAndUpdateLocation({bool requestIfNeeded = true}) async {
    try {
      LocationPermission permission;
      if (requestIfNeeded) {
        permission = await PermissionService.requestLocationPermission(
          showRationaleOnPermanentlyDenied: false,
        );
      } else {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return;
        permission = await Geolocator.checkPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        if (mounted) {
          setState(() => _currentPosition = position);
        }
        _updateCityFromCoordinates(position.latitude, position.longitude);

        final email = await SecureStorage().getUserEmail();
        if (email != null && email.isNotEmpty) {
          final response = await RegisterService().updateLatLon(
            email: email,
            lat: position.latitude.toString(),
            lon: position.longitude.toString(),
          );
          debugPrint(
            "[Home] UpdateLatLon response status: ${response.statusCode}",
          );
        }
      }
    } catch (e) {
      debugPrint("[Home] Location update error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    HomeScreen.state = this;
    WidgetsBinding.instance.addObserver(this);
    _checkLoginAndLoadProfile();
    _fetchEveryoneUsers();
    _fetchOnlineUsers();
    _fetchVerifiedUsers();
    _tabController = TabController(length: 2, vsync: this);
    // ✅ Free Tonight ke liye 5 sec timer — Travel Alert pe skip
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (_currentPage == 0) return; // Travel Alert = video handle karega
      final nextPage = (_currentPage + 1) % _topCards.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (HomeScreen.state == this) {
      HomeScreen.state = null;
    }
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchAndUpdateLocation(requestIfNeeded: false);
    }
  }

  Future<void> _checkLoginAndLoadProfile() async {
    final storedEmail = await SecureStorage().getUserEmail();
    if (storedEmail == null || storedEmail.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAll(
          () => WelcomeScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 600),
        );
      });
      return;
    }

    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

    // 🔥 1. Update Online Status to True on Server
    try {
      RegisterService()
          .updateOnlineStatus(email: storedEmail, isOnline: true)
          .then((res) {
            debugPrint(
              "[Home] UpdateOnlineStatus (True) status: ${res.statusCode}",
            );
          })
          .catchError((e) {
            debugPrint("[Home] UpdateOnlineStatus error: $e");
          });
    } catch (e) {
      debugPrint("[Home] UpdateOnlineStatus exception: $e");
    }

    // 🔔 2. Check & Request Notification Permission + Update FCM Token
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final isNotifGranted = await PermissionService.isNotificationGranted();
        if (!isNotifGranted) {
          await PermissionService.requestNotificationPermission(
            showRationaleOnPermanentlyDenied: false,
          );
        }
      } catch (e) {
        debugPrint("[Home] Notification permission error: $e");
      }

      try {
        await authController.updateFCMTokenIfAvailable(email: storedEmail);
      } catch (e) {
        debugPrint("[Home] FCM Token update error: $e");
      }

      // 📍 3. Check & Request Location Permission + Update Current GPS City
      await _fetchAndUpdateLocation(requestIfNeeded: true);
    });

    // Shared storage mein check karein ki profile data saved hai ya nahi
    final cachedJsonStr = await SecureStorage().getProfileJson();

    if (cachedJsonStr == null || cachedJsonStr.trim().isEmpty) {
      // User ka data shared storage mein save nahi hai -> Bina delay ke home screen par hi fetch karke save karayein
      debugPrint(
        "[Home] User profile data not found in shared storage. Calling ShowCompleteProfile immediately...",
      );
      try {
        await authController.fetchAndStoreFullProfile(email: storedEmail);
        debugPrint(
          "[Home] Full user profile fetched and saved in shared storage.",
        );
      } catch (e) {
        debugPrint("[Home] Error fetching full profile on home screen: $e");
      }
      await _loadCachedProfileInfo();
    } else {
      // Shared storage mein data pehle se hai -> Fast load UI
      await _loadCachedProfileInfo();

      // Background mein fresh profile sync karke shared storage update karein
      try {
        await authController.fetchAndStoreFullProfile(email: storedEmail);
        debugPrint("[Home] Background profile refreshed from server.");
        await _loadCachedProfileInfo();
      } catch (e) {
        debugPrint("[Home] Background profile refresh error: $e");
      }
    }
  }

  bool _isBlockedDialogShowing = false;

  void _showBlockedDialog() {
    if (_isBlockedDialogShowing || !mounted) return;
    _isBlockedDialogShowing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (BuildContext dialogContext) {
          return PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF181926),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Blocked Icon
                    Container(
                      width: 72.w,
                      height: 72.w,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.45),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.block_rounded,
                        color: Colors.redAccent,
                        size: 38.sp,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    // Title
                    Text(
                      "You are blocked",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // Message
                    Text(
                      "You are blocked by admin.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // Contact Us Button
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final Uri emailUri = Uri(
                            scheme: 'mailto',
                            path: 'support@boomboom.app',
                            query: 'subject=Account%20Blocked%20Inquiry',
                          );
                          try {
                            if (await canLaunchUrl(emailUri)) {
                              await launchUrl(
                                emailUri,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              await launchUrl(emailUri);
                            }
                          } catch (e) {
                            debugPrint("Error opening email app: $e");
                          }
                        },
                        icon: Icon(
                          Icons.mail_outline_rounded,
                          color: Colors.black,
                          size: 20.sp,
                        ),
                        label: Text(
                          "Contact Us",
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    // Close App Button
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          SystemNavigator.pop();
                          exit(0);
                        },
                        icon: Icon(
                          Icons.power_settings_new_rounded,
                          color: Colors.redAccent,
                          size: 20.sp,
                        ),
                        label: Text(
                          "Close App",
                          style: GoogleFonts.poppins(
                            color: Colors.redAccent,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.redAccent.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Future<void> _loadCachedProfileInfo() async {
    try {
      final jsonStr = await SecureStorage().getProfileJson();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        final List? dataList = decoded["Data"];
        if (dataList != null && dataList.isNotEmpty) {
          final data = dataList.first;

          // Check verification / blocked status
          final String isVerifiedStatus =
              (data["IsVerified"] ?? data["isVerified"] ?? "")
                  .toString()
                  .trim()
                  .toLowerCase();
          if (isVerifiedStatus == "blocked") {
            _showBlockedDialog();
          }

          String? imageUrl;
          dynamic rawMedia = data["Media"] ?? data["Photos"] ?? data["Photo"];
          if (rawMedia is List && rawMedia.isNotEmpty) {
            final firstMedia = rawMedia.first;
            if (firstMedia is Map) {
              imageUrl = firstMedia["Url"] ?? firstMedia["Media"];
            } else if (firstMedia is String) {
              imageUrl = firstMedia;
            }
          }

          final String? lat = data["Lat"]?.toString();
          final String? lon = data["Lon"]?.toString();

          if (mounted) {
            setState(() {
              if (imageUrl != null && imageUrl.isNotEmpty) {
                _profileImageUrl = imageUrl;
              }
            });
          }

          final double? latDouble = double.tryParse(lat ?? "");
          final double? lonDouble = double.tryParse(lon ?? "");
          if (latDouble != null &&
              lonDouble != null &&
              latDouble != 0.0 &&
              lonDouble != 0.0) {
            _updateCityFromCoordinates(latDouble, lonDouble);
          }
        }
      }
    } catch (e) {
      debugPrint("[Home] Error loading cached profile info: $e");
    }
  }

  Future<void> _updateCityFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final geocoder = geo.Geocoding();
      List<geo.Placemark> placemarks = await geocoder.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final String city =
            placemark.locality ??
            placemark.subAdministrativeArea ??
            placemark.name ??
            "Pattaya City";
        if (mounted) {
          setState(() {
            _currentCityName = city;
          });
        }
      }
    } catch (e) {
      debugPrint("[Home] Geocoding error: $e");
    }
  }

  // ✅ VideoBackgroundCard yahan call karega jab video end ho
  void _onTravelVideoEnd() {
    if (!mounted) return;
    final nextPage = (_currentPage + 1) % _topCards.length;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _handleCardTap(String screen) {
    if (screen == "travel") {
      Get.to(() => TravelAlertScreen());
    } else if (screen == "events") {
      Get.to(() => const EventsScreen());
    }
  }

  Widget _travelAlertCard(Map<String, dynamic> card) {
    return VideoBackgroundCard(
      videoAsset: "assets/videos/travel.mp4",
      title: card["title"],
      subtitle: card["subtitle"],
      onTap: () => _handleCardTap(card["screen"]),
      borderRadius: BorderRadius.circular(20),
      onVideoEnd: _onTravelVideoEnd, // ✅ video khatam → next slide
    );
  }

  Widget _normalCard(Map<String, dynamic> card) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: TopCard(
        image: card["image"],
        title: card["title"],
        subtitle: card["subtitle"],
        buttonText: card["buttonText"],
        onTap: () => _handleCardTap(card["screen"]),
      ),
    );
  }

  // Widget _pillBadge({
  //   required Widget child,
  //   required Color borderColor,
  //   Color? bgColor,
  //   EdgeInsets? padding,
  // }) {
  //   return Container(
  //     padding: padding ?? EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(20.r),
  //       border: Border.all(color: borderColor, width: 1),
  //       color: bgColor ?? Colors.transparent,
  //     ),
  //     child: child,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          // Rebuild the profile sections whenever Apply Filters changes the
          // shared in-memory filter controller.
          // ignore: unused_local_variable
          final filterVersion = FilterController.instance.filterVersion.value;
          return ListView(
            children: [
              // ── TOP BAR ──────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Get.to(() => SettingsScreen()),
                          child: CircleAvatar(
                            radius: 18.r,
                            backgroundImage: NetworkImage(_profileImageUrl),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Row(
                          children: [
                            Text(
                              _currentCityName,
                              style: AppTextStyles.subHeading,
                            ),
                            SizedBox(width: 4.w),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // ✅ Circle grey (pehle jaisa) — sirf icon YELLOW
                        GestureDetector(
                          onTap: () {
                            Get.to(() => const NotificationSettingsScreen());
                          },
                          child: CustomLottieee(
                            asset: "assets/Notification bell.json",
                            height: 28.h,
                            width: 28.w,
                          ),
                        ),

                        // SizedBox(width: 10.w),

                        // Filter Icon — connected to FilterController (Commented out for now)
                        // GestureDetector(
                        //   onTap: () async {
                        //     await Get.to(() => const FilterPreferencesScreen());
                        //     setState(() {});
                        //   },
                        //   child: Obx(() {
                        //     final isActive =
                        //         FilterController.instance.isFilterActive;
                        //     return CircleAvatar(
                        //       backgroundColor: isActive
                        //           ? const Color(0xFFE8335A)
                        //           : Colors.grey.shade800,
                        //       child: const Icon(
                        //         Icons.tune_rounded,
                        //         color: Colors.white,
                        //       ),
                        //     );
                        //   }),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // ── CAROUSEL ─────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: SizedBox(
                  height: 200.h,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: _topCards.length,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemBuilder: (context, index) {
                          final card = _topCards[index];
                          if (card["isTravelAlert"] == true) {
                            return _travelAlertCard(card);
                          }
                          return _normalCard(card);
                        },
                      ),
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _topCards.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: EdgeInsets.symmetric(horizontal: 4.w),
                              width: _currentPage == index ? 20.w : 7.w,
                              height: 7.h,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? Colors.white
                                    : Colors.white38,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // ── NEW MATCHES LABEL ─────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.08),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyanAccent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyanAccent.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.local_fire_department,
                              color: Colors.orangeAccent,
                              size: 18.sp,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Text(
                            "NEW",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NewUsersScreen(),
                          ),
                        ),
                        child: Container(
                          width: 30.w,
                          height: 30.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.cyanAccent,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.cyanAccent,
                            size: 15.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              SizedBox(height: AppSize.h(420), child: FullCardScreen()),

              SizedBox(height: 24.h),

              // ── ACTIVE / VERIFIED TABS ────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _tabController.animateTo(0);
                        setState(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: _tabController.index == 0
                              ? Colors.cyanAccent.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: _tabController.index == 0
                                ? Colors.cyanAccent.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2ECC71),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              "Active",
                              style: AppTextStyles.subHeading.copyWith(
                                fontSize: 12.sp,
                                color: _tabController.index == 0
                                    ? Colors.white
                                    : Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: () {
                        _tabController.animateTo(1);
                        setState(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: _tabController.index == 1
                              ? Colors.cyanAccent.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: _tabController.index == 1
                                ? Colors.cyanAccent.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              color: Colors.cyanAccent,
                              size: 11.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              "Verified",
                              style: AppTextStyles.subHeading.copyWith(
                                fontSize: 12.sp,
                                color: _tabController.index == 1
                                    ? Colors.white
                                    : Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 18.h),

              Builder(
                builder: (_) {
                  final isActive = _tabController.index == 0;
                  final isLoading = isActive
                      ? _isOnlineLoading
                      : _isVerifiedLoading;
                  final rawList = isActive ? _onlineUsers : _verifiedUsers;

                  if (isLoading) {
                    return SizedBox(
                      height: 220.h,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF9B59B6),
                          strokeWidth: 2.5,
                        ),
                      ),
                    );
                  }

                  // Filter profiles in frontend memory
                  final filtered = FilterController.instance.applyFilterToUsers(
                    rawList,
                    userPosition: _currentPosition,
                  );
                  final displayUsers = filtered.take(5).toList();

                  return _activeVerifiedUserRow(displayUsers, isActive);
                },
              ),

              SizedBox(height: 28.h),

              // ── EVERYONE ROW ──────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.08),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40.w,
                            height: 52.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyanAccent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyanAccent.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.groups_rounded,
                              color: Colors.cyanAccent,
                              size: 15.sp,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Everyone",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                "Everyone's here, explore freely",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MatchesScreen(),
                          ),
                        ),
                        child: Container(
                          width: 30.w,
                          height: 30.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.cyanAccent,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.cyanAccent,
                            size: 15.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              // ── EVERYONE GRID ─────────────────────────────
              Builder(
                builder: (_) {
                  if (_isEveryoneLoading) {
                    return SizedBox(
                      height: 180.h,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF9B59B6),
                          strokeWidth: 2.5,
                        ),
                      ),
                    );
                  }

                  if (_everyoneUsers.isEmpty) {
                    return _homeEmptyState(
                      title: "No new profiles found",
                      subtitle: "Please refresh or check back soon.",
                      icon: Icons.people_alt_rounded,
                      onRefresh: _fetchEveryoneUsers,
                    );
                  }

                  // Filter profiles in frontend memory
                  final filtered = FilterController.instance.applyFilterToUsers(
                    _everyoneUsers,
                    userPosition: _currentPosition,
                  );
                  // First 11 filtered users from API, 12th is "See All"
                  final displayUsers = filtered.take(11).toList();

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayUsers.length + 1,
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6.w,
                      mainAxisSpacing: 5.h,
                      // Slightly taller cards so profiles are easier to see.
                      childAspectRatio: 0.56,
                    ),
                    itemBuilder: (_, index) {
                      if (index == displayUsers.length) {
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MatchesScreen(),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14.r),
                              gradient: const LinearGradient(
                                colors: [Colors.cyanAccent, Colors.blueAccent],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10.w),
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 22.sp,
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  "See All",
                                  style: AppTextStyles.small.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return _everyoneGridCard(displayUsers[index]);
                    },
                  );
                },
              ),

              // Keep the last row above the persistent bottom navigation bar.
              SizedBox(height: 108.h + MediaQuery.of(context).padding.bottom),
            ],
          );
        }),
      ),
    );
  }

  Widget _activeVerifiedUserRow(
    List<Map<String, dynamic>> users,
    bool isActive,
  ) {
    if (users.isEmpty) {
      return _homeEmptyState(
        title: isActive ? "No active people" : "No verified people",
        subtitle: isActive
            ? "Active profiles will appear here when people come online."
            : "Verified profiles will appear here as they are approved.",
        icon: isActive ? Icons.wifi_tethering_rounded : Icons.verified_rounded,
        onRefresh: isActive ? _fetchOnlineUsers : _fetchVerifiedUsers,
      );
    }

    return SizedBox(
      height: 220.h,
      width: double.infinity,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: users.length + 1,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        itemBuilder: (_, index) {
          if (index == users.length) {
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Activeuser(initialTab: isActive ? 1 : 0),
                ),
              ),
              child: Container(
                width: 130.w,
                margin: EdgeInsets.only(right: 5.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.cyanAccent, Colors.blueAccent],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "See All",
                      style: AppTextStyles.small.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final user = users[index];
          final String fullName = (user["FullName"] ?? "User").toString();
          final int age = _calculateUserAge(user["Dob"]?.toString());
          final bool isOnline =
              user["IsOnline"]?.toString().toLowerCase() == "true" || isActive;
          final bool isVerified =
              user["IsVerified"]?.toString().toLowerCase() == "true" ||
              !isActive;
          final String? media = user["Media"]?.toString();
          final bool hasValidImg =
              media != null &&
              media.isNotEmpty &&
              media.toLowerCase() != "null" &&
              (media.startsWith("http") || media.startsWith("https"));

          final String initial = fullName.trim().isNotEmpty
              ? fullName.trim()[0].toUpperCase()
              : "U";

          return GestureDetector(
            onTap: () async {
              await Get.to(
                () => BoomProfileScreen(
                  userEmail:
                      user["EmailAddress"]?.toString() ??
                      user["email"]?.toString(),
                  initialUserData: user,
                  showLike: false,
                ),
                transition: Transition.rightToLeft,
              );
              HomeScreen.refreshHomeData();
              MessagePage.refreshChats();
            },
            child: Container(
              width: 130.w,
              margin: EdgeInsets.only(right: 5.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasValidImg)
                      Image.network(
                        media,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildUserRowInitialBg(initial),
                      )
                    else
                      _buildUserRowInitialBg(initial),

                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.92),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFF2ECC71)
                              : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2ECC71,
                              ).withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              "$fullName, $age",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.small.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                          if (isVerified) ...[
                            SizedBox(width: 3.w),
                            Icon(
                              Icons.verified_rounded,
                              color: Colors.cyanAccent,
                              size: 10.sp,
                            ),
                          ],
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
    );
  }

  Widget _homeEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onRefresh,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62.w,
              height: 62.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyanAccent.withValues(alpha: 0.10),
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.30),
                ),
              ),
              child: Icon(icon, color: Colors.cyanAccent, size: 30.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12.sp,
                height: 1.35,
              ),
            ),
            TextButton.icon(
              onPressed: onRefresh,
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

  Widget _buildUserRowInitialBg(String initial) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF28133E), Color(0xFF1B1B2F), Color(0xFF110E1D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF9B59B6), Color(0xFF3498DB)],
            ),
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _calculateUserAge(String? dobStr) {
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

  Widget _everyoneGridCard(Map<String, dynamic> user) {
    final String fullName = (user["FullName"] ?? "User").toString();
    final int age = _calculateUserAge(user["Dob"]?.toString());
    final String rawOnlineStatus =
        (user["OnlineStatus"] ??
                user["onlineStatus"] ??
                user["Status"] ??
                user["status"])
            ?.toString()
            .trim() ??
        "";
    final String onlineValue =
        (user["IsOnline"] ?? user["isOnline"] ?? user["Online"] ?? "")
            .toString()
            .trim()
            .toLowerCase();
    final bool isOnlineVal =
        onlineValue == "true" ||
        onlineValue == "1" ||
        onlineValue == "yes" ||
        onlineValue == "online";
    final String onlineStatus =
        rawOnlineStatus.isNotEmpty && rawOnlineStatus.toLowerCase() != "null"
        ? rawOnlineStatus
        : (isOnlineVal ? "Online" : "Offline");
    final String sLower = onlineStatus.toLowerCase();
    final bool isOnline =
        (sLower == "online" ||
            sLower == "online now" ||
            sLower == "active" ||
            sLower == "active now") &&
        sLower != "hidden" &&
        sLower != "offline";
    final String verifiedValue =
        (user["IsVerified"] ?? user["isVerified"] ?? "")
            .toString()
            .trim()
            .toLowerCase();
    final bool isVerified = verifiedValue == "true" || verifiedValue == "1";
    final String? media = user["Media"]?.toString();
    final bool hasValidImg =
        media != null &&
        media.isNotEmpty &&
        media.toLowerCase() != "null" &&
        (media.startsWith("http") || media.startsWith("https"));

    final String initial = fullName.trim().isNotEmpty
        ? fullName.trim()[0].toUpperCase()
        : "U";

    return GestureDetector(
      onTap: () async {
        await Get.to(
          () => BoomProfileScreen(
            userEmail:
                user["EmailAddress"]?.toString() ?? user["email"]?.toString(),
            initialUserData: user,
          ),
          transition: Transition.rightToLeft,
        );
        HomeScreen.refreshHomeData();
        MessagePage.refreshChats();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          color: const Color(0xFF151515),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasValidImg)
                Image.network(
                  media,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF28133E), Color(0xFF110E1D)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
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
                    child: Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9B59B6), Color(0xFF3498DB)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF9B59B6,
                            ).withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.95),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFF2ECC71) : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: isOnline
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF2ECC71,
                              ).withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        "$fullName, $age",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.small.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5.sp,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      SizedBox(width: 2.w),
                      Icon(
                        Icons.verified_rounded,
                        color: Colors.cyanAccent,
                        size: 11.sp,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // void _showLocationSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     isScrollControlled: true,
  //     builder: (_) {
  //       return Container(
  //         padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h),
  //         decoration: BoxDecoration(
  //           color: const Color(0xFF070707),
  //           borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
  //         ),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Container(
  //               width: 46.w,
  //               height: 5.h,
  //               decoration: BoxDecoration(
  //                 color: Colors.white38,
  //                 borderRadius: BorderRadius.circular(20.r),
  //               ),
  //             ),

  //             SizedBox(height: 24.h),

  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Text(
  //                   "Select Location",
  //                   style: TextStyle(
  //                     color: const Color(0xFFFF3D7F),
  //                     fontSize: 26.sp,
  //                     fontWeight: FontWeight.w800,
  //                   ),
  //                 ),
  //                 GestureDetector(
  //                   onTap: () => Navigator.pop(context),
  //                   child: Container(
  //                     height: 52.w,
  //                     width: 52.w,
  //                     decoration: BoxDecoration(
  //                       shape: BoxShape.circle,
  //                       color: Colors.white.withValues(alpha: 0.04),
  //                       border: Border.all(color: Colors.white12),
  //                     ),
  //                     child: Icon(Icons.close, color: Colors.white, size: 28.sp),
  //                   ),
  //                 ),
  //               ],
  //             ),

  //             SizedBox(height: 22.h),

  //             _locationOption(
  //               icon: Icons.navigation_rounded,
  //               title: "Use Current Location",
  //               subtitle: "Detect your location using GPS",
  //               gradientColors: const [Color(0xFF3A071D), Color(0xFF71123A)],
  //               borderColor: const Color(0xFFFF2D78),
  //               iconBgColor: const Color(0xFFFF2D78),
  //               onTap: () => Navigator.pop(context),
  //             ),

  //             SizedBox(height: 16.h),

  //             _locationOption(
  //               icon: Icons.map_rounded,
  //               title: "Choose on Map",
  //               subtitle: "Select location from map",
  //               gradientColors: const [Color(0xFF160B38), Color(0xFF29145F)],
  //               borderColor: const Color(0xFF7A3CFF),
  //               iconBgColor: const Color(0xFF8B45FF),
  //               onTap: () => Navigator.pop(context),
  //             ),

  //             SizedBox(height: MediaQuery.of(context).padding.bottom),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  // Widget _locationOption({
  //   required IconData icon,
  //   required String title,
  //   required String subtitle,
  //   required List<Color> gradientColors,
  //   required Color borderColor,
  //   required Color iconBgColor,
  //   required VoidCallback onTap,
  // }) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(22.r),
  //         gradient: LinearGradient(
  //           begin: Alignment.centerLeft,
  //           end: Alignment.centerRight,
  //           colors: gradientColors,
  //         ),
  //         border: Border.all(
  //           color: borderColor.withValues(alpha: 0.75),
  //           width: 1.3,
  //         ),
  //         boxShadow: [
  //           BoxShadow(
  //             color: borderColor.withValues(alpha: 0.28),
  //             blurRadius: 18,
  //             spreadRadius: 1,
  //           ),
  //         ],
  //       ),
  //       child: Row(
  //         children: [
  //           Container(
  //             height: 76.w,
  //             width: 76.w,
  //             decoration: BoxDecoration(
  //               shape: BoxShape.circle,
  //               color: iconBgColor,
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: iconBgColor.withValues(alpha: 0.65),
  //                   blurRadius: 20,
  //                   spreadRadius: 3,
  //                 ),
  //               ],
  //               border: Border.all(
  //                 color: Colors.white.withValues(alpha: 0.22),
  //                 width: 2,
  //               ),
  //             ),
  //             child: Icon(icon, color: Colors.white, size: 36.sp),
  //           ),

  //           SizedBox(width: 18.w),

  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   title,
  //                   style: TextStyle(
  //                     color: Colors.white,
  //                     fontSize: 20.sp,
  //                     fontWeight: FontWeight.w800,
  //                   ),
  //                 ),
  //                 // SizedBox(height: 6.h),
  //                 Text(
  //                   subtitle,
  //                   style: TextStyle(
  //                     color: Colors.white60,
  //                     fontSize: 14.sp,
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),

  //           Icon(
  //             Icons.arrow_forward_ios_rounded,
  //             color: Colors.white70,
  //             size: 24.sp,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
