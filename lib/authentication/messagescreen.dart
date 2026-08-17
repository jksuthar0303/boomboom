import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xml/xml.dart' as xml;

import '../backend/home_service.dart';
import '../backend/secure_storage.dart';
import '../constant/appsize.dart';
import '../constant/apptextstyle.dart';
import '../constant/colors.dart';
import '../model/messagescreen.dart';
import '../screens/home/homescreenitems/verifyiuser.dart';
import 'boomboom.dart';
import 'messagedetail.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => MessagePageState();
}

class MessagePageState extends State<MessagePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _onlineUsers = [];
  bool _isOnlineLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOnlineUsers();
  }

  Future<void> _fetchOnlineUsers() async {
    try {
      final email = await SecureStorage().getUserEmail() ?? "";
      final response = await HomeService().showOnlineUsers(myEmail: email);
      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        final res = doc.findAllElements('ShowOnlineUsersResult');
        if (res.isNotEmpty) {
          final Map<String, dynamic> jsonResult = jsonDecode(
            res.first.innerText,
          );
          if (jsonResult["Status"] == 1 && jsonResult["Data"] is List) {
            final List list = jsonResult["Data"];
            if (mounted) {
              setState(() {
                _onlineUsers = list
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList();
                _isOnlineLoading = false;
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("[MessagePage] Error fetching online users: $e");
    }
    if (mounted) {
      setState(() => _isOnlineLoading = false);
    }
  }

  // ── Sample Messages ──

  // ── Sample Messages ──
  static final List<MessageModel> messageList = [
    MessageModel(
      name: 'Rahul verma',
      message: 'Heyyy',
      image: 'https://randomuser.me/api/portraits/men/1.jpg',
      timestamp: 'now',
      unreadCount: 1,
    ),

    MessageModel(
      name: 'Priya Sharma',
      message: 'Hi there! How are you?',
      image: 'https://randomuser.me/api/portraits/women/1.jpg',
      timestamp: 'yesterday',
    ),

    MessageModel(
      name: 'Amit Kumar',
      message: 'See you tomorrow 👋',
      image: 'https://randomuser.me/api/portraits/men/5.jpg',
      timestamp: '2d ago',
      unreadCount: 3,
    ),
  ];

  final List<MessageModel> _messages = messageList;

  List<MessageModel> get _filteredMessages => _messages
      .where(
        (m) =>
            m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            m.message.toLowerCase().contains(_searchQuery.toLowerCase()),
      )
      .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      ),
    );
  }

  // ─── Phone Layout ────────────────────────
  Widget _buildPhoneLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildSearchBar(),
        SizedBox(height: AppSize.h(20)),
        _buildSectionLabel('Online Now'),
        SizedBox(height: AppSize.h(12)),
        _buildActivitiesRow(),
        SizedBox(height: AppSize.h(20)),
        _buildSectionLabel('Messages'),
        SizedBox(height: AppSize.h(8)),
        Expanded(child: _buildMessagesList()),
      ],
    );
  }

  // ─── Tablet Layout ───────────────────────
  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Left: list panel
        SizedBox(
          width: 380.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSearchBar(),
              SizedBox(height: AppSize.h(20)),
              _buildSectionLabel('Online Now'),
              SizedBox(height: AppSize.h(12)),
              _buildActivitiesRow(),
              SizedBox(height: AppSize.h(20)),
              _buildSectionLabel('Messages'),
              SizedBox(height: AppSize.h(8)),
              Expanded(child: _buildMessagesList()),
            ],
          ),
        ),
        // Divider
        Container(width: 1, color: const Color(0xFF2A2A2A)),
        // Right: chat detail placeholder
        Expanded(
          child: Center(
            child: Text(
              'Select a conversation',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Header ─────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w(16),
        vertical: AppSize.h(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Messages', style: AppTextStyles.heading),
          // _callLogsButton(),
        ],
      ),
    );
  }

  // Widget _callLogsButton() {
  //   return Container(
  //     padding: EdgeInsets.symmetric(
  //       horizontal: AppSize.w(14),
  //       vertical: AppSize.h(8),
  //     ),
  //     decoration: BoxDecoration(
  //       border: Border.all(color: const Color(0xFF3A3A3A), width: 1.5),
  //       borderRadius: BorderRadius.circular(20.r),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(Icons.phone_outlined, color: AppColors.textPrimary, size: 16.sp),
  //         SizedBox(width: AppSize.w(6)),
  //         Text(
  //           'Call logs',
  //           style: GoogleFonts.poppins(
  //             fontSize: 13.sp,
  //             fontWeight: FontWeight.w500,
  //             color: AppColors.textPrimary,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ─── Search Bar ──────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w(16)),
      child: Container(
        height: AppSize.h(44),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.textSecondary,
              size: 20.sp,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: AppSize.h(12)),
          ),
        ),
      ),
    );
  }

  // ─── Section Label ───────────────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w(16)),
      child: Text(label, style: AppTextStyles.subHeading),
    );
  }

  // ─── Activities Row ──────────────────────
  Widget _buildActivitiesRow() {
    if (_isOnlineLoading) {
      return SizedBox(
        height: AppSize.h(90),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppSize.w(16)),
          itemCount: 4,
          itemBuilder: (_, _) => Padding(
            padding: EdgeInsets.only(right: AppSize.w(16)),
            child: Column(
              children: [
                Container(
                  width: AppSize.w(60),
                  height: AppSize.h(60),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                SizedBox(height: AppSize.h(6)),
                Container(
                  width: AppSize.w(40),
                  height: AppSize.h(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Always show available online users + See More button at the end
    final int count = _onlineUsers.length + 1;

    return SizedBox(
      height: AppSize.h(90),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSize.w(16)),
        itemCount: count,
        itemBuilder: (_, i) {
          if (i == _onlineUsers.length) {
            return _seeMoreButton();
          }
          return _userOnlineAvatar(_onlineUsers[i]);
        },
      ),
    );
  }

  Widget _seeMoreButton() {
    return Padding(
      padding: EdgeInsets.only(right: AppSize.w(16)),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Get.to(() => const Activeuser(initialTab: 0));
            },
            child: Container(
              width: AppSize.w(60),
              height: AppSize.h(60),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 22.sp,
              ),
            ),
          ),
          SizedBox(height: AppSize.h(6)),
          Text(
            'See More',
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _userOnlineAvatar(Map<String, dynamic> user) {
    final String fullName = (user["FullName"] ?? user["name"] ?? "User")
        .toString();
    final String? media = user["Media"]?.toString();

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

    return Padding(
      padding: EdgeInsets.only(right: AppSize.w(16)),
      child: GestureDetector(
        onTap: () {
          Get.to(
            () => BoomProfileScreen(
              userEmail:
                  user["EmailAddress"]?.toString() ?? user["email"]?.toString(),
              initialUserData: user,
            ),
            transition: Transition.rightToLeft,
          );
        },
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                /// 🔥 PROFILE IMAGE / INITIAL AVATAR
                Container(
                  width: AppSize.w(60),
                  height: AppSize.h(60),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: imageBytes != null
                        ? Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _avatarFallback(fullName),
                          )
                        : hasHttp
                        ? Image.network(
                            media!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _avatarFallback(fullName),
                          )
                        : _avatarFallback(fullName),
                  ),
                ),

                /// 🔥 ONLINE GREEN GLOWING DOT
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 16.w,
                    height: 16.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSize.h(6)),
            SizedBox(
              width: AppSize.w(60),
              child: Text(
                fullName.split(" ").first,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Messages List ───────────────────────
  Widget _buildMessagesList() {
    final list = _filteredMessages;

    if (list.isEmpty) {
      return Center(
        child: Text('No messages found', style: AppTextStyles.body),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w(16)),
      itemCount: list.length,
      separatorBuilder: (_, _) =>
          Divider(color: const Color(0xFF2A2A2A), height: 1, thickness: 1),
      itemBuilder: (context, index) {
        final msg = list[index];
        return _messageTile(context, msg, index);
      },
    );
  }

  Widget _messageTile(BuildContext context, MessageModel msg, int index) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MessageDetailPage(index: index, messageData: msg.toMap()),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSize.h(12)),
        child: Row(
          children: [
            // Avatar
            Container(
              width: AppSize.w(52),
              height: AppSize.h(52),
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: Image.network(
                  msg.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _avatarFallback(msg.name),
                ),
              ),
            ),
            SizedBox(width: AppSize.w(12)),

            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  /// 🔥 NAME
                  Text(
                    msg.name,

                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),

                  SizedBox(height: AppSize.h(4)),

                  /// 🔥 LAST MESSAGE
                  Text(
                    msg.message,

                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSize.h(2)),

                  /// 🔥 LAST SEEN
                  Text(
                    "Last seen 2 min ago",

                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Time + unread badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  msg.timestamp,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (msg.unreadCount > 0) ...[
                  SizedBox(height: AppSize.h(4)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSize.w(7),
                      vertical: AppSize.h(2),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '${msg.unreadCount}',
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Avatar Fallback ─────────────────────
  Widget _avatarFallback(String name) {
    final String initial = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : 'U';
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
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
