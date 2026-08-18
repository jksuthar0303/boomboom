import 'dart:convert';

import 'package:boomboom/screens/profile/updateprofile/deletescreen.dart';
import 'package:boomboom/screens/profile/updateprofile/feedbackscreen.dart';
import 'package:boomboom/screens/profile/updateprofile/privacyscreen.dart';
import 'package:boomboom/screens/profile/updateprofile/termsscreen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:boomboom/backend/secure_storage.dart';
import 'package:boomboom/backend/registerservice.dart';
import 'package:boomboom/authentication/welcomscreens.dart';
import 'package:boomboom/screens/profile/updateprofile/selfieverification.dart';
import 'package:boomboom/screens/profile/updateprofile/subscriptionplan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart' as xml;
import 'package:share_plus/share_plus.dart';
import '../../../controller/appsetting.dart';

import '../../authentication/boomboom.dart';
import '../../widget/lotteewidgets.dart';
import '../home/homescreenitems/notificationscreen.dart';
import 'EditProfile.dart';

import 'help&support.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
class _C {
  static const surface = Color(0xFF181818);
  static const border = Color(0xFF252525);
  static const textPrimary = Color(0xFFD8D8D8);
  static const textSecondary = Color(0xFF666666);
  static const shadowDark = Color(0xFF0A0A0A);
  static const shadowLight = Color(0xFF1E1E1E);
  static const green = Color(0xFF1A2E1E);
  static const greenBorder = Color(0xFF1E3A22);
  static const greenText = Color(0xFF5FB85A);
  static const red = Color(0xFF2E1212);
  static const redBorder = Color(0xFF4A1A1A);
  static const redText = Color(0xFFE05555);
  static const blue = Color(0xFF131D2E);
  static const teal = Color(0xFF0F2626);
  static const yellow = Color(0xFF2A2010);
  static const orange = Color(0xFF2A1C0E);
  static const purple = Color(0xFF1E1230);
}

// ─── Responsive Helper ────────────────────────────────────────────────────────
// ─── Responsive Helper ────────────────────────────────────────────────────────
class _R {
  static bool isTablet(BuildContext ctx) => MediaQuery.of(ctx).size.width > 600;

  static double titleFs(BuildContext ctx) => isTablet(ctx) ? 28.sp : 22.sp;

  static double labelFs(BuildContext ctx) => isTablet(ctx) ? 18.sp : 15.sp;

  static double sectionFs(BuildContext ctx) => isTablet(ctx) ? 14.sp : 11.sp;

  static double badgeFs(BuildContext ctx) => isTablet(ctx) ? 12.sp : 9.sp;

  static double iconBoxSize(BuildContext ctx) => isTablet(ctx) ? 42.w : 32.w;

  static double iconBoxRadius(BuildContext ctx) => isTablet(ctx) ? 14.r : 10.r;

  static double neuBtnSize(BuildContext ctx) => isTablet(ctx) ? 44.w : 34.w;

  static double neuBtnRadius(BuildContext ctx) => isTablet(ctx) ? 14.r : 10.r;

  static double chevronSize(BuildContext ctx) => isTablet(ctx) ? 20.sp : 16.sp;

  static double hPad(BuildContext ctx) => isTablet(ctx) ? 28.w : 18.w;

  static double cardHMargin(BuildContext ctx) => isTablet(ctx) ? 24.w : 16.w;

  static double tileHPad(BuildContext ctx) => isTablet(ctx) ? 18.w : 14.w;

  static double tileVPad(BuildContext ctx) => isTablet(ctx) ? 15.h : 11.h;

  static double tileGroupRadius(BuildContext ctx) =>
      isTablet(ctx) ? 20.r : 16.r;

  static double iconGap(BuildContext ctx) => isTablet(ctx) ? 16.w : 12.w;
}

// ─── Neumorphic Box Decoration ────────────────────────────────────────────────
BoxDecoration neuDeco({Color color = _C.surface, double radius = 16}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _C.border, width: 1),
    boxShadow: const [
      BoxShadow(color: _C.shadowDark, offset: Offset(4, 4), blurRadius: 12),
      BoxShadow(color: Color(0xFF090909), offset: Offset(2, 2), blurRadius: 6),
      BoxShadow(color: _C.shadowLight, offset: Offset(-2, -2), blurRadius: 6),
    ],
  );
}

Future<void> _openVerificationFlow(BuildContext context) async {
  final email = await SecureStorage().getUserEmail();
  if (email == null || email.trim().isEmpty) return;
  if (!context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  String status = '';
  try {
    final response = await RegisterService()
        .showCompleteProfile(email: email.trim())
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final doc = xml.XmlDocument.parse(response.body);
      final nodes = doc.findAllElements('ShowCompleteProfileResult');
      if (nodes.isNotEmpty) {
        final decoded = jsonDecode(nodes.first.innerText);
        final sets = decoded['ResultSets'];
        if (sets is List) {
          for (final set in sets) {
            if (set is List && set.isNotEmpty && set.first is Map) {
              final item = Map<String, dynamic>.from(set.first);
              if (item.containsKey('IsVerified')) {
                status = item['IsVerified']?.toString() ?? '';
                break;
              }
            }
          }
        }
        if (status.isEmpty &&
            decoded['Data'] is List &&
            (decoded['Data'] as List).isNotEmpty) {
          status = (decoded['Data'].first['IsVerified'] ?? '').toString();
        }
      }
    }
  } catch (e) {
    debugPrint('Error checking verification status: $e');
  } finally {
    if (context.mounted &&
        Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  if (!context.mounted) return;
  final normalized = status.trim().toLowerCase();
  if (normalized == 'pending') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your profile verification is under review.'),
      ),
    );
  } else if (normalized == 'true') {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('You are verified.')));
  } else {
    Get.to(() => const SelfieVerificationScreen());
  }
}

// ─── Settings Screen ──────────────────────────────────────────────────────────
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // final AppSettingsController settings =
  // Get.put(AppSettingsController());

  @override
  Widget build(BuildContext context) {
    final isTab = _R.isTablet(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // 👈 change

      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              "https://i.postimg.cc/xdgdLC94/MDF3u-Llwv-E7W1ar-Hr-Gw18wf-Hv-Gr65gt-EJt-BEQm-Nabp-BIIvpm-Joq0c0m3b-Xks7yrt-Etty6Wr-T0Iiwowu-Osc-B9.jpg",
            ),
            fit: BoxFit.cover,
          ),
        ),

        /// 🔥 OVERLAY (optional but recommended)
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),

          child: SafeArea(
            child: Column(
              children: [
                _TopBar(),
                Expanded(child: isTab ? _TabletLayout() : _PhoneLayout()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Phone Layout ─────────────────────────────────────────────────────────────
class _PhoneLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileCard(),
          SizedBox(height: 20.h),
          _SpotlightCard(),
          SizedBox(height: 20.h),
          _TileGroupWidget(tiles: _allTiles(context)[0]),
          SizedBox(height: 18.h),
          _SectionLabel('Account'),
          _TileGroupWidget(tiles: _allTiles(context)[1]),
          SizedBox(height: 18.h),
          _SectionLabel('About'),
          _TileGroupWidget(tiles: _allTiles(context)[2]),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

// ─── Tablet Layout (two-column) ───────────────────────────────────────────────
class _TabletLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hm = _R.cardHMargin(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileCard(),
            SizedBox(height: 28.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TileGroupWidget(
                        tiles: _allTiles(context)[0],
                        noMargin: true,
                      ),
                      SizedBox(height: 20.h),
                      _SectionLabel('About'),
                      _TileGroupWidget(
                        tiles: _allTiles(context)[2],
                        noMargin: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                // Right column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('Account'),
                      _TileGroupWidget(
                        tiles: _allTiles(context)[1],
                        noMargin: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}

// ─── Tile Data Model ──────────────────────────────────────────────────────────
class _TileData {
  final Color iconBg;
  final Color iconBorder;
  final Widget emoji;
  final String label;
  final Color labelColor;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final String? subtitle;

  const _TileData({
    required this.iconBg,
    required this.iconBorder,
    required this.emoji,
    required this.label,
    this.labelColor = _C.textPrimary,
    this.trailingWidget,
    this.onTap,
    this.subtitle,
  });
}

final AppSettingsController settings = Get.put(AppSettingsController());

List<List<_TileData>> _allTiles(BuildContext context) => [
  [
    // const _TileData(
    //   iconBg: _C.green,
    //   iconBorder: _C.greenBorder,
    //   emoji: '🔥',
    //   label: 'BoomBoom Mode',
    // ),
  ],
  [
    _TileData(
      iconBg: _C.blue,
      iconBorder: Color(0xFF162240),
      emoji: Text('👤', style: TextStyle(fontSize: 18.sp)),
      label: 'View Profile',
      subtitle: "See your profile information",
      onTap: () => Get.to(
        () => const BoomProfileScreen(
          showStar: false,
          showMore: false,
          showTelegram: false,
          isOwnProfile: true,
        ),
      ),
    ),
    _TileData(
      iconBg: _C.teal,
      iconBorder: Color(0xFF133030),
      emoji: Text('✅', style: TextStyle(fontSize: 18.sp)),
      label: 'Verify Profile',
      subtitle: "Verify your account",
      onTap: () => _openVerificationFlow(context),
    ),
    // _TileData(iconBg: _C.blue, iconBorder: Color(0xFF162240),emoji: Text(
    // '✏️',
    // style: TextStyle(fontSize: 18.sp),
    // ), label: 'Edit Profile'),
    _TileData(
      iconBg: _C.blue,
      iconBorder: Color(0xFF133030),
      emoji: Text('✏️', style: TextStyle(fontSize: 18.sp)),
      label: 'Edit Profile',
      subtitle: "Update Your Details",
      onTap: () => Get.to(() => UpdateProfileTabsScreen()),
    ),
    _TileData(
      iconBg: _C.yellow,
      iconBorder: const Color(0xFF362A10),
      emoji: Text('⭐'),
      label: 'Subscription Plan',
      subtitle: "Manage your subscription",
      onTap: () {
        // Navigate to Selfie Verification Screen when tapped
        Get.to(() => SubscriptionScreen());
      },
      trailingWidget: const _FreeBadge(),
    ),
  ],
  [
    _TileData(
      iconBg: _C.surface,
      iconBorder: Color(0xFF2A2A2A),
      emoji: Text('📄', style: TextStyle(fontSize: 18.sp)),
      label: 'Terms & Conditions',
      subtitle: "Read Our Terms And Policies",
      onTap: () {
        Get.to(() => const TermsOfUseScreen());
      },
    ),
    _TileData(
      iconBg: _C.surface,
      iconBorder: Color(0xFF2A2A2A),
      emoji: Text('🔒', style: TextStyle(fontSize: 18.sp)),
      label: 'Privacy Policy',
      subtitle: "Check Our Privacy Policy",
      onTap: () {
        // Navigate to the FeedbackScreen when tapped
        Get.to(() => PrivacyPolicyScreen());
      },
    ),
    _TileData(
      iconBg: _C.teal,
      iconBorder: const Color(0xFF133030),
      emoji: Text('🎧', style: TextStyle(fontSize: 18.sp)),
      label: 'Help & Support',
      subtitle: "Solve Your Query",
      onTap: () {
        Get.to(HelpSupportScreen());
        // Navigate Screen
      },
    ),

    _TileData(
      iconBg: _C.yellow,
      iconBorder: const Color(0xFF362A10),
      emoji: Text('⭐', style: TextStyle(fontSize: 18.sp)),
      label: 'Rate Us',
      subtitle: "Rate Our App",
      onTap: () async {
        const playStoreUrl =
            'https://play.google.com/store/apps/details?id=com.boomboom.dating&pcampaignid=web_share';
        final uri = Uri.parse(playStoreUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          final marketUri = Uri.parse(
            'market://details?id=com.boomboom.dating',
          );
          if (await canLaunchUrl(marketUri)) {
            await launchUrl(marketUri, mode: LaunchMode.externalApplication);
          }
        }
      },
    ),
    _TileData(
      iconBg: _C.orange,
      iconBorder: const Color(0xFF362210),
      emoji: Text('⭐', style: TextStyle(fontSize: 18.sp)),
      label: 'Feedback',
      subtitle: "Give Your Feedback",
      onTap: () {
        // Navigate to the FeedbackScreen when tapped
        Get.to(() => SendFeedbackScreen());
      },
    ),
    _TileData(
      iconBg: _C.red,
      iconBorder: _C.redBorder,

      emoji: CustomLottieee(
        asset: "assets/Notification bell.json",

        height: 28.h,
        width: 28.w,
      ),

      label: 'Notification',

      subtitle: "Check Your Notification",

      onTap: () {
        Get.to(() => NotificationSettingsScreen());
      },

      labelColor: _C.redText,
    ),
    _TileData(
      iconBg: _C.yellow,
      iconBorder: const Color(0xFF362A10),
      emoji: Text('👻', style: TextStyle(fontSize: 18.sp)),
      label: 'Ghost Mode',
      subtitle: "Hide your online presence",
      trailingWidget: Obx(
        () => Switch(
          value: settings.ghostMode.value,

          onChanged: (v) {
            settings.ghostMode.value = v;
          },

          activeThumbColor: Colors.white,
          activeTrackColor: Colors.deepPurpleAccent,
        ),
      ),
    ),
    _TileData(
      iconBg: _C.purple,
      iconBorder: const Color(0xFF28164A),
      emoji: Text('🙈', style: TextStyle(fontSize: 18.sp)),
      label: 'Exclude Message Profile',
      subtitle: "message already send",
      trailingWidget: Obx(
        () => Switch(
          value: settings.hideChatUsers.value,

          onChanged: (v) {
            settings.hideChatUsers.value = v;
          },

          activeThumbColor: Colors.white,
          activeTrackColor: Colors.deepPurpleAccent,
        ),
      ),
    ),
    _TileData(
      iconBg: _C.red,
      iconBorder: _C.redBorder,
      emoji: Text('🗑️', style: TextStyle(fontSize: 18.sp)),
      label: 'Delete Profile',
      subtitle: "Delete Your Account",
      onTap: () {
        // Navigate to the FeedbackScreen when tapped
        Get.to(() => DeleteAccountScreen());
      },
      labelColor: _C.redText,
    ),
    _TileData(
      iconBg: _C.green,
      iconBorder: _C.greenBorder,
      emoji: Text('🔗', style: TextStyle(fontSize: 18.sp)),
      label: 'Share App',
      subtitle: "Invite friends to BoomBoom",
      labelColor: _C.greenText,
      onTap: () async {
        await SharePlus.instance.share(
          ShareParams(
            text:
                'We found a great dating app called BoomBoom! Meet genuine people, discover meaningful connections, and find your perfect match. Download it here: https://play.google.com/store/apps/details?id=com.boomboom.dating',
          ),
        );
      },
    ),
    _TileData(
      iconBg: _C.red,
      iconBorder: _C.redBorder,
      emoji: Text('🚪', style: TextStyle(fontSize: 18.sp)),
      label: 'Logout',
      subtitle: "Sign out of your account",
      labelColor: _C.redText,
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: _C.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
                side: const BorderSide(color: _C.border, width: 1.5),
              ),
              title: Text(
                "Confirm Logout",
                style: GoogleFonts.poppins(
                  color: _C.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
              content: Text(
                "Are you sure you want to log out of your account?",
                style: GoogleFonts.poppins(
                  color: _C.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.poppins(
                      color: _C.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      final GoogleSignIn googleSignIn = GoogleSignIn();
                      await googleSignIn.signOut();
                    } catch (e) {
                      debugPrint("Google Sign Out Error: $e");
                    }
                    await SecureStorage().clearAll();
                    Get.offAll(() => const WelcomeScreen());
                  },
                  child: Text(
                    "Logout",
                    style: GoogleFonts.poppins(
                      color: _C.redText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
  ],
];

// ─── Tile Group Widget ────────────────────────────────────────────────────────
class _TileGroupWidget extends StatelessWidget {
  final List<_TileData> tiles;
  final bool noMargin;
  const _TileGroupWidget({required this.tiles, this.noMargin = false});

  @override
  Widget build(BuildContext context) {
    final r = _R.tileGroupRadius(context);
    final hm = noMargin ? 0.0 : _R.cardHMargin(context);
    final visibleTiles = tiles
        .where(
          (tile) =>
              tile.label != 'Ghost Mode' &&
              tile.label != 'Exclude Message Profile',
        )
        .toList();
    visibleTiles.sort((a, b) {
      if (a.label == 'Share App') return -1;
      if (b.label == 'Share App') return 1;
      return 0;
    });
    if (visibleTiles.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hm),
      decoration: neuDeco(radius: r),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Column(
          children: visibleTiles.asMap().entries.map((e) {
            final isLast = e.key == visibleTiles.length - 1;
            return Column(
              children: [
                _TileRow(data: e.value),
                if (!isLast)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFF1F1F1F),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Tile Row ─────────────────────────────────────────────────────────────────
class _TileRow extends StatelessWidget {
  final _TileData data;
  const _TileRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // 👈 important for ripple
      child: InkWell(
        onTap: data.onTap ?? () {}, // ✅ safe tap (null crash fix)
        borderRadius: BorderRadius.circular(_R.tileGroupRadius(context)),

        splashColor: Colors.white.withValues(alpha: 0.06), // 🔥 better splash
        highlightColor: Colors.white.withValues(alpha: 0.03),

        child: Ink(
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(_R.tileGroupRadius(context)),
          ),

          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _R.tileHPad(context),
              vertical: _R.tileVPad(context),
            ),

            child: Row(
              children: [
                /// 🔥 ICON BOX
                Container(
                  width: _R.iconBoxSize(context),
                  height: _R.iconBoxSize(context),
                  decoration: BoxDecoration(
                    color: data.iconBg,
                    borderRadius: BorderRadius.circular(
                      _R.iconBoxRadius(context),
                    ),
                    border: Border.all(color: data.iconBorder, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF080808),
                        offset: Offset(2, 2),
                        blurRadius: 5,
                      ),
                      BoxShadow(
                        color: Color(0xFF222222),
                        offset: Offset(-1, -1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    // child: data.label == "Notification"
                    //
                    //     ? TweenAnimationBuilder<double>(
                    //
                    //   tween: Tween(begin: -0.15, end: 0.15),
                    //
                    //   duration: const Duration(milliseconds: 400),
                    //
                    //   curve: Curves.easeInOut,
                    //
                    //   builder: (context, angle, child) {
                    //
                    //     return Transform.rotate(
                    //
                    //       angle: angle,
                    //
                    //       child: Icon(
                    //         Icons.notifications_active_rounded,
                    //         color: Colors.redAccent,
                    //         size: 18.sp,
                    //       ),
                    //     );
                    //   },
                    //
                    //   onEnd: () {
                    //     (context as Element).markNeedsBuild();
                    //   },
                    // )
                    child: data.emoji,
                  ),
                ),

                SizedBox(width: _R.iconGap(context)),

                /// 🔥 LABEL
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        data.label,

                        style: GoogleFonts.nunito(
                          fontSize: _R.labelFs(context),

                          fontWeight: FontWeight.w900,

                          color: data.labelColor,
                        ),
                      ),

                      if (data.subtitle != null) ...[
                        SizedBox(height: 3.h),

                        Text(
                          data.subtitle!,

                          style: GoogleFonts.nunito(
                            fontSize: 11.sp,

                            color: Colors.white54,

                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                /// 🔥 TRAILING
                if (data.trailingWidget != null) ...[
                  data.trailingWidget!,
                  SizedBox(width: 6.w),
                ],

                /// 🔥 ARROW
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF3A3A3A),
                  size: _R.chevronSize(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _R.hPad(context),
        vertical: 12.h,
      ),
      child: Row(
        children: [
          _NeuButton(
            size: _R.neuBtnSize(context),
            radius: _R.neuBtnRadius(context),
            onTap: () => Navigator.maybePop(context),
            child: Icon(
              Icons.chevron_left,
              color: _C.textSecondary,
              size: 22.sp,
            ),
          ),
          const Spacer(),
          Text(
            'Settings',
            style: GoogleFonts.nunito(
              fontSize: _R.titleFs(context),
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          // _NeuButton(
          //   size: _R.neuBtnSize(context),
          //   radius: _R.neuBtnRadius(context),
          //   onTap: () {},
          //   child: Icon(Icons.settings_outlined, color: _C.textSecondary, size: 18.sp),
          // ),
        ],
      ),
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _R.isTablet(context);

    return FutureBuilder<String?>(
      future: SecureStorage().getProfileJson(),
      builder: (context, snapshot) {
        String name = "Sid";
        String email = "rocker971155@gmail.com";
        String initialLetter = "S";

        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty) {
          try {
            final decoded = jsonDecode(snapshot.data!);
            final List? dataList = decoded["Data"];
            if (dataList != null && dataList.isNotEmpty) {
              final data = dataList.first;
              name = data["FullName"] ?? name;
              email = data["EmailAddress"] ?? email;
              if (name.isNotEmpty) {
                initialLetter = name[0].toUpperCase();
              }
            }
          } catch (e) {
            debugPrint("Error parsing profile in _ProfileCard: $e");
          }
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 18.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.r),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF00E5FF),
                  Color(0xFF6D5DFF),
                  Color(0xFFFF2FB3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                  blurRadius: 25,
                ),
                BoxShadow(
                  color: const Color(0xFFFF00AA).withValues(alpha: 0.18),
                  blurRadius: 25,
                ),
              ],
            ),
            child: Container(
              margin: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26.r),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF021B3A),
                    Color(0xFF0B1248),
                    Color(0xFF28002F),
                  ],
                ),
                border: Border.all(
                  width: 1.5,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                children: [
                  /// AVATAR
                  Stack(
                    children: [
                      Container(
                        width: 86.w,
                        height: 86.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          border: Border.all(
                            color: const Color(0xFF00F0FF),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF00F0FF,
                              ).withValues(alpha: 0.5),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initialLetter,
                            style: GoogleFonts.nunito(
                              fontSize: 34.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFFC107),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "PREMIUM",
                                style: GoogleFonts.nunito(
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Icon(
                                Icons.star,
                                size: 10.sp,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  /// NAME
                  Text(
                    name,
                    style: GoogleFonts.nunito(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),

                  /// EMAIL
                  Text(
                    email,
                    style: GoogleFonts.nunito(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  /// COIN
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 18.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30.r),
                      border: Border.all(color: const Color(0xFFFFB300)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          color: Colors.amber,
                          size: 18.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          "Upgrade Now",
                          style: GoogleFonts.nunito(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Spotlight Card ─────────────────────────────────────────────

class _SpotlightCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          /// TITLE
          Row(
            children: [
              Icon(Icons.star, color: Colors.purpleAccent, size: 20.sp),

              SizedBox(width: 8.w),

              Text(
                "SPOTLIGHT",

                style: GoogleFonts.nunito(
                  color: Colors.white70,

                  fontSize: 16.sp,

                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),

          /// CARD
          Container(
            width: double.infinity,

            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.r),

              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,

                colors: [Color(0xFF161A52), Color(0xFF250035)],
              ),

              border: Border.all(color: Colors.purpleAccent, width: 1.4),

              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withValues(alpha: 0.25),

                  blurRadius: 20,
                ),
              ],
            ),

            child: Row(
              children: [
                /// ICON
                Container(
                  width: 40.w,
                  height: 40.w,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    border: Border.all(color: Colors.purpleAccent),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.purpleAccent.withValues(alpha: 0.5),

                        blurRadius: 18,
                      ),
                    ],
                  ),

                  child: Icon(
                    Icons.star_border,
                    color: Colors.purpleAccent,
                    size: 15.sp,
                  ),
                ),

                SizedBox(width: 16.w),

                /// TEXTS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        "You're in the Spotlight!",

                        style: GoogleFonts.nunito(
                          color: Colors.white,

                          fontSize: 18.sp,

                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      SizedBox(height: 6.h),

                      Text(
                        "Stand out and get more visibility.\nUpgrade to Premium to shine brighter.",

                        style: GoogleFonts.nunito(
                          color: Colors.white70,

                          fontSize: 12.sp,

                          height: 1.4,
                        ),
                      ),

                      SizedBox(height: 14.h),

                      /// BUTTON
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18.w,
                          vertical: 10.h,
                        ),

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.r),

                          gradient: const LinearGradient(
                            colors: [Color(0xFFB026FF), Color(0xFF3B82F6)],
                          ),
                        ),

                        child: Row(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            Text(
                              "Upgrade Now",

                              style: GoogleFonts.nunito(
                                color: Colors.white,

                                fontSize: 13.sp,

                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            SizedBox(width: 6.w),

                            Icon(
                              Icons.workspace_premium,
                              color: Colors.white,
                              size: 16.sp,
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
        ],
      ),
    );
  }
}

// ─── Phone Profile Content (centered column) ──────────────────────────────────
// class _PhoneProfileContent extends StatelessWidget {
//   final BuildContext context;
//   const _PhoneProfileContent({required this.context});

//   @override
//   Widget build(BuildContext _) {
//     return Column(
//       children: [
//         _AvatarStack(ctx: context),
//         SizedBox(height: 10.h),
//         Text(
//           'Sid',
//           style: GoogleFonts.nunito(
//             fontSize: _R.nameFs(context),
//             fontWeight: FontWeight.w800,
//             color: _C.textPrimary,
//           ),
//         ),
//         SizedBox(height: 2.h),
//         Text(
//           'rocker971155@gmail.com',
//           style: GoogleFonts.nunito(fontSize: _R.emailFs(context), color: _C.textSecondary),
//         ),
//         SizedBox(height: 10.h),
//         _CoinBadge(ctx: context),
//       ],
//     );
//   }
// }

// // ─── Tablet Profile Content (row layout) ─────────────────────────────────────
// class _TabletProfileContent extends StatelessWidget {
//   final BuildContext context;
//   const _TabletProfileContent({required this.context});

//   @override
//   Widget build(BuildContext _) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         _AvatarStack(ctx: context),
//         SizedBox(width: 24.w),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Sid',
//                 style: GoogleFonts.nunito(
//                   fontSize: _R.nameFs(context),
//                   fontWeight: FontWeight.w800,
//                   color: _C.textPrimary,
//                 ),
//               ),
//               SizedBox(height: 4.h),
//               Text(
//                 'rocker971155@gmail.com',
//                 style: GoogleFonts.nunito(
//                   fontSize: _R.emailFs(context),
//                   color: _C.textSecondary,
//                 ),
//               ),
//               SizedBox(height: 12.h),
//               _CoinBadge(ctx: context),
//             ],
//           ),
//         ),
//         // Tablet-only: Quick Edit button
//         GestureDetector(
//           onTap: () {
//       Get.to(() =>UpdateProfileTabsScreen ());
//           },
//           child: Container(
//             padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
//             decoration: BoxDecoration(
//               color: _C.gold,
//               borderRadius: BorderRadius.circular(12.r),
//               boxShadow: const [
//                 BoxShadow(color: Color(0xFF0A0A0A), offset: Offset(2, 2), blurRadius: 6),
//               ],
//             ),
//             child: Text(
//               'Edit Profile',
//               style: GoogleFonts.nunito(
//                 fontSize: 13.sp,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.black,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// ─── Avatar Stack ─────────────────────────────────────────────────────────────
// class _AvatarStack extends StatelessWidget {
//   final BuildContext ctx;
//   const _AvatarStack({required this.ctx});

//   @override
//   Widget build(BuildContext context) {
//     final size = _R.avatarSize(ctx);
//     final camSize = _R.cameraBtnSize(ctx);

//     return Stack(
//       children: [
//         Container(
//           width: size,
//           height: size,
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [Color(0xFF1A1A1A), Color(0xFF111111)],
//             ),
//             shape: BoxShape.circle,
//             border: Border.all(color: const Color(0xFF2E2E2E), width: 2),
//             boxShadow: const [
//               BoxShadow(color: Color(0xFF080808), offset: Offset(3, 3), blurRadius: 8),
//               BoxShadow(color: Color(0xFF1E1E1E), offset: Offset(-2, -2), blurRadius: 6),
//             ],
//           ),
//           child: Center(
//             child: Text(
//               'S',
//               style: GoogleFonts.nunito(
//                 fontSize: _R.avatarInitialFs(ctx),
//                 fontWeight: FontWeight.w800,
//                 color: _C.gold,
//               ),
//             ),
//           ),
//         ),
//         Positioned(
//           bottom: 0,
//           right: 0,
//           child: Container(
//             width: camSize,
//             height: camSize,
//             decoration: BoxDecoration(
//               color: _C.gold,
//               shape: BoxShape.circle,
//               border: Border.all(color: _C.bg, width: 2),
//             ),
//             child: const Icon(Icons.camera_alt, color: Colors.black, size: 12),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ─── Coin Badge ───────────────────────────────────────────────────────────────
// class _CoinBadge extends StatelessWidget {
//   final BuildContext ctx;
//   const _CoinBadge({required this.ctx});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
//       decoration: BoxDecoration(
//         color: _C.surface,
//         borderRadius: BorderRadius.circular(20.r),
//         border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
//         boxShadow: const [
//           BoxShadow(color: Color(0xFF0A0A0A), offset: Offset(3, 3), blurRadius: 6),
//           BoxShadow(color: Color(0xFF1E1E1E), offset: Offset(-2, -2), blurRadius: 5),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text('🪙', style: TextStyle(fontSize: 14)),
//           SizedBox(width: 6.w),
//           Text(
//             '0',
//             style: GoogleFonts.nunito(
//               fontSize: _R.coinFs(ctx),
//               fontWeight: FontWeight.w700,
//               color: _C.gold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ─── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final isTab = _R.isTablet(context);
    return Padding(
      padding: EdgeInsets.only(
        left: isTab ? 0 : _R.hPad(context),
        right: isTab ? 0 : _R.hPad(context),
        bottom: 8.h,
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.nunito(
          fontSize: _R.sectionFs(context),
          fontWeight: FontWeight.w700,
          color: _C.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Free Badge ───────────────────────────────────────────────────────────────
class _FreeBadge extends StatelessWidget {
  const _FreeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: _C.green,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _C.greenBorder, width: 1),
      ),
      child: Text(
        'Free',
        style: GoogleFonts.nunito(
          fontSize: _R.badgeFs(context),
          fontWeight: FontWeight.w700,
          color: _C.greenText,
        ),
      ),
    );
  }
}

// ─── Neumorphic Button ────────────────────────────────────────────────────────
class _NeuButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final double size;
  final double radius;

  const _NeuButton({
    required this.onTap,
    required this.child,
    required this.size,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: _C.border, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF0A0A0A),
              offset: Offset(3, 3),
              blurRadius: 7,
            ),
            BoxShadow(
              color: Color(0xFF202020),
              offset: Offset(-3, -3),
              blurRadius: 7,
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
