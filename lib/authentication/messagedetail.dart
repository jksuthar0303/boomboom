import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';

import 'package:xml/xml.dart' as xml;

import '../backend/registerservice.dart';
import '../backend/secure_storage.dart';
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
  final DraggableScrollableController? draggableController;

  const MessageDetailPage({
    super.key,
    required this.index,
    required this.messageData,
    this.sheetScrollController,
    this.draggableController,
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
    final DraggableScrollableController sheetCtrl =
        DraggableScrollableController();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) {
        return DraggableScrollableSheet(
          controller: sheetCtrl,
          initialChildSize: 0.62,
          minChildSize: 0.50,
          maxChildSize: 1.0,
          expand: false,
          snap: true,
          snapSizes: const [0.62, 1.0],
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
                draggableController: sheetCtrl,
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
  final FocusNode _focusNode = FocusNode();
  final ScrollController _chatScroll = ScrollController();
  final ImagePicker _picker = ImagePicker();
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

  bool _isLoadingMessages = true;
  String? _blockMessage;
  bool _isSenderPending = false;
  final List<ChatMessage> _chats = [];
  final List<ChatMessage> _pendingLocalChats = [];
  Timer? _pollingTimer;
  bool _isPollingInProgress = false;
  int? _resolvedChatListId;

  // ─────────────────────────────────────────
  // 🔥 INIT STATE
  // ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        if (_showEmojiPicker) {
          setState(() => _showEmojiPicker = false);
        }
        if (widget.draggableController != null &&
            widget.draggableController!.isAttached) {
          widget.draggableController!.animateTo(
            1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
        Future.delayed(const Duration(milliseconds: 280), () {
          _scrollToBottom(animate: true);
        });
      }
    });
    _fetchChatMessages(isInitial: true);
    // Realtime polling every 500ms
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _fetchChatMessages(isInitial: false);
    });
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scrollCtrl = widget.sheetScrollController ?? _chatScroll;
      if (scrollCtrl.hasClients) {
        if (animate) {
          scrollCtrl.animateTo(
            scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          );
        } else {
          scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
        }
      }
    });
  }

  Future<void> _fetchChatMessages({bool isInitial = false}) async {
    if (_isPollingInProgress) return;
    _isPollingInProgress = true;

    int chatListId = _resolvedChatListId ??
        int.tryParse((widget.messageData["ChatListId"] ??
                widget.messageData["chatListId"] ??
                widget.messageData["id"] ??
                "0")
            .toString()) ??
        0;

    final otherEmail = (widget.messageData["email"] ??
            widget.messageData["EmailAddress"] ??
            widget.messageData["ActionEmail"] ??
            widget.messageData["OtherUser"] ??
            "")
        .toString()
        .trim();

    try {
      final myEmail = await SecureStorage().getUserEmail() ?? "";

      // 🔥 If opened from profile with chatListId == 0, check if chat already exists in ShowChatList!
      if (chatListId <= 0 && otherEmail.isNotEmpty && myEmail.isNotEmpty) {
        try {
          final listRes = await RegisterService().showChatList(email: myEmail.trim());
          if (listRes.statusCode == 200) {
            final listDoc = xml.XmlDocument.parse(listRes.body);
            final listElements = listDoc.findAllElements('ShowChatListResult');
            if (listElements.isNotEmpty) {
              final dynamic listJson = jsonDecode(listElements.first.innerText);
              if (listJson is Map && listJson["Status"] == 1 && listJson["Data"] is List) {
                final List data = listJson["Data"];
                for (var c in data) {
                  final cOther = (c["OtherUser"] ?? c["Sender"] ?? c["Reciever"] ?? c["Email"] ?? "")
                      .toString()
                      .trim()
                      .toLowerCase();
                  if (cOther == otherEmail.toLowerCase()) {
                    final foundId = int.tryParse((c["ChatListId"] ?? c["Id"] ?? c["id"] ?? "0").toString()) ?? 0;
                    if (foundId > 0) {
                      chatListId = foundId;
                      _resolvedChatListId = foundId;
                      break;
                    }
                  }
                }
              }
            }
          }
        } catch (_) {}
      }

      // If still new conversation, allow typing directly
      if (chatListId <= 0) {
        if (mounted) {
          setState(() {
            _isLoadingMessages = false;
            _blockMessage = null;
          });
        }
        _isPollingInProgress = false;
        return;
      }

      final targetEmail = otherEmail.isNotEmpty ? otherEmail : myEmail;

      final response = await RegisterService().showChatMessages(
        chatListId: chatListId,
        email: targetEmail.trim(),
      );

      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        final res = doc.findAllElements('ShowChatMessagesResult');
        if (res.isNotEmpty) {
          final Map<String, dynamic> jsonResult = jsonDecode(
            res.first.innerText,
          );

          if (jsonResult["Status"] == 0) {
            final String rawApiMsg = (jsonResult["Message"] ??
                    (jsonResult["Data"] is Map ? jsonResult["Data"]["Message"] : null) ??
                    "")
                .toString()
                .trim();

            final bool isBlocked = rawApiMsg.toLowerCase().contains("block");

            final sender = (widget.messageData["Sender"] ??
                    widget.messageData["SenderEmail"] ??
                    widget.messageData["sender"] ??
                    "")
                .toString()
                .trim();
            final bool isMeSender = sender.isNotEmpty
                ? sender.toLowerCase() == myEmail.toLowerCase()
                : (widget.messageData["isSender"] == "true");

            final String msg;
            if (rawApiMsg.isNotEmpty && rawApiMsg.toLowerCase() != "null") {
              msg = rawApiMsg;
            } else if (isMeSender) {
              msg = "Waiting for user to accept your chat request";
            } else {
              msg = "Please accept the chat request first.";
            }

            if (mounted && (_blockMessage != msg || _isLoadingMessages)) {
              setState(() {
                _blockMessage = msg;
                _isSenderPending = !isBlocked && isMeSender;
                _isLoadingMessages = false;
              });
            }
            _isPollingInProgress = false;
            return;
          } else if (jsonResult["Status"] == 1 && jsonResult["Data"] is List) {
            final List list = jsonResult["Data"];
            final List<ChatMessage> loadedChats = [];
            for (var item in list) {
              final sender = (item["SenderEmail"] ?? item["Sender"] ?? item["Senderemail"] ?? "")
                  .toString()
                  .trim();
              final isMe = myEmail.isNotEmpty &&
                  sender.toLowerCase() == myEmail.toLowerCase();
              final text =
                  (item["ChatMessage"] ?? item["Message"] ?? "").toString();
              final rawTime = item["MessageDateandTime"] ??
                  item["Time"] ??
                  item["Date"] ??
                  item["CreatedDate"];
              final time = _formatMessageTime(rawTime?.toString());

              final msgStatusRaw = (item["MessageStatus"] ?? "").toString().toLowerCase().trim();
              final isReadVal = item["IsRead"] ?? item["isRead"] ?? item["Isread"];
              final isDeliveredVal = item["IsDelivered"] ?? item["isDelivered"] ?? item["Isdelivered"];

              MessageStatus status;
              if (isReadVal == 1 || isReadVal == "1" || isReadVal == true || isReadVal == "true" || msgStatusRaw == "read") {
                status = MessageStatus.read;
              } else if (isDeliveredVal == 1 || isDeliveredVal == "1" || isDeliveredVal == true || isDeliveredVal == "true" || msgStatusRaw == "delivered") {
                status = MessageStatus.delivered;
              } else {
                status = MessageStatus.sent;
              }

              // If this message was sent to me and is not yet marked read, mark it read via API
              if (!isMe) {
                final messageIdRaw = item["Id"] ?? item["MessageId"] ?? item["id"];
                final messageId = int.tryParse(messageIdRaw?.toString() ?? "");
                if (messageId != null && messageId > 0 && status != MessageStatus.read) {
                  RegisterService().messageRead(messageId: messageId, email: myEmail);
                }
              }

              if (text.isNotEmpty) {
                loadedChats.add(
                  ChatMessage(
                    text: text,
                    isMe: isMe,
                    time: time,
                    status: status,
                  ),
                );
              }
            }

            // Remove server-confirmed messages from local pending list
            _pendingLocalChats.removeWhere((pending) =>
                loadedChats.any((s) => s.isMe && s.text.trim() == pending.text.trim()));

            final combinedChats = List<ChatMessage>.from(loadedChats);
            // Append any pending local messages that server has not returned yet
            combinedChats.addAll(_pendingLocalChats);

            // Detect if count, text, or tick status changed
            final bool hasChanged = combinedChats.length != _chats.length ||
                combinedChats.asMap().entries.any((entry) {
                  final i = entry.key;
                  if (i >= _chats.length) return true;
                  return entry.value.status != _chats[i].status ||
                      entry.value.text != _chats[i].text;
                });

            if (mounted && (hasChanged || isInitial || _isLoadingMessages || _blockMessage != null)) {
              setState(() {
                _chats.clear();
                _chats.addAll(combinedChats);
                _blockMessage = null;
                _isLoadingMessages = false;
              });
              _scrollToBottom(animate: !isInitial);
            }
            _isPollingInProgress = false;
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("[MessageDetailPage] Error fetching messages: $e");
    }

    _isPollingInProgress = false;
    if (mounted && _isLoadingMessages) {
      setState(() => _isLoadingMessages = false);
    }
  }

  String _formatMessageTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty || rawDate.toLowerCase() == "null") {
      return _nowStr();
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
        final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final m = dt.minute.toString().padLeft(2, '0');
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        return '$h:$m $ampm';
      }
    } catch (_) {}
    return rawDate;
  }

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
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _focusNode.dispose();
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
  void _sendMessage(String t) async {
    final receiverEmail = widget.messageData["email"] ??
        widget.messageData["EmailAddress"] ??
        widget.messageData["ActionEmail"] ??
        "";

    final localMsg = ChatMessage(
      text: t,
      isMe: true,
      time: _nowStr(),
      status: MessageStatus.sent,
    );

    setState(() {
      _pendingLocalChats.add(localMsg);
      _chats.add(localMsg);
      _ctrl.clear();
    });

    _scrollToBottom(animate: true);

    if (receiverEmail.trim().isNotEmpty) {
      try {
        final senderEmail = await SecureStorage().getUserEmail() ?? "";
        if (senderEmail.trim().isNotEmpty) {
          final res = await RegisterService().sendChatMessage(
            senderEmail: senderEmail.trim(),
            receiverEmail: receiverEmail.trim(),
            chatMessage: t,
          );
          debugPrint("[MessageDetailPage] sendChatMessage response: ${res.statusCode} -> ${res.body}");
        }
      } catch (e) {
        debugPrint("[MessageDetailPage] Error sending chat message: $e");
      }
    }
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

  Future<void> _handleBlockUser() async {
    final chatListId = _resolvedChatListId ??
        int.tryParse((widget.messageData["ChatListId"] ??
                widget.messageData["chatListId"] ??
                widget.messageData["id"] ??
                "0")
            .toString()) ??
        0;

    try {
      final myEmail = await SecureStorage().getUserEmail() ?? "";
      if (myEmail.isNotEmpty) {
        await RegisterService().blockChatUser(
          chatListId: chatListId,
          email: myEmail.trim(),
        );
      }
      if (mounted) {
        Get.snackbar(
          'Blocked',
          'User has been blocked successfully',
          backgroundColor: const Color(0xFFFF5252).withValues(alpha: 0.85),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint("[MessageDetailPage] Error blocking user: $e");
    }
  }

  // ─────────────────────────────────────────
  // 🔥 BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    String name = (widget.messageData["name"] ??
            widget.messageData["FullName"] ??
            widget.messageData["Name"] ??
            "")
        .toString()
        .trim();
    String image = (widget.messageData["image"] ??
            widget.messageData["Image"] ??
            widget.messageData["Media"] ??
            widget.messageData["ProfileImage"] ??
            "")
        .toString()
        .trim();

    final senderName = (widget.messageData["SenderName"] ?? "").toString().trim();
    final receiverName = (widget.messageData["RecieverName"] ??
            widget.messageData["ReceiverName"] ??
            "")
        .toString()
        .trim();
    final senderImage =
        (widget.messageData["SenderImage"] ?? "").toString().trim();
    final receiverImage = (widget.messageData["RecieverImage"] ??
            widget.messageData["ReceiverImage"] ??
            "")
        .toString()
        .trim();

    final bool isSender = widget.messageData["isSender"] == "true";

    if (name.isEmpty || name == "User" || name.contains("@")) {
      if (isSender && receiverName.isNotEmpty) {
        name = receiverName;
      } else if (!isSender && senderName.isNotEmpty) {
        name = senderName;
      } else if (senderName.isNotEmpty) {
        name = senderName;
      } else if (receiverName.isNotEmpty) {
        name = receiverName;
      }
    }

    if (image.isEmpty) {
      if (isSender && receiverImage.isNotEmpty) {
        image = receiverImage;
      } else if (!isSender && senderImage.isNotEmpty) {
        image = senderImage;
      } else if (senderImage.isNotEmpty) {
        image = senderImage;
      } else if (receiverImage.isNotEmpty) {
        image = receiverImage;
      }
    }

    if (name.isEmpty) name = "User";

    final age = widget.messageData["age"] ?? "";
    final city = widget.messageData["city"] ?? "";
    final flag = widget.messageData["flag"] ?? "";
    final distance = widget.messageData["distance"] ?? "";
    final bool isVerified = widget.messageData["isVerified"] == "true" ||
        widget.messageData["isVerified"] == "1";

    final bool isOnline = widget.messageData["isOnline"] == "true" ||
        widget.messageData["isOnline"] == "1" ||
        widget.messageData["IsOnline"] == "true" ||
        widget.messageData["IsOnline"] == "1";
    final String lastSeen = widget.messageData["lastSeen"] ??
        widget.messageData["LastSeen"] ??
        "";

    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: true,
        bottom: !_showEmojiPicker,
        child: Column(
          children: [
            // Drag handle
            GestureDetector(
              onVerticalDragUpdate: widget.sheetScrollController != null
                  ? (details) {}
                  : null,
              child: Column(
                children: [
                  SizedBox(height: 8.h),
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                ],
              ),
            ),

            _ProfileCard(
              name: name,
              imageUrl: image,
              age: age,
              city: city,
              flag: flag,
              distance: distance,
              isVerified: isVerified,
              isOnline: isOnline,
              lastSeen: lastSeen,
              onBlockUser: _handleBlockUser,
            ),

            Expanded(child: _chatArea()),
            if (_isLoadingMessages)
              const SizedBox.shrink()
            else if (_blockMessage != null)
              _blockedNoticeBanner(_blockMessage!)
            else
              _inputBar(name),
            if (!_isLoadingMessages && _showEmojiPicker && _blockMessage == null)
              _emojiPickerPanel(),
          ],
        ),
      ),
    );
  }

  Widget _blockedNoticeBanner(String msg) {
    final bool isBlocked = msg.toLowerCase().contains("block");
    final Color tintColor = isBlocked
        ? const Color(0xFFFF5252)
        : (_isSenderPending
            ? const Color(0xFFFFA726)
            : const Color(0xFFFF5252));
    final IconData icon = isBlocked
        ? Icons.block_rounded
        : (_isSenderPending
            ? Icons.hourglass_top_rounded
            : Icons.info_outline);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: tintColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: tintColor, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  Widget _chatArea() {
    if (_isLoadingMessages) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF9B59B6),
          strokeWidth: 2.5,
        ),
      );
    }

    if (_blockMessage != null) {
      final bool isBlocked = _blockMessage!.toLowerCase().contains("block");
      final Color tintColor = isBlocked
          ? const Color(0xFFFF5252)
          : (_isSenderPending
              ? const Color(0xFFFFA726)
              : const Color(0xFFFF5252));
      final IconData icon = isBlocked
          ? Icons.block_rounded
          : (_isSenderPending
              ? Icons.hourglass_top_rounded
              : Icons.lock_outline_rounded);

      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: tintColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: tintColor,
                  size: 36.sp,
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                _blockMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_chats.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white38,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                "No messages yet",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                "Say hello to start the conversation 👋",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                      focusNode: _focusNode,
                      onChanged: (v) {},
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
      height: 180.h,
      color: AppColors.bg,
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w(8),
        vertical: AppSize.h(4),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 36.w,
            height: 3.h,
            margin: EdgeInsets.only(bottom: 6.h),
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
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Center(
                      child: Text(
                        _emojis[i],
                        style: TextStyle(fontSize: 18.sp),
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
}

// ═══════════════════════════════════════════
// 🔥 PROFILE CARD
// ═══════════════════════════════════════════
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.imageUrl,
    required this.age,
    required this.city,
    required this.flag,
    this.distance = "",
    this.isVerified = false,
    this.isOnline = false,
    this.lastSeen = "",
    this.onBlockUser,
  });

  final String name, imageUrl, age, city, flag, distance;
  final bool isVerified;
  final bool isOnline;
  final String lastSeen;
  final VoidCallback? onBlockUser;

  static const _cardBg = Color(0xFF0F1017);
  static const _cardBorder = Color(0xFF1C1D2A);
  static const _blue = Color(0xFF2B5CE6);
  static const _grey = Color(0xFFAAAAAA);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        AppSize.w(12),
        AppSize.h(6),
        AppSize.w(12),
        AppSize.h(6),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w(12),
        vertical: AppSize.h(10),
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
          // Photo + Online Badge
          _photo(),
          SizedBox(width: AppSize.w(12)),

          // Info
          Expanded(child: _info()),

          // 3 dot menu
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
                Container(
                  width: 38.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                SizedBox(height: 16.h),

                _menuItem(
                  context: context,
                  icon: Icons.block_rounded,
                  label: "Block $name",
                  color: Colors.orangeAccent,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmAction(
                      context,
                      title: "Block $name?",
                      subtitle: "They won't be able to message you anymore.",
                      actionLabel: "Block",
                      color: Colors.orangeAccent,
                      onConfirm: () {
                        onBlockUser?.call();
                      },
                    );
                  },
                ),

                Divider(
                  color: Colors.white.withValues(alpha: 0.06),
                  height: 1,
                  indent: 16.w,
                  endIndent: 16.w,
                ),

                _menuItem(
                  context: context,
                  icon: Icons.flag_rounded,
                  label: "Report $name",
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmAction(
                      context,
                      title: "Report $name?",
                      subtitle: "We'll review this profile and take action.",
                      actionLabel: "Report",
                      color: Colors.redAccent,
                      onConfirm: () {
                        Get.snackbar(
                          'Reported',
                          'User report submitted successfully',
                          backgroundColor: Colors.black87,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    );
                  },
                ),

                SizedBox(height: 8.h),

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
                        "Cancel",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
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

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String actionLabel,
    required Color color,
    required VoidCallback onConfirm,
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
                            "Cancel",
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
                      onTap: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
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
    Uint8List? imageBytes;
    bool hasHttp = false;

    if (imageUrl.isNotEmpty) {
      final trimmed = imageUrl.trim();
      if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
        hasHttp = true;
      } else {
        try {
          final cleanB64 = trimmed.contains(",")
              ? trimmed.split(",").last.trim()
              : trimmed;
          imageBytes = base64Decode(cleanB64);
        } catch (_) {}
      }
    }

    final avatarImg = ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: imageBytes != null
          ? Image.memory(
              imageBytes,
              width: AppSize.w(74),
              height: AppSize.h(84),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            )
          : hasHttp
          ? Image.network(
              imageUrl,
              width: AppSize.w(74),
              height: AppSize.h(84),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            )
          : _fallback(),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarImg,
        if (isOnline)
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              width: 14.w,
              height: 14.w,
              decoration: BoxDecoration(
                color: const Color(0xFF00E676),
                shape: BoxShape.circle,
                border: Border.all(color: _cardBg, width: 2.2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallback() {
    return Container(
      width: AppSize.w(74),
      height: AppSize.h(84),
      color: const Color(0xFF181924),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : "?",
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
        // Name + Verified
        SizedBox(height: AppSize.h(4)),
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
            if (isVerified) ...[
              SizedBox(width: AppSize.w(6)),
              Icon(Icons.verified_rounded, color: _blue, size: 18.sp),
            ],
          ],
        ),
        SizedBox(height: AppSize.h(3)),

        // Active Now (only when online)
        if (isOnline) ...[
          Row(
            children: [
              Container(
                width: 7.w,
                height: 7.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF00E676),
                ),
              ),
              SizedBox(width: 5.w),
              Text(
                "Active now",
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  color: const Color(0xFF00E676),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSize.h(3)),
        ],

        // Age / City / Flag
        if (age.isNotEmpty || city.isNotEmpty || flag.isNotEmpty)
          Row(
            children: [
              if (age.isNotEmpty) ...[
                _meta(age),
                if (city.isNotEmpty) SizedBox(width: AppSize.w(6)),
              ],
              if (city.isNotEmpty)
                Flexible(
                  child: Text(
                    city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: _grey,
                    ),
                  ),
                ),
              if (flag.isNotEmpty) ...[
                if (city.isNotEmpty || age.isNotEmpty)
                  SizedBox(width: AppSize.w(6)),
                Text(flag, style: TextStyle(fontSize: 15.sp)),
              ],
            ],
          ),
        if (distance.isNotEmpty) ...[
          SizedBox(height: AppSize.h(6)),
          // Distance Badge
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
                  () {
                    final cleanNum =
                        distance.replaceAll(RegExp(r'[^\d.]'), '');
                    final d = double.tryParse(cleanNum);
                    if (d != null && d < 1.0) {
                      return "1 km away";
                    }
                    return distance.toLowerCase().contains("km")
                        ? distance
                        : "$distance km away";
                  }(),
                  style: GoogleFonts.poppins(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _meta(String t) => Text(
    t,
    style: GoogleFonts.poppins(fontSize: 11.sp, color: _grey),
  );
}
