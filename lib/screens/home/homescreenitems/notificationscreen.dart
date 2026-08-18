import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../backend/home_service.dart';
import '../../../backend/secure_storage.dart';
import '../../../constant/appsize.dart';
import '../../../constant/apptextstyle.dart';
import '../../../model/notification.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _allNotifications = true;
  bool _isLoading = true;
  String? _loadError;

  late final List<NotifItem> _notifications;

  @override
  void initState() {
    super.initState();

    _notifications = [
      NotifItem(
        id: 'messages',
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Messages Notifications',
        subtitle: 'Get notified when you receive new messages.',
        value: true,
      ),

      NotifItem(
        id: 'match_notif',
        icon: Icons.favorite_border_rounded,
        title: 'Match Notifications',
        subtitle: 'Receive alerts when you get a new match.',
        value: true,
      ),

      NotifItem(
        id: 'likes',
        icon: Icons.thumb_up_alt_outlined,
        title: 'Likes Notifications',
        subtitle: 'Get notifications when someone likes your profile.',
        value: true,
      ),

      NotifItem(
        id: 'who_viewed',
        icon: Icons.remove_red_eye_outlined,
        title: 'Who Viewed You',
        subtitle: 'Get alerts when someone views your profile.',
        value: true,
      ),

      NotifItem(
        id: 'cross_path',
        icon: Icons.shuffle_rounded,
        title: 'Cross Path Notifications',
        subtitle:
            'Receive notifications when someone crosses your path nearby.',
        value: true,
      ),

      NotifItem(
        id: 'travel_alerts',
        icon: Icons.flight_rounded,
        title: 'Traveller Alerts',
        subtitle: 'Get updates about travellers visiting your location.',
        value: true,
      ),

      NotifItem(
        id: 'free_tonight',
        icon: Icons.calendar_month_rounded,
        title: 'Free Tonight Alerts',
        subtitle: 'Receive alerts when someone is free tonight.',
        value: true,
      ),
    ];

    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final email = await SecureStorage().getUserEmail();
      if (email == null || email.trim().isEmpty) {
        throw Exception('User email not found.');
      }

      final token = await SecureStorage().getUserToken();
      final response = await HomeService().showSettingsByEmail(
        email: email.trim(),
        token: token,
      );

      final document = XmlResponseJson.decode(response.body);
      final data = document['Data'];
      if (document['Status'].toString() != '1' || data is! List) {
        throw Exception(
          document['Message']?.toString() ?? 'Unable to load settings.',
        );
      }

      final settingsByType = <String, bool>{};
      for (final row in data) {
        if (row is Map) {
          final type = row['Type']?.toString();
          if (type != null) {
            settingsByType[_normalise(type)] = _toBool(row['Mode']);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        for (final item in _notifications) {
          final value = settingsByType[_normalise(_apiTypeFor(item.id))];
          if (value != null) item.value = value;
        }
        _allNotifications = _notifications.every((item) => item.value);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _apiTypeFor(String id) {
    switch (id) {
      case 'messages':
        return 'Message Notifications';
      case 'match_notif':
        return 'Match Notifications';
      case 'likes':
        return 'Likes Notifications';
      case 'who_viewed':
        return 'Who viewed you';
      case 'cross_path':
        return 'Cross Path Notification';
      case 'travel_alerts':
        return 'Traveller Alerts';
      case 'free_tonight':
        return 'Free Tonight Alerts';
      default:
        return id;
    }
  }

  String _normalise(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  bool _toBool(dynamic value) =>
      value.toString().toLowerCase() == 'true' || value.toString() == '1';

  void _onAllToggle(bool val) {
    setState(() {
      _allNotifications = val;

      for (final item in _notifications) {
        item.value = val;
      }
    });

    _updateNotificationSetting(type: 'select all', mode: val);
  }

  void _onItemToggle(NotifItem item, bool val) {
    setState(() {
      item.value = val;

      _allNotifications = _notifications.every((e) => e.value);
    });

    _updateNotificationSetting(type: _apiTypeFor(item.id), mode: val);
  }

  Future<void> _updateNotificationSetting({
    required String type,
    required bool mode,
  }) async {
    try {
      final email = await SecureStorage().getUserEmail();
      if (email == null || email.trim().isEmpty) {
        throw Exception('User email not found.');
      }

      final token = await SecureStorage().getUserToken();
      await HomeService().updateSettings(
        type: type,
        mode: mode,
        email: email.trim(),
        token: token,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update notification setting.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      debugPrint('[NotificationSettings] Update failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    final hPad = isTablet ? 32.0 : AppSize.w(16);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,

      child: Scaffold(
        backgroundColor: Colors.black,

        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(isTablet),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.amber),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: hPad,
                          vertical: AppSize.h(16),
                        ),

                        child: Column(
                          children: [
                            if (_loadError != null)
                              Padding(
                                padding: EdgeInsets.only(bottom: 10.h),
                                child: Text(
                                  _loadError!,
                                  style: GoogleFonts.poppins(
                                    color: Colors.redAccent,
                                    fontSize: 11.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            _allNotificationCard(),

                            SizedBox(height: 10.h),

                            ..._notifications.map(
                              (e) => Padding(
                                padding: EdgeInsets.only(bottom: 10.h),
                                child: _notifCard(e),
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

  /// APPBAR
  Widget _buildAppBar(bool isTablet) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: isTablet ? 32.0 : AppSize.w(16),
      vertical: AppSize.h(12),
    ),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        SizedBox(height: 10.h),

        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                padding: EdgeInsets.all(8.sp),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.12,
                  ), // soft glass effect
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.08),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 15.sp,
                ),
              ),
            ),
            SizedBox(width: 50.h),
            Text(
              'Notifications Settings',

              style: AppTextStyles.subHeading.copyWith(
                fontSize: isTablet ? 24.sp : 20.sp,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        SizedBox(height: 6.h),

        Padding(
          padding: EdgeInsets.only(left: 70.h),
          child: Text(
            'Manage what notifications you want to receive.',

            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10.sp),
          ),
        ),
      ],
    ),
  );

  /// ALL NOTIFICATION CARD
  Widget _allNotificationCard() => Container(
    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),

    decoration: BoxDecoration(
      color: const Color(0xFF111827),

      borderRadius: BorderRadius.circular(22.r),

      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),

    child: Row(
      children: [
        _iconBox(Icons.notifications_none_rounded, Colors.amber),

        SizedBox(width: 10.w),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                'All Notifications',

                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: 4.h),

              Text(
                'Enable or disable all notifications from the app.',

                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ),

        _customSwitch(_allNotifications, (v) => _onAllToggle(v)),
      ],
    ),
  );

  /// NOTIFICATION CARD
  Widget _notifCard(NotifItem item) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 16.h),

    decoration: BoxDecoration(
      color: const Color(0xFF111827),

      borderRadius: BorderRadius.circular(15.r),

      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),

    child: Row(
      children: [
        _iconBox(item.icon, Colors.blueAccent),

        SizedBox(width: 10.w),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                item.title,

                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: 4.h),

              Text(
                item.subtitle,

                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 10.sp,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        _customSwitch(item.value, (v) => _onItemToggle(item, v)),
      ],
    ),
  );

  /// ICON BOX
  Widget _iconBox(IconData icon, Color color) => Container(
    width: 40.w,
    height: 40.w,

    decoration: BoxDecoration(
      color: const Color(0xFF1A2234),

      borderRadius: BorderRadius.circular(16.r),
    ),

    child: Icon(icon, color: color, size: 22.sp),
  );

  /// SWITCH
  Widget _customSwitch(bool value, ValueChanged<bool> onChanged) => Switch(
    value: value,

    activeThumbColor: Colors.white,

    activeTrackColor: Colors.amber,

    inactiveThumbColor: Colors.white,

    inactiveTrackColor: const Color(0xFF2A2A2A),

    onChanged: onChanged,
  );
}

/// Extracts the JSON payload from the SOAP/XML response returned by .NET.
class XmlResponseJson {
  static Map<String, dynamic> decode(String body) {
    final start = body.indexOf('{');
    final end = body.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('Invalid settings response.');
    }
    final decoded = jsonDecode(body.substring(start, end + 1));
    if (decoded is! Map) {
      throw const FormatException('Invalid settings payload.');
    }
    return Map<String, dynamic>.from(decoded);
  }
}
