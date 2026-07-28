import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../constant/appsize.dart';
import '../constant/colors.dart';
import '../model/messagedetails.dart';

// ═══════════════════════════════════════════
// 🔥 STATIC METHOD TO OPEN AS DRAGGABLE SHEET
// Jahan se bhi call karo — bas ye use karo:
//
//   MessageDetailPage.show(context,
//     index: index,
//     messageData: messageData,
//   );
// ═══════════════════════════════════════════
class MessageDetailPage extends StatefulWidget {
  final int index;
  final Map<String, String> messageData;
  final ScrollController? sheetScrollController;

  const MessageDetailPage({
    super.key,
    required this.index,
    required this.messageData,
    this.sheetScrollController,
  });

  // ─────────────────────────────────────────
  // 🔥 STATIC SHOW METHOD
  // Star click pe sirf ye call karo
  // ─────────────────────────────────────────
  static Future<void> show(
    BuildContext context, {
    required int index,
    required Map<String, String> messageData,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          expand: false,
          snap: true,
          snapSizes: const [0.5, 1.0],
          builder: (ctx, scrollController) {
            return ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28.r),
                topRight: Radius.circular(28.r),
              ),
              child: MessageDetailPage(
                index: index,
                messageData: messageData,
                sheetScrollController: scrollController,
              ),
            );
          },
        );
      },
    );
  }

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _showSend = false;
  bool _showEmojiPicker = false;

  // ─── Popular emojis list ───
  static const List<String> _emojis = [
    '😀',
    '😂',
    '🥰',
    '😍',
    '😎',
    '🥳',
    '😢',
    '😭',
    '😡',
    '🤩',
    '🫶',
    '❤️',
    '🔥',
    '👍',
    '👎',
    '🙏',
    '💪',
    '🤝',
    '✌️',
    '🫂',
    '😘',
    '🤗',
    '😴',
    '🤔',
    '😏',
    '🥺',
    '😜',
    '🤣',
    '😇',
    '🫠',
    '🌹',
    '🎉',
    '🎊',
    '💯',
    '⭐',
    '🌟',
    '💫',
    '✨',
    '🎶',
    '🎵',
    '🍕',
    '🍔',
    '🍷',
    '🥂',
    '☕',
    '🎂',
    '🍫',
    '🍭',
    '🌈',
    '🌙',
    '👀',
    '💋',
    '💍',
    '💎',
    '👑',
    '🏆',
    '🎯',
    '💰',
    '🤑',
    '💸',
  ];

  // ─────────────────────────────────────────
  // 🔥 INIT STATE
  // ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  final List<ChatMessage> _chats = [
    const ChatMessage(
      text: 'Hi',
      isMe: true,
      time: '5:02 PM',
      status: MessageStatus.read,
    ),
  ];

  // ─────────────────────────────────────────
  // 🔥 CHECK RESTRICTED INFO
  // ─────────────────────────────────────────
  bool _containsRestrictedInfo(String text) {
    final lower = text.toLowerCase().trim();

    final phoneRegex = RegExp(r'(?:\+91[\-\s]?)?[6-9]\d{9}');
    final instaRegex = RegExp(r'(instagram|insta|ig|@[\w._]+)');
    final whatsappRegex = RegExp(r'(whatsapp|wa\.me|wa me|whats app)');
    final upiRegex = RegExp(
      r'[\w.\-]{2,}@(paytm|ybl|ibl|axl|oksbi|okaxis|okhdfcbank|upi)',
    );
    final paymentRegex = RegExp(
      r'(paytm|gpay|google pay|phonepe|paypal|cashapp|bank account|account number|ifsc|payment)',
    );
    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+');

    return phoneRegex.hasMatch(lower) ||
        instaRegex.hasMatch(lower) ||
        whatsappRegex.hasMatch(lower) ||
        upiRegex.hasMatch(lower) ||
        paymentRegex.hasMatch(lower) ||
        emailRegex.hasMatch(lower);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // 🔥 SEND
  // ─────────────────────────────────────────
  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;

    if (_containsRestrictedInfo(t)) {
      _showSafetySheet(
        onContinue: () {
          Navigator.pop(context);
          _sendMessage(t);
        },
      );
      return;
    }

    _sendMessage(t);
  }

  // ─────────────────────────────────────────
  // 🔥 SAFETY SHEET
  // ─────────────────────────────────────────
  void _showSafetySheet({required VoidCallback onContinue}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 80.h,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 285.w,
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              padding: EdgeInsets.all(11.w),
              decoration: BoxDecoration(
                color: const Color(0xFF111217),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38.w,
                      height: 3.5.h,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFC107,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.shield_rounded,
                            color: const Color(0xFFFFC107),
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Stay Safe From\nScammers",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.sp,
                                  height: 1.25,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                "Stay alert while sharing personal information with new people.",
                                style: GoogleFonts.poppins(
                                  color: Colors.white60,
                                  fontSize: 8.8.sp,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 28.w,
                            height: 28.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white70,
                              size: 15.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Divider(color: Colors.white10),
                    SizedBox(height: 8.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Please be careful before sharing:",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: _safetyItem(
                            icon: Icons.call_rounded,
                            title: "Phone Number",
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 7.w),
                        Expanded(
                          child: _safetyItem(
                            icon: Icons.language_rounded,
                            title: "Social Media Accounts",
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Expanded(
                          child: _safetyItem(
                            icon: Icons.location_on_rounded,
                            title: "Live Location",
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(width: 7.w),
                        Expanded(
                          child: _safetyItem(
                            icon: Icons.credit_card_rounded,
                            title: "Payment or Bank Details",
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    _fullSafetyItem(
                      icon: Icons.lock_rounded,
                      title: "OTP / Verification Codes",
                      color: Colors.lightBlueAccent,
                    ),
                    SizedBox(height: 8.h),
                    Divider(color: Colors.white10),
                    SizedBox(height: 8.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.cancel_rounded,
                          color: Colors.redAccent,
                          size: 16.sp,
                        ),
                        SizedBox(width: 7.w),
                        Expanded(
                          child: Text(
                            "Never send money to someone you don't fully trust.",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10.sp,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Divider(color: Colors.white10),
                    SizedBox(height: 8.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          color: Colors.blueAccent,
                          size: 18.sp,
                        ),
                        SizedBox(width: 7.w),
                        Expanded(
                          child: Text(
                            "For your safety, continue chatting inside the app until you feel comfortable.",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10.sp,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      height: 38.h,
                      child: ElevatedButton(
                        onPressed: onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B5CE6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Continue Chat Anyway",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // 🔥 SAFETY ITEM (small box)
  // ─────────────────────────────────────────
  Widget _safetyItem({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🔥 SAFETY ITEM (full width)
  // ─────────────────────────────────────────
  Widget _fullSafetyItem({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          SizedBox(width: 10.w),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🔥 SEND MESSAGE
  // ─────────────────────────────────────────
  void _sendMessage(String t) {
    setState(() {
      _chats.add(
        ChatMessage(
          text: t,
          isMe: true,
          time: _nowStr(),
          status: MessageStatus.sent,
        ),
      );
      _ctrl.clear();
      _showSend = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─────────────────────────────────────────
  // 🔥 SEND CAMERA IMAGE
  // ─────────────────────────────────────────
  // Future<void> _sendImage() async {
  //   final XFile? image = await _picker.pickImage(
  //     source: ImageSource.camera,
  //     imageQuality: 70,
  //   );
  //   if (image == null) return;

  //   setState(() {
  //     _chats.add(
  //       ChatMessage(
  //         text: image.path,
  //         isMe: true,
  //         time: _nowStr(),
  //         status: MessageStatus.sent,
  //         isImage: true,
  //       ),
  //     );
  //   });

  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (_chatScroll.hasClients) {
  //       _chatScroll.animateTo(
  //         _chatScroll.position.maxScrollExtent,
  //         duration: const Duration(milliseconds: 280),
  //         curve: Curves.easeOut,
  //       );
  //     }
  //   });
  // }

  void _addImage(String path) {
    setState(() {
      _chats.add(
        ChatMessage(
          text: path,
          isMe: true,
          time: _nowStr(),
          status: MessageStatus.sent,
          isImage: true,
        ),
      );
    });
  }

  void _addVideo(String path) {
    setState(() {
      _chats.add(
        ChatMessage(
          text: path,
          isMe: true,
          time: _nowStr(),
          status: MessageStatus.sent,
          isVideo: true,
        ),
      );
    });
  }

  Future<void> _pickMedia() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111217),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.white),
                title: const Text(
                  "Camera Photo",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);

                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                  );

                  if (image != null) {
                    _addImage(image.path);
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.photo, color: Colors.white),
                title: const Text(
                  "Gallery Photo",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);

                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                  );

                  if (image != null) {
                    _addImage(image.path);
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.white),
                title: const Text(
                  "Gallery Video",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);

                  final XFile? video = await _picker.pickVideo(
                    source: ImageSource.gallery,
                  );

                  if (video != null) {
                    _addVideo(video.path);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _nowStr() {
    final t = TimeOfDay.now();
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? "AM" : "PM"}';
  }

  // ─────────────────────────────────────────
  // 🔥 BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final name = widget.messageData['name'] ?? 'User';
    final image = widget.messageData['image'] ?? '';
    final age = widget.messageData['age'] ?? '38';
    final city = widget.messageData['city'] ?? 'Ajman';
    final flag = widget.messageData['flag'] ?? '🇦🇪';
    final lastSeen = widget.messageData['lastSeen'] ?? '5 min ago';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // ─── DRAG HANDLE ───
          GestureDetector(
            onVerticalDragUpdate: widget.sheetScrollController != null
                ? (details) {}
                : null,
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Center(
                  child: Container(
                    width: 42.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
              ],
            ),
          ),

          SizedBox(height: 18.h),

          _ProfileCard(
            name: name,
            imageUrl: image,
            age: age,
            //gender: gender,
            city: city,
            flag: flag,
            lastSeen: lastSeen,
            onBack: () => Navigator.pop(context),
          ),

          Expanded(child: _chatArea()),
          _inputBar(name),
          if (_showEmojiPicker) _emojiPickerPanel(),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🔥 CHAT AREA
  // ─────────────────────────────────────────
  Widget _chatArea() {
    return ListView.builder(
      controller: widget.sheetScrollController ?? _chatScroll,
      padding: EdgeInsets.fromLTRB(
        AppSize.w(14),
        AppSize.h(10),
        AppSize.w(14),
        AppSize.h(6),
      ),
      itemCount: _chats.length,
      itemBuilder: (_, i) => _bubble(_chats[i]),
    );
  }

  // ─────────────────────────────────────────
  // 🔥 SINGLE BUBBLE
  // ─────────────────────────────────────────
  Widget _bubble(ChatMessage c) {
    final me = c.isMe;

    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: AppSize.h(8),
          left: me ? AppSize.w(72) : 0,
          right: me ? 0 : AppSize.w(72),
        ),
        child: Column(
          crossAxisAlignment: me
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: c.isImage
                  ? EdgeInsets.zero
                  : EdgeInsets.symmetric(
                      horizontal: AppSize.w(16),
                      vertical: AppSize.h(11),
                    ),
              decoration: BoxDecoration(
                color: c.isImage
                    ? Colors.transparent
                    : me
                    ? AppColors.purple
                    : AppColors.bubbleIn,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.r),
                  topRight: Radius.circular(18.r),
                  bottomLeft: Radius.circular(me ? 18.r : 4.r),
                  bottomRight: Radius.circular(me ? 4.r : 18.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (me ? AppColors.blue : Colors.black).withValues(
                      alpha: 0.25,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: c.isImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14.r),
                      child: Image.file(
                        File(c.text),
                        width: 180.w,
                        height: 230.h,
                        fit: BoxFit.cover,
                      ),
                    )
                  : c.isVideo
                  ? Container(
                      width: 180.w,
                      height: 230.h,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 60.sp,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "Video Selected",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      c.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
            ),
            SizedBox(height: AppSize.h(4)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.time,
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    color: AppColors.grey,
                  ),
                ),
                if (me) ...[SizedBox(width: AppSize.w(3)), _ticks(c.status)],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ticks(MessageStatus s) {
    final color = s == MessageStatus.read ? AppColors.blue : AppColors.grey;
    final icon = s == MessageStatus.sent
        ? Icons.check_rounded
        : Icons.done_all_rounded;
    return Icon(icon, size: 13.sp, color: color);
  }

  // ─────────────────────────────────────────
  // 🔥 INPUT BAR
  // ─────────────────────────────────────────
  Widget _inputBar(String name) {
    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w(12),
        vertical: AppSize.h(10),
      ),
      child: Row(
        children: [
          _circleBtn(icon: Icons.camera_alt_rounded, onTap: _pickMedia),
          SizedBox(width: AppSize.w(8)),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(color: AppColors.inputBorder),
              ),
              padding: EdgeInsets.symmetric(horizontal: AppSize.w(16)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onChanged: (v) {
                        setState(() => _showSend = v.trim().isNotEmpty);
                      },
                      onTap: () {
                        if (_showEmojiPicker) {
                          setState(() => _showEmojiPicker = false);
                        }
                      },
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Message $name...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: AppColors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: AppSize.h(12),
                        ),
                      ),
                    ),
                  ),
                  // ─── EMOJI BUTTON ───
                  GestureDetector(
                    onTap: () {
                      setState(() => _showEmojiPicker = !_showEmojiPicker);
                      if (_showEmojiPicker) FocusScope.of(context).unfocus();
                    },
                    child: Padding(
                      padding: EdgeInsets.only(left: AppSize.w(6)),
                      child: Text(
                        _showEmojiPicker ? '⌨️' : '😊',
                        style: TextStyle(fontSize: 22.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: AppSize.w(8)),

          if (!_showSend) ...[
            _circleBtn(
              key: const ValueKey('mic'),
              icon: Icons.mic_rounded,
              onTap: () {
                // Voice recording
              },
            ),

            SizedBox(width: AppSize.w(8)),

            _gifBtn(),
          ],

          if (_showSend)
            _circleBtn(
              key: const ValueKey('send'),
              icon: Icons.send_rounded,
              onTap: _send,
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🔥 EMOJI PICKER PANEL
  // ─────────────────────────────────────────
  Widget _emojiPickerPanel() {
    return Container(
      height: 240.h,
      color: AppColors.bg,
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w(8),
        vertical: AppSize.h(8),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 36.w,
            height: 3.5.h,
            margin: EdgeInsets.only(bottom: 8.h),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 4.w,
                mainAxisSpacing: 4.h,
                childAspectRatio: 1,
              ),
              itemCount: _emojis.length,
              itemBuilder: (_, i) {
                return GestureDetector(
                  onTap: () {
                    final pos = _ctrl.selection.isValid
                        ? _ctrl.selection.baseOffset
                        : _ctrl.text.length;
                    final newText =
                        _ctrl.text.substring(0, pos) +
                        _emojis[i] +
                        _ctrl.text.substring(pos);
                    _ctrl.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(
                        offset: pos + _emojis[i].length,
                      ),
                    );
                    setState(() => _showSend = newText.trim().isNotEmpty);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Center(
                      child: Text(
                        _emojis[i],
                        style: TextStyle(fontSize: 20.sp),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn({
    Key? key,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: AppSize.w(46),
        height: AppSize.h(46),
        decoration: const BoxDecoration(
          color: AppColors.blue,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22.sp),
      ),
    );
  }

  Widget _gifBtn({Key? key}) {
    return GestureDetector(
      key: key,
      onTap: () {},
      child: Container(
        width: AppSize.w(46),
        height: AppSize.h(46),
        decoration: BoxDecoration(
          color: AppColors.blue,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Center(
          child: Text(
            'GIF',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 🔥 PROFILE CARD
// ═══════════════════════════════════════════
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.imageUrl,
    required this.age,
    //required this.gender,
    required this.city,
    required this.flag,
    required this.lastSeen,
    required this.onBack,
  });

  final String name, imageUrl, age, city, flag, lastSeen;
  final VoidCallback onBack;

  static const _cardBg = Color(0xFF0F1017);
  static const _cardBorder = Color(0xFF1C1D2A);
  static const _blue = Color(0xFF2B5CE6);
  static const _green = Color(0xFF2ECC71);
  static const _grey = Color(0xFFAAAAAA);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        AppSize.w(12),
        AppSize.h(0),
        AppSize.w(12),
        AppSize.h(4),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w(12),
        vertical: AppSize.h(12),
      ),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── BACK BUTTON ───
          GestureDetector(
            onTap: onBack,
            child: Padding(
              padding: EdgeInsets.all(AppSize.w(6)),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22.sp,
              ),
            ),
          ),
          SizedBox(width: AppSize.w(6)),

          // ─── PHOTO ───
          _photo(),
          SizedBox(width: AppSize.w(12)),

          // ─── INFO ───
          Expanded(child: _info()),

          // ─── 3 DOT MENU ───
          GestureDetector(
            onTap: () => _showMoreMenu(context),
            child: Container(
              padding: EdgeInsets.all(AppSize.w(8)),
              decoration: BoxDecoration(
                color: const Color(0xFF181924),
                shape: BoxShape.circle,
                border: Border.all(color: _cardBorder),
              ),
              child: Icon(
                Icons.more_horiz_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🔥 3 DOT → BLOCK / REPORT MENU
  // ─────────────────────────────────────────
  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) {
        return Container(
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
          decoration: BoxDecoration(
            color: const Color(0xFF111217),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12.h),
                // Handle
                Container(
                  width: 38.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                SizedBox(height: 16.h),

                // ─── BLOCK ───
                _menuItem(
                  context: context,
                  icon: Icons.block_rounded,
                  label: 'Block $name',
                  color: Colors.orangeAccent,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmAction(
                      context,
                      title: 'Block $name?',
                      subtitle: 'They won\'t be able to message you anymore.',
                      actionLabel: 'Block',
                      color: Colors.orangeAccent,
                    );
                  },
                ),

                Divider(
                  color: Colors.white.withValues(alpha: 0.06),
                  height: 1,
                  indent: 16.w,
                  endIndent: 16.w,
                ),

                // ─── REPORT ───
                _menuItem(
                  context: context,
                  icon: Icons.flag_rounded,
                  label: 'Report $name',
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmAction(
                      context,
                      title: 'Report $name?',
                      subtitle: 'We\'ll review this profile and take action.',
                      actionLabel: 'Report',
                      color: Colors.redAccent,
                    );
                  },
                ),

                SizedBox(height: 8.h),

                // ─── CANCEL ───
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
                    width: double.infinity,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Menu Item Widget ───
  Widget _menuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38.w,
        height: 38.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: color, size: 20.sp),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── Confirm Dialog ───
  void _confirmAction(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String actionLabel,
    required Color color,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: const Color(0xFF111217),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: color, size: 40.sp),
              SizedBox(height: 12.h),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 12.sp,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: color.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            actionLabel,
                            style: GoogleFonts.poppins(
                              color: color,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: AppSize.w(74),
              height: AppSize.h(84),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: AppSize.w(74),
      height: AppSize.h(84),
      color: const Color(0xFF181924),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.poppins(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: _blue,
          ),
        ),
      ),
    );
  }

  Widget _info() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── NAME + VERIFIED ───
        SizedBox(height: AppSize.h(7)),
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: AppSize.w(6)),
            Icon(Icons.verified_rounded, color: _blue, size: 18.sp),
          ],
        ),
        SizedBox(height: AppSize.h(4)),

        // ─── AGE / GENDER / CITY / FLAG ───
        Row(
          children: [
            _meta(age),
            _sep(),
            //_meta(gender),
            _sep(),
            _meta(city),
            SizedBox(width: AppSize.w(4)),
            Text(flag, style: TextStyle(fontSize: 15.sp)),
          ],
        ),
        SizedBox(height: AppSize.h(6)),

        Row(
          children: [
            // 📍 Distance Badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSize.w(10),
                vertical: AppSize.h(5),
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orangeAccent, width: 0.5),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.orangeAccent,
                    size: 10.sp,
                  ),
                  SizedBox(width: AppSize.w(4)),
                  Text(
                    '12 km',
                    style: GoogleFonts.poppins(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: AppSize.w(4)), // dono ke beech gap
            // 🟢 Online Badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSize.w(12),
                vertical: AppSize.h(5),
              ),
              decoration: BoxDecoration(
                border: Border.all(color: _green, width: 1.0),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: AppSize.w(3),
                    height: AppSize.h(5),
                    decoration: const BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: AppSize.w(3)),
                  Text(
                    lastSeen,
                    style: GoogleFonts.poppins(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w700,
                      color: _green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _meta(String t) => Text(
    t,
    style: GoogleFonts.poppins(fontSize: 10.sp, color: _grey),
  );

  Widget _sep() => Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSize.w(4)),
    child: Text(
      '•',
      style: TextStyle(fontSize: 10.sp, color: _grey),
    ),
  );
}
