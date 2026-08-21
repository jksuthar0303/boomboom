import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xml/xml.dart' as xml;

import '../backend/home_service.dart';
import '../backend/registerservice.dart';
import '../backend/secure_storage.dart';
import '../constant/appsize.dart';
import '../constant/apptextstyle.dart';
import '../constant/colors.dart';
import 'boomboom.dart';
import 'messagedetail.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  static MessagePageState? state;

  static void refreshChats() {
    state?._loadAll();
  }

  @override
  State<MessagePage> createState() => MessagePageState();
}

class MessagePageState extends State<MessagePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int _selectedTab = 0; // 0: Chats, 1: Pending

  List<Map<String, dynamic>> _onlineUsers = [];
  bool _isOnlineLoading = true;

  List<Map<String, dynamic>> _chatList = [];
  bool _isChatLoading = true;

  List<Map<String, dynamic>> _pendingList = [];
  bool _isPendingLoading = true;

  String _myEmail = '';

  @override
  void initState() {
    super.initState();
    MessagePage.state = this;
    _loadAll();
  }

  @override
  void dispose() {
    if (MessagePage.state == this) {
      MessagePage.state = null;
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _myEmail = await SecureStorage().getUserEmail() ?? "";
    _fetchOnlineUsers();
    _fetchChatList();
    _fetchPendingChats();
  }

  Future<void> _fetchChatList() async {
    try {
      final email = _myEmail.isNotEmpty
          ? _myEmail
          : (await SecureStorage().getUserEmail() ?? "");
      if (email.trim().isEmpty) return;
      final response = await RegisterService().showChatList(
        email: email.trim(),
      );
      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        final res = doc.findAllElements('ShowChatListResult');
        if (res.isNotEmpty) {
          final Map<String, dynamic> jsonResult = jsonDecode(
            res.first.innerText,
          );
          if (jsonResult["Status"] == 1 && jsonResult["Data"] is List) {
            final List list = jsonResult["Data"];

            // Mark delivered for any incoming sent messages
            for (var item in list) {
              final sender = (item["Sender"] ?? item["Senderemail"] ?? "").toString().trim();
              final isMe = sender.isNotEmpty && sender.toLowerCase() == email.toLowerCase();
              final status = (item["MessageStatus"] ?? "").toString().toLowerCase().trim();
              if (!isMe && status == "sent") {
                final msgIdRaw = item["Id"] ?? item["MessageId"] ?? item["id"];
                final msgId = int.tryParse(msgIdRaw?.toString() ?? "");
                if (msgId != null && msgId > 0) {
                  RegisterService().messageDelivered(messageId: msgId, email: email);
                }
              }
            }

            if (mounted) {
              setState(() {
                _chatList = list
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList();
                _isChatLoading = false;
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("[MessagePage] Error fetching ShowChatList: $e");
    }
    if (mounted) {
      setState(() => _isChatLoading = false);
    }
  }

  Future<void> _fetchPendingChats() async {
    try {
      final email = _myEmail.isNotEmpty
          ? _myEmail
          : (await SecureStorage().getUserEmail() ?? "");
      if (email.trim().isEmpty) return;
      final response = await RegisterService().showPendingChats(
        email: email.trim(),
      );
      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        final res = doc.findAllElements('ShowPendingChatsResult');
        if (res.isNotEmpty) {
          final Map<String, dynamic> jsonResult = jsonDecode(
            res.first.innerText,
          );
          if (jsonResult["Status"] == 1 && jsonResult["Data"] is List) {
            final List list = jsonResult["Data"];
            if (mounted) {
              setState(() {
                _pendingList = list
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList();
                _isPendingLoading = false;
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("[MessagePage] Error fetching ShowPendingChats: $e");
    }
    if (mounted) {
      setState(() => _isPendingLoading = false);
    }
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

  Future<void> _handleAcceptChat(Map<String, dynamic> item) async {
    final chatListIdRaw = item["ChatListId"] ?? item["id"] ?? "0";
    final chatListId = int.tryParse(chatListIdRaw.toString()) ?? 0;
    final email = _myEmail.isNotEmpty
        ? _myEmail
        : (await SecureStorage().getUserEmail() ?? "");

    try {
      final response = await RegisterService().acceptChat(
        chatListId: chatListId,
        email: email.trim(),
      );
      if (response.statusCode == 200) {
        Get.snackbar(
          'Accepted',
          'Chat request accepted!',
          backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.8),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        _fetchPendingChats();
        _fetchChatList();
      }
    } catch (e) {
      debugPrint("[MessagePage] Error accepting chat: $e");
    }
  }

  Future<void> _handleRejectChat(Map<String, dynamic> item) async {
    final chatListIdRaw = item["ChatListId"] ?? item["id"] ?? "0";
    final chatListId = int.tryParse(chatListIdRaw.toString()) ?? 0;
    final email = _myEmail.isNotEmpty
        ? _myEmail
        : (await SecureStorage().getUserEmail() ?? "");

    try {
      final response = await RegisterService().rejectChat(
        chatListId: chatListId,
        email: email.trim(),
      );
      if (response.statusCode == 200) {
        Get.snackbar(
          'Declined',
          'Chat request declined',
          backgroundColor: const Color(0xFFFF4D4D).withValues(alpha: 0.8),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        _fetchPendingChats();
        _fetchChatList();
      }
    } catch (e) {
      debugPrint("[MessagePage] Error rejecting chat: $e");
    }
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
        SizedBox(height: AppSize.h(16)),
        _buildSectionLabel('Online Now'),
        SizedBox(height: AppSize.h(10)),
        _buildActivitiesRow(),
        SizedBox(height: AppSize.h(16)),
        _buildTabBar(),
        SizedBox(height: AppSize.h(8)),
        Expanded(
          child: _selectedTab == 0 ? _buildChatsTab() : _buildPendingTab(),
        ),
      ],
    );
  }

  // ─── Tablet Layout ───────────────────────
  Widget _buildTabletLayout() {
    return Row(
      children: [
        SizedBox(
          width: 380.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSearchBar(),
              SizedBox(height: AppSize.h(16)),
              _buildSectionLabel('Online Now'),
              SizedBox(height: AppSize.h(10)),
              _buildActivitiesRow(),
              SizedBox(height: AppSize.h(16)),
              _buildTabBar(),
              SizedBox(height: AppSize.h(8)),
              Expanded(
                child:
                    _selectedTab == 0 ? _buildChatsTab() : _buildPendingTab(),
              ),
            ],
          ),
        ),
        Container(width: 1, color: const Color(0xFF2A2A2A)),
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
        vertical: AppSize.h(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Messages', style: AppTextStyles.heading),
        ],
      ),
    );
  }

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

  // ─── Activities Row (Online Users) ───────
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

    if (_onlineUsers.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSize.w(16)),
        child: Container(
          width: double.infinity,
          height: AppSize.h(48),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 18.sp,
                color: Colors.white60,
              ),
              SizedBox(width: 8.w),
              Text(
                'No people online',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.white60,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final int count = _onlineUsers.length;

    return SizedBox(
      height: AppSize.h(90),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSize.w(16)),
        itemCount: count,
        itemBuilder: (_, i) {
          return _userOnlineAvatar(_onlineUsers[i]);
        },
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

  // ─── TAB BAR (Chats vs Pending) ──────────
  Widget _buildTabBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w(16)),
      child: Container(
        height: AppSize.h(42),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(22.r),
        ),
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            // Chats Tab
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_selectedTab != 0) {
                    setState(() => _selectedTab = 0);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _selectedTab == 0
                        ? AppColors.accent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Chats',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: _selectedTab == 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: _selectedTab == 0
                              ? Colors.white
                              : Colors.white60,
                        ),
                      ),
                      if (_chatList.isNotEmpty) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            '${_chatList.length}',
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Pending Tab
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_selectedTab != 1) {
                    setState(() => _selectedTab = 1);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _selectedTab == 1
                        ? AppColors.accent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pending',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: _selectedTab == 1
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: _selectedTab == 1
                              ? Colors.white
                              : Colors.white60,
                        ),
                      ),
                      if (_pendingList.isNotEmpty) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5252),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            '${_pendingList.length}',
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CHATS TAB ───────────────────────────
  Widget _buildChatsTab() {
    if (_isChatLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF9B59B6),
          strokeWidth: 2.5,
        ),
      );
    }

    final query = _searchQuery.toLowerCase().trim();
    final myEmailLower = _myEmail.trim().toLowerCase();
    final list = _chatList.where((item) {
      final sender = (item["Sender"] ?? "").toString().trim().toLowerCase();
      final receiver =
          (item["Reciever"] ?? item["Receiver"] ?? "").toString().trim().toLowerCase();
      final chatStatus =
          (item["ChatStatus"] ?? "").toString().trim().toLowerCase();

      // If this is a pending request received by me, it belongs ONLY in the Pending tab, not in Chats!
      if (chatStatus == "pending" &&
          receiver == myEmailLower &&
          sender != myEmailLower) {
        return false;
      }

      if (query.isEmpty) return true;
      final otherUser = (item["OtherUser"] ??
              item["Sender"] ??
              item["Reciever"] ??
              "")
          .toString()
          .toLowerCase();
      final name = (item["FullName"] ?? item["name"] ?? "")
          .toString()
          .toLowerCase();
      final status = (item["ChatMessage"] ?? item["ChatStatus"] ?? "")
          .toString()
          .toLowerCase();
      return otherUser.contains(query) ||
          name.contains(query) ||
          status.contains(query);
    }).toList();

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white38,
                size: 40.sp,
              ),
              SizedBox(height: 12.h),
              Text(
                "No chats found",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchChatList();
        await _fetchOnlineUsers();
      },
      color: const Color(0xFF9B59B6),
      backgroundColor: AppColors.primary,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: AppSize.w(16)),
        itemCount: list.length,
        separatorBuilder: (_, _) =>
            Divider(color: const Color(0xFF2A2A2A), height: 1, thickness: 1),
        itemBuilder: (context, index) {
          final item = list[index];
          return _apiChatTile(context, item, index);
        },
      ),
    );
  }

  // ─── PENDING TAB ─────────────────────────
  Widget _buildPendingTab() {
    if (_isPendingLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF9B59B6),
          strokeWidth: 2.5,
        ),
      );
    }

    final query = _searchQuery.toLowerCase().trim();
    final list = _pendingList.where((item) {
      if (query.isEmpty) return true;
      final otherUser = (item["OtherUser"] ??
              item["Sender"] ??
              item["Reciever"] ??
              "")
          .toString()
          .toLowerCase();
      final name = (item["FullName"] ?? item["name"] ?? "")
          .toString()
          .toLowerCase();
      final status = (item["ChatMessage"] ?? item["ChatStatus"] ?? "")
          .toString()
          .toLowerCase();
      return otherUser.contains(query) ||
          name.contains(query) ||
          status.contains(query);
    }).toList();

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mark_chat_unread_outlined,
                color: Colors.white38,
                size: 40.sp,
              ),
              SizedBox(height: 12.h),
              Text(
                "No pending chats found",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchPendingChats();
        await _fetchOnlineUsers();
      },
      color: const Color(0xFF9B59B6),
      backgroundColor: AppColors.primary,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: AppSize.w(16)),
        itemCount: list.length,
        separatorBuilder: (_, _) =>
            Divider(color: const Color(0xFF2A2A2A), height: 1, thickness: 1),
        itemBuilder: (context, index) {
          final item = list[index];
          return _apiPendingChatTile(context, item, index);
        },
      ),
    );
  }

  String _formatChatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty || rawDate.toLowerCase() == "null") {
      return "now";
    }
    try {
      DateTime? dt;
      if (rawDate.contains("/Date(") && rawDate.contains(")/")) {
        final numStr = rawDate.replaceAll(RegExp(r'[^\d]'), '');
        if (numStr.isNotEmpty) {
          final millis = int.tryParse(numStr);
          if (millis != null) {
            dt = DateTime.fromMillisecondsSinceEpoch(millis);
          }
        }
      } else {
        dt = DateTime.tryParse(rawDate);
      }
      if (dt != null) {
        final now = DateTime.now();
        final diff = now.difference(dt);
        if (diff.inMinutes < 1) {
          return 'now';
        } else if (diff.inHours < 1) {
          return '${diff.inMinutes}m ago';
        } else if (diff.inDays < 1 && now.day == dt.day) {
          final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
          final m = dt.minute.toString().padLeft(2, '0');
          final ampm = dt.hour >= 12 ? 'PM' : 'AM';
          return '$h:$m $ampm';
        } else if (diff.inDays < 2 && now.day - dt.day == 1) {
          return 'yesterday';
        } else if (diff.inDays < 7) {
          return '${diff.inDays}d ago';
        } else {
          return '${dt.day}/${dt.month}/${dt.year}';
        }
      }
    } catch (_) {}
    return rawDate;
  }

  // ─── CHAT TILE (Chats tab) ───────────────
  Widget _apiChatTile(
    BuildContext context,
    Map<String, dynamic> item,
    int index,
  ) {
    final myEmail = _myEmail.trim().toLowerCase();
    final sender = (item["Sender"] ?? item["Senderemail"] ?? item["SenderEmail"] ?? "").toString().trim();
    final receiver = (item["Reciever"] ?? item["RecieverEmail"] ?? item["Receiver"] ?? "").toString().trim();
    final senderLower = sender.toLowerCase();
    final receiverLower = receiver.toLowerCase();

    final bool isMeSender = myEmail.isNotEmpty && senderLower == myEmail;
    final bool isMeReceiver = myEmail.isNotEmpty && receiverLower == myEmail;

    final otherUser = (item["OtherUser"] ??
            (isMeSender ? receiver : (isMeReceiver ? sender : (sender.isNotEmpty ? sender : receiver))))
        .toString()
        .trim();

    String name = "";
    if (isMeSender) {
      name = (item["RecieverName"] ?? item["ReceiverName"] ?? item["Receivername"] ?? "").toString().trim();
    } else if (isMeReceiver) {
      name = (item["SenderName"] ?? item["Sendername"] ?? "").toString().trim();
    }
    if (name.isEmpty || name.toLowerCase() == "null") {
      name = (item["FullName"] ?? item["name"] ?? item["Name"] ?? "").toString().trim();
    }
    if (name.isEmpty || name.toLowerCase() == "null") {
      name = (otherUser.isNotEmpty ? otherUser.split("@").first : "User");
    }

    // Last message text: prioritize ChatMessage over status
    final chatMsg = (item["ChatMessage"] ?? item["Message"] ?? "").toString().trim();
    final lastMessage = chatMsg.isNotEmpty
        ? chatMsg
        : (item["ChatStatus"] == "Accepted" ? "Tap to chat" : (item["ChatStatus"] ?? "Tap to chat"));

    String img = "";
    if (isMeSender) {
      img = (item["RecieverImage"] ?? item["ReceiverImage"] ?? item["Receiverimage"] ?? "").toString().trim();
    } else if (isMeReceiver) {
      img = (item["SenderImage"] ?? item["Senderimage"] ?? "").toString().trim();
    }
    if (img.isEmpty || img.toLowerCase() == "null") {
      img = (item["Image"] ?? item["Media"] ?? item["image"] ?? item["ProfileImage"] ?? "").toString().trim();
    }

    final rawDate = item["MessageDateandTime"] ?? item["Date"] ?? item["Time"];
    final formattedTime = _formatChatDate(rawDate?.toString());

    final unreadRaw = item["UnreadCount"] ?? item["unread"] ?? "0";
    final int unreadCount = int.tryParse(unreadRaw.toString()) ?? 0;

    final onlineValue = (item["IsOnline"] ??
            item["isOnline"] ??
            item["Online"] ??
            item["online"] ??
            "")
        .toString()
        .trim()
        .toLowerCase();
    final bool isOnline = (onlineValue == "true" ||
            onlineValue == "1" ||
            onlineValue == "yes" ||
            onlineValue == "online") ||
        _onlineUsers.any((u) =>
            (u["email"] ??
                    u["Email"] ??
                    u["EmailAddress"] ??
                    u["OtherUser"] ??
                    "")
                .toString()
                .trim()
                .toLowerCase() ==
            otherUser.toLowerCase());

    final bool isSender =
        sender.isNotEmpty && sender.toLowerCase() == _myEmail.toLowerCase();
    final Map<String, String> messageMap = <String, String>{
      "name": name,
      "email": otherUser,
      "image": img,
      "message": lastMessage,
      "ChatListId":
          (item["ChatListId"] ?? item["Id"] ?? item["id"] ?? "0").toString(),
      "Sender": sender,
      "Reciever": receiver,
      "SenderName": (item["SenderName"] ?? "").toString(),
      "RecieverName": (item["RecieverName"] ?? item["ReceiverName"] ?? "").toString(),
      "SenderImage": (item["SenderImage"] ?? "").toString(),
      "RecieverImage": (item["RecieverImage"] ?? item["ReceiverImage"] ?? "").toString(),
      "isSender": isSender.toString(),
      "isOnline": isOnline.toString(),
      "status": (item["ChatStatus"] ?? "").toString(),
    };

    return InkWell(
      onTap: () {
        MessageDetailPage.show(
          context,
          index: index,
          messageData: messageMap,
        );
      },
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSize.h(12)),
        child: Row(
          children: [
            // Avatar + Online Indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: AppSize.w(52),
                  height: AppSize.h(52),
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: img.isNotEmpty &&
                            (img.startsWith("http://") ||
                                img.startsWith("https://"))
                        ? Image.network(
                            img,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _avatarFallback(name),
                          )
                        : _avatarFallback(name),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14.w,
                      height: 14.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: AppSize.w(12)),

            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: AppSize.h(3)),
                  Text(
                    lastMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: unreadCount > 0
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight:
                          unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Time + unread badge / pending badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  formattedTime,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: unreadCount > 0
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    fontWeight:
                        unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                SizedBox(height: AppSize.h(4)),
                if (unreadCount > 0)
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
                      '$unreadCount',
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  )
                else if (item["ChatStatus"] == "Pending")
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSize.w(7),
                      vertical: AppSize.h(2),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      'Pending',
                      style: GoogleFonts.poppins(
                        fontSize: 9.sp,
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── PENDING CHAT TILE (Pending tab with Accept / Decline action UI) ──
  Widget _apiPendingChatTile(
    BuildContext context,
    Map<String, dynamic> item,
    int index,
  ) {
    final myEmail = _myEmail.trim().toLowerCase();
    final sender = (item["Sender"] ?? item["Senderemail"] ?? item["SenderEmail"] ?? "").toString().trim();
    final receiver = (item["Reciever"] ?? item["RecieverEmail"] ?? item["Receiver"] ?? "").toString().trim();
    final senderLower = sender.toLowerCase();
    final receiverLower = receiver.toLowerCase();

    final bool isMeSender = myEmail.isNotEmpty && senderLower == myEmail;
    final bool isMeReceiver = myEmail.isNotEmpty && receiverLower == myEmail;

    final otherUser = (item["OtherUser"] ??
            (isMeSender ? receiver : (isMeReceiver ? sender : (sender.isNotEmpty ? sender : receiver))))
        .toString()
        .trim();

    String name = "";
    if (isMeSender) {
      name = (item["RecieverName"] ?? item["ReceiverName"] ?? item["Receivername"] ?? "").toString().trim();
    } else if (isMeReceiver) {
      name = (item["SenderName"] ?? item["Sendername"] ?? "").toString().trim();
    }
    if (name.isEmpty || name.toLowerCase() == "null") {
      name = (item["FullName"] ?? item["name"] ?? item["Name"] ?? "").toString().trim();
    }
    if (name.isEmpty || name.toLowerCase() == "null") {
      name = (otherUser.isNotEmpty ? otherUser.split("@").first : "User");
    }

    final status =
        (item["ChatMessage"] ?? item["ChatStatus"] ?? "Pending request")
            .toString();

    String img = "";
    if (isMeSender) {
      img = (item["RecieverImage"] ?? item["ReceiverImage"] ?? item["Receiverimage"] ?? "").toString().trim();
    } else if (isMeReceiver) {
      img = (item["SenderImage"] ?? item["Senderimage"] ?? "").toString().trim();
    }
    if (img.isEmpty || img.toLowerCase() == "null") {
      img = (item["Image"] ?? item["Media"] ?? item["image"] ?? item["ProfileImage"] ?? "").toString().trim();
    }

    final bool isSender =
        sender.isNotEmpty && sender.toLowerCase() == _myEmail.toLowerCase();
    final Map<String, String> messageMap = <String, String>{
      "name": name,
      "email": otherUser,
      "image": img,
      "message": status,
      "ChatListId": (item["ChatListId"] ?? item["id"] ?? "0").toString(),
      "Sender": sender,
      "Reciever": receiver,
      "SenderName": (item["SenderName"] ?? "").toString(),
      "RecieverName": (item["RecieverName"] ?? item["ReceiverName"] ?? "").toString(),
      "SenderImage": (item["SenderImage"] ?? "").toString(),
      "RecieverImage": (item["RecieverImage"] ?? item["ReceiverImage"] ?? "").toString(),
      "isSender": isSender.toString(),
      "status": "Pending",
    };

    return InkWell(
      onTap: () {
        MessageDetailPage.show(
          context,
          index: index,
          messageData: messageMap,
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
                child: img.isNotEmpty &&
                        (img.startsWith("http://") || img.startsWith("https://"))
                    ? Image.network(
                        img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _avatarFallback(name),
                      )
                    : _avatarFallback(name),
              ),
            ),
            SizedBox(width: AppSize.w(12)),

            // Name + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: AppSize.h(4)),
                  Text(
                    status,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Accept / Decline action UI buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Decline button
                GestureDetector(
                  onTap: () => _handleRejectChat(item),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF4D4D),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'Decline',
                        style: GoogleFonts.poppins(
                          fontSize: 9.sp,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                // Accept button
                GestureDetector(
                  onTap: () => _handleAcceptChat(item),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00E676),
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'Accept',
                        style: GoogleFonts.poppins(
                          fontSize: 9.sp,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
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
