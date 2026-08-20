import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:get/get.dart';

import 'package:xml/xml.dart' as xml;

import '../backend/registerservice.dart';
import '../backend/secure_storage.dart';
import '../constant/appconstants.dart';
import '../constant/appsize.dart';
import '../constant/colors.dart';
import '../model/messagedetails.dart';
import 'package:video_compress/video_compress.dart';

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
  final ValueChanged<bool>? onKeyboardChanged;

  const MessageDetailPage({
    super.key,
    required this.index,
    required this.messageData,
    this.sheetScrollController,
    this.draggableController,
    this.onKeyboardChanged,
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
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (modalContext) {
        final media = MediaQuery.of(modalContext);
        final keyboardHeight = media.viewInsets.bottom;
        final isKeyboardOpen = keyboardHeight > 0;

        return Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              height: isKeyboardOpen
                  ? (media.size.height - media.padding.top - keyboardHeight)
                        .clamp(250.0, media.size.height)
                  : media.size.height * 0.62,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28.r),
                  topRight: Radius.circular(28.r),
                ),
                child: MessageDetailPage(
                  index: index,
                  messageData: messageData,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage>
    with WidgetsBindingObserver {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _chatScroll = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _wordsSpokenBeforeListening = '';
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
  OverlayEntry? _topSnackEntry;
  Timer? _topSnackTimer;
  bool _isPollingInProgress = false;
  int? _resolvedChatListId;

  // ─────────────────────────────────────────
  // 🔥 INIT STATE
  // ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSpeech();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        if (_showEmojiPicker) {
          setState(() => _showEmojiPicker = false);
        }
        widget.onKeyboardChanged?.call(true);
        _expandChatForKeyboard();
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

  void _expandChatForKeyboard() {
    final controller = widget.draggableController;
    if (controller == null) return;

    void expand() {
      if (!mounted || !controller.isAttached) return;
      try {
        controller.animateTo(
          1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } catch (_) {
        // The sheet may still be attaching while the keyboard opens.
      }
    }

    // Run once immediately and again after the keyboard has changed the
    // available height; the second pass prevents the sheet from staying at
    // its half-screen snap position.
    WidgetsBinding.instance.addPostFrameCallback((_) => expand());
    Future.delayed(const Duration(milliseconds: 350), expand);
    Future.delayed(const Duration(milliseconds: 650), expand);
  }

  void _showTopMessage(String message) {
    _topSnackTimer?.cancel();
    _topSnackEntry?.remove();

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        final topInset = MediaQuery.of(overlayContext).padding.top;
        return Positioned(
          top: topInset + 12.h,
          left: 16.w,
          right: 16.w,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF241522),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.55),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: const Color(0xFFFF8A80),
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
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

    _topSnackEntry = entry;
    overlay.insert(entry);
    _topSnackTimer = Timer(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
      if (identical(_topSnackEntry, entry)) _topSnackEntry = null;
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final keyboardOpen =
        WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .viewInsets
            .bottom >
        0;
    widget.onKeyboardChanged?.call(keyboardOpen);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.draggableController == null) return;
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      final controller = widget.draggableController!;
      if (!controller.isAttached) return;

      try {
        controller.animateTo(
          keyboardHeight > 0 ? 1.0 : 0.62,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } catch (_) {}
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

    int chatListId =
        _resolvedChatListId ??
        int.tryParse(
          (widget.messageData["ChatListId"] ??
                  widget.messageData["chatListId"] ??
                  widget.messageData["id"] ??
                  "0")
              .toString(),
        ) ??
        0;

    final otherEmail =
        (widget.messageData["email"] ??
                widget.messageData["EmailAddress"] ??
                widget.messageData["ActionEmail"] ??
                widget.messageData["OtherUser"] ??
                "")
            .toString()
            .trim();

    try {
      final myEmail = await SecureStorage().getUserEmail() ?? "";

      // 1️⃣ Agar chatListId 0 hai, pehle ShowChatList se is user ki ChatListId dhoondo
      if (chatListId <= 0 && otherEmail.isNotEmpty && myEmail.isNotEmpty) {
        try {
          final listRes = await RegisterService().showChatList(
            email: myEmail.trim(),
          );
          if (listRes.statusCode == 200) {
            final listDoc = xml.XmlDocument.parse(listRes.body);
            final listElements = listDoc.findAllElements('ShowChatListResult');
            if (listElements.isNotEmpty) {
              final dynamic listJson = jsonDecode(listElements.first.innerText);
              if (listJson is Map &&
                  listJson["Status"] == 1 &&
                  listJson["Data"] is List) {
                final List data = listJson["Data"];
                for (var c in data) {
                  final cOther =
                      (c["OtherUser"] ??
                              c["Sender"] ??
                              c["Reciever"] ??
                              c["Email"] ??
                              "")
                          .toString()
                          .trim()
                          .toLowerCase();
                  final cSender = (c["Sender"] ?? c["SenderEmail"] ?? "")
                      .toString()
                      .trim()
                      .toLowerCase();
                  final cReciever = (c["Reciever"] ?? c["RecieverEmail"] ?? "")
                      .toString()
                      .trim()
                      .toLowerCase();

                  if (cOther == otherEmail.toLowerCase() ||
                      cSender == otherEmail.toLowerCase() ||
                      cReciever == otherEmail.toLowerCase()) {
                    final foundId =
                        int.tryParse(
                          (c["ChatListId"] ?? c["Id"] ?? c["id"] ?? "0")
                              .toString(),
                        ) ??
                        0;
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

      // 2️⃣ Agar abhi bhi chatListId 0 hai (naye user se pehli conversation), toh screen khol do
      if (chatListId <= 0) {
        if (mounted && _isLoadingMessages) {
          setState(() {
            _isLoadingMessages = false;
          });
        }
        _isPollingInProgress = false;
        return;
      }

      // 3️⃣ ChatListId milne ke baad ShowChatMessages call karo taaki messages load ho sakein
      final response = await RegisterService().showChatMessages(
        chatListId: chatListId,
        email: myEmail.trim(),
      );

      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        final res = doc.findAllElements('ShowChatMessagesResult');
        if (res.isNotEmpty) {
          final Map<String, dynamic> jsonResult = jsonDecode(
            res.first.innerText,
          );

          if (jsonResult["Status"] == 0) {
            final String rawApiMsg =
                (jsonResult["Message"] ??
                        (jsonResult["Data"] is Map
                            ? jsonResult["Data"]["Message"]
                            : null) ??
                        "Your chat request is pending. Please wait for the user to accept.")
                    .toString()
                    .trim();

            if (jsonResult["Data"] is Map &&
                jsonResult["Data"]["ChatListId"] != null) {
              final idVal = int.tryParse(
                jsonResult["Data"]["ChatListId"].toString(),
              );
              if (idVal != null && idVal > 0) {
                _resolvedChatListId = idVal;
              }
            }

            if (mounted) {
              setState(() {
                if (rawApiMsg.isNotEmpty) {
                  _blockMessage = rawApiMsg;
                }
                _isLoadingMessages = false;
              });
            }
            _isPollingInProgress = false;
            return;
          } else if (jsonResult["Status"] == 1 && jsonResult["Data"] is List) {
            final List list = jsonResult["Data"];

            // A successful response can still represent a pending request.
            // In that case the API message is the conversation state; do not
            // render old messages or allow another message to be sent.
            Map<String, dynamic>? pendingItem;
            for (final rawItem in list) {
              if (rawItem is Map) {
                final chatStatus =
                    (rawItem["ChatStatus"] ?? rawItem["chatStatus"] ?? "")
                        .toString()
                        .trim()
                        .toLowerCase();
                if (chatStatus == "pending") {
                  pendingItem = Map<String, dynamic>.from(rawItem);
                  break;
                }
              }
            }

            if (pendingItem != null) {
              final pendingMessage =
                  (pendingItem["Message"] ??
                          pendingItem["ChatMessage"] ??
                          jsonResult["Message"] ??
                          "Please accept the chat request to continue the conversation.")
                      .toString()
                      .trim();

              if (mounted) {
                setState(() {
                  _chats.clear();
                  _pendingLocalChats.clear();
                  _blockMessage = pendingMessage.isEmpty
                      ? "Please accept the chat request to continue the conversation."
                      : pendingMessage;
                  _isSenderPending = true;
                  _isLoadingMessages = false;
                });
              }
              _isPollingInProgress = false;
              return;
            }

            final List<ChatMessage> loadedChats = [];
            for (var item in list) {
              final itemChatListId =
                  int.tryParse(
                    (item["ChatListId"] ?? item["chatListId"] ?? "0")
                        .toString(),
                  ) ??
                  0;
              if (itemChatListId > 0 &&
                  (_resolvedChatListId == null || _resolvedChatListId! <= 0)) {
                _resolvedChatListId = itemChatListId;
              }

              final sender =
                  (item["SenderEmail"] ??
                          item["Sender"] ??
                          item["Senderemail"] ??
                          "")
                      .toString()
                      .trim();
              final isMe =
                  myEmail.isNotEmpty &&
                  sender.toLowerCase() == myEmail.toLowerCase();
              final text = (item["ChatMessage"] ?? item["Message"] ?? "")
                  .toString();
              final rawTime =
                  item["MessageDateandTime"] ??
                  item["Time"] ??
                  item["Date"] ??
                  item["CreatedDate"];
              final time = _formatMessageTime(rawTime?.toString());

              final msgStatusRaw = (item["MessageStatus"] ?? "")
                  .toString()
                  .toLowerCase()
                  .trim();
              final isReadVal =
                  item["IsRead"] ?? item["isRead"] ?? item["Isread"];
              final isDeliveredVal =
                  item["IsDelivered"] ??
                  item["isDelivered"] ??
                  item["Isdelivered"];

              MessageStatus status;
              if (isReadVal == 1 ||
                  isReadVal == "1" ||
                  isReadVal == true ||
                  isReadVal == "true" ||
                  msgStatusRaw == "read") {
                status = MessageStatus.read;
              } else if (isDeliveredVal == 1 ||
                  isDeliveredVal == "1" ||
                  isDeliveredVal == true ||
                  isDeliveredVal == "true" ||
                  msgStatusRaw == "delivered") {
                status = MessageStatus.delivered;
              } else {
                status = MessageStatus.sent;
              }

              // If this message was sent to me and is not yet marked read, mark it read via API
              if (!isMe) {
                final messageIdRaw =
                    item["Id"] ?? item["MessageId"] ?? item["id"];
                final messageId = int.tryParse(messageIdRaw?.toString() ?? "");
                if (messageId != null &&
                    messageId > 0 &&
                    status != MessageStatus.read) {
                  RegisterService().messageRead(
                    messageId: messageId,
                    email: myEmail,
                  );
                }
              }

              if (text.isNotEmpty) {
                final lowerText = text.toLowerCase().trim();
                final extRaw = (item["Ext"] ?? item["ext"] ?? "")
                    .toString()
                    .toLowerCase()
                    .trim();
                final bool isImg =
                    extRaw.contains("png") ||
                    extRaw.contains("jpg") ||
                    extRaw.contains("jpeg") ||
                    lowerText.endsWith(".png") ||
                    lowerText.endsWith(".jpg") ||
                    lowerText.endsWith(".jpeg") ||
                    lowerText.endsWith(".webp") ||
                    (lowerText.contains("/uploads/") &&
                        !lowerText.endsWith(".mp4"));

                final bool isVid =
                    extRaw.contains("mp4") ||
                    lowerText.endsWith(".mp4") ||
                    lowerText.endsWith(".mov") ||
                    lowerText.endsWith(".mkv");

                loadedChats.add(
                  ChatMessage(
                    text: text,
                    isMe: isMe,
                    time: time,
                    status: status,
                    isImage: isImg,
                    isVideo: isVid,
                  ),
                );
              }
            }

            // Remove server-confirmed messages from local pending list
            _pendingLocalChats.removeWhere(
              (pending) => loadedChats.any(
                (s) => s.isMe && s.text.trim() == pending.text.trim(),
              ),
            );

            final combinedChats = List<ChatMessage>.from(loadedChats);
            // Append any pending local messages that server has not returned yet
            combinedChats.addAll(_pendingLocalChats);

            // Detect if count, text, or tick status changed
            final bool hasChanged =
                combinedChats.length != _chats.length ||
                combinedChats.asMap().entries.any((entry) {
                  final i = entry.key;
                  if (i >= _chats.length) return true;
                  return entry.value.status != _chats[i].status ||
                      entry.value.text != _chats[i].text;
                });

            if (mounted &&
                (hasChanged ||
                    isInitial ||
                    _isLoadingMessages ||
                    _blockMessage != null)) {
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
    try {
      _speechToText.stop();
    } catch (_) {}
    _topSnackTimer?.cancel();
    _topSnackEntry?.remove();
    WidgetsBinding.instance.removeObserver(this);
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
  Future<void> _sendMessage(String t) async {
    final receiverEmail =
        widget.messageData["email"] ??
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
          debugPrint(
            "[MessageDetailPage] sendChatMessage response: ${res.statusCode} -> ${res.body}",
          );

          // The API can return HTTP 200 with a business-level failure, for
          // example LikeRequired. Do not leave the optimistic message in the
          // chat and show the exact API message to the user.
          if (res.statusCode == 200) {
            try {
              final doc = xml.XmlDocument.parse(res.body);
              final result = doc.findAllElements('SendChatMessageResult');
              if (result.isNotEmpty) {
                final apiResult = jsonDecode(result.first.innerText);
                final data = apiResult is Map ? apiResult["Data"] : null;
                final status = apiResult is Map ? apiResult["Status"] : null;
                final dataStatus = data is Map ? data["Status"] : null;
                final isFailure =
                    status.toString() == "0" || dataStatus.toString() == "0";

                if (isFailure) {
                  final apiMessage =
                      (apiResult["Message"] ??
                              (data is Map ? data["Message"] : null) ??
                              "Unable to send message.")
                          .toString()
                          .trim();

                  if (mounted) {
                    setState(() {
                      _chats.removeWhere(
                        (message) => identical(message, localMsg),
                      );
                      _pendingLocalChats.removeWhere(
                        (message) => identical(message, localMsg),
                      );
                    });
                    _showTopMessage(apiMessage);
                  }
                }
              }
            } catch (e) {
              debugPrint(
                "[MessageDetailPage] Could not parse send response: $e",
              );
            }
          } else {
            if (mounted) {
              setState(() {
                _chats.removeWhere((message) => identical(message, localMsg));
                _pendingLocalChats.removeWhere(
                  (message) => identical(message, localMsg),
                );
              });
              _showTopMessage("Server error (${res.statusCode})");
            }
          }
        }
      } catch (e) {
        debugPrint("[MessageDetailPage] Error sending chat message: $e");
        if (mounted) {
          setState(() {
            _chats.removeWhere((message) => identical(message, localMsg));
            _pendingLocalChats.removeWhere(
              (message) => identical(message, localMsg),
            );
          });
          _showTopMessage("Failed to send message: $e");
        }
      }
    }
  }

  Future<void> _addImage(String path) async {
    final localMsg = ChatMessage(
      text: path,
      localFilePath: path,
      isMe: true,
      time: _nowStr(),
      status: MessageStatus.sent,
      isImage: true,
      isUploading: true,
    );

    setState(() {
      _chats.add(localMsg);
      _pendingLocalChats.add(localMsg);
    });
    _scrollToBottom(animate: true);

    final receiverEmail =
        widget.messageData["email"] ??
        widget.messageData["EmailAddress"] ??
        widget.messageData["ActionEmail"] ??
        "";

    if (receiverEmail.trim().isNotEmpty) {
      try {
        final senderEmail = await SecureStorage().getUserEmail() ?? "";
        if (senderEmail.trim().isNotEmpty) {
          final file = File(path);
          final bytes = await file.readAsBytes();
          final base64Image = base64Encode(bytes);

          final res = await RegisterService().sendChatMessage(
            senderEmail: senderEmail.trim(),
            receiverEmail: receiverEmail.trim(),
            chatMessage: base64Image,
          );

          debugPrint(
            "[MessageDetailPage] sendImage response: ${res.statusCode} -> ${res.body}",
          );

          if (res.statusCode == 200) {
            try {
              final doc = xml.XmlDocument.parse(res.body);
              final result = doc.findAllElements('SendChatMessageResult');
              if (result.isNotEmpty) {
                final apiResult = jsonDecode(result.first.innerText);
                final data = apiResult is Map ? apiResult["Data"] : null;
                final status = apiResult is Map ? apiResult["Status"] : null;
                final dataStatus = data is Map ? data["Status"] : null;
                final isFailure =
                    status.toString() == "0" || dataStatus.toString() == "0";

                if (isFailure) {
                  final apiMessage =
                      (apiResult["Message"] ??
                              (data is Map ? data["Message"] : null) ??
                              "Unable to send image.")
                          .toString()
                          .trim();

                  if (mounted) {
                    setState(() {
                      _chats.removeWhere((m) => identical(m, localMsg));
                      _pendingLocalChats.removeWhere(
                        (m) => identical(m, localMsg),
                      );
                    });
                    _showTopMessage(apiMessage);
                  }
                  return;
                }
              }
            } catch (_) {}

            if (mounted) {
              setState(() {
                final idx = _chats.indexWhere((m) => identical(m, localMsg));
                if (idx != -1) {
                  _chats[idx] = _chats[idx].copyWith(isUploading: false);
                }
                final pendingIdx = _pendingLocalChats.indexWhere(
                  (m) => identical(m, localMsg),
                );
                if (pendingIdx != -1) {
                  _pendingLocalChats[pendingIdx] =
                      _pendingLocalChats[pendingIdx].copyWith(
                        isUploading: false,
                      );
                }
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _chats.removeWhere((m) => identical(m, localMsg));
                _pendingLocalChats.removeWhere((m) => identical(m, localMsg));
              });
              _showTopMessage("Server error (${res.statusCode})");
            }
          }
        }
      } catch (e) {
        debugPrint("[MessageDetailPage] Error sending image: $e");
        if (mounted) {
          setState(() {
            _chats.removeWhere((m) => identical(m, localMsg));
            _pendingLocalChats.removeWhere((m) => identical(m, localMsg));
          });
          _showTopMessage("Failed to send image.");
        }
      }
    }
  }

  Future<void> _addVideo(String path) async {
    final localMsg = ChatMessage(
      text: path,
      localFilePath: path,
      isMe: true,
      time: _nowStr(),
      status: MessageStatus.sent,
      isVideo: true,
      isUploading: true,
    );

    setState(() {
      _chats.add(localMsg);
      _pendingLocalChats.add(localMsg);
    });
    _scrollToBottom(animate: true);

    final receiverEmail =
        widget.messageData["email"] ??
        widget.messageData["EmailAddress"] ??
        widget.messageData["ActionEmail"] ??
        "";

    if (receiverEmail.trim().isNotEmpty) {
      try {
        final senderEmail = await SecureStorage().getUserEmail() ?? "";
        if (senderEmail.trim().isNotEmpty) {
          // Compress video using VideoCompress
          MediaInfo? compressed;
          try {
            compressed = await VideoCompress.compressVideo(
              path,
              quality: VideoQuality.MediumQuality,
              deleteOrigin: false,
              includeAudio: true,
            );
          } catch (e) {
            debugPrint("[MessageDetailPage] Video compression error: $e");
          }

          final File uploadFile = compressed?.file ?? File(path);
          final bytes = await uploadFile.readAsBytes();
          final base64Video = base64Encode(bytes);

          final res = await RegisterService().sendChatMessage(
            senderEmail: senderEmail.trim(),
            receiverEmail: receiverEmail.trim(),
            chatMessage: base64Video,
          );

          debugPrint(
            "[MessageDetailPage] sendVideo response: ${res.statusCode} -> ${res.body}",
          );

          if (res.statusCode == 200) {
            try {
              final doc = xml.XmlDocument.parse(res.body);
              final result = doc.findAllElements('SendChatMessageResult');
              if (result.isNotEmpty) {
                final apiResult = jsonDecode(result.first.innerText);
                final data = apiResult is Map ? apiResult["Data"] : null;
                final status = apiResult is Map ? apiResult["Status"] : null;
                final dataStatus = data is Map ? data["Status"] : null;
                final isFailure =
                    status.toString() == "0" || dataStatus.toString() == "0";

                if (isFailure) {
                  final apiMessage =
                      (apiResult["Message"] ??
                              (data is Map ? data["Message"] : null) ??
                              "Unable to send video.")
                          .toString()
                          .trim();

                  if (mounted) {
                    setState(() {
                      _chats.removeWhere((m) => identical(m, localMsg));
                      _pendingLocalChats.removeWhere(
                        (m) => identical(m, localMsg),
                      );
                    });
                    _showTopMessage(apiMessage);
                  }
                  return;
                }
              }
            } catch (_) {}

            if (mounted) {
              setState(() {
                final idx = _chats.indexWhere((m) => identical(m, localMsg));
                if (idx != -1) {
                  _chats[idx] = _chats[idx].copyWith(isUploading: false);
                }
                final pendingIdx = _pendingLocalChats.indexWhere(
                  (m) => identical(m, localMsg),
                );
                if (pendingIdx != -1) {
                  _pendingLocalChats[pendingIdx] =
                      _pendingLocalChats[pendingIdx].copyWith(
                        isUploading: false,
                      );
                }
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _chats.removeWhere((m) => identical(m, localMsg));
                _pendingLocalChats.removeWhere((m) => identical(m, localMsg));
              });
              _showTopMessage("Server error (${res.statusCode})");
            }
          }
        }
      } catch (e) {
        debugPrint("[MessageDetailPage] Error sending video: $e");
        if (mounted) {
          setState(() {
            _chats.removeWhere((m) => identical(m, localMsg));
            _pendingLocalChats.removeWhere((m) => identical(m, localMsg));
          });
          _showTopMessage("Failed to send video.");
        }
      }
    }
  }

  // ─────────────────────────────────────────
  // 🔥 VOICE TO TEXT METHODS
  // ─────────────────────────────────────────
  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (val) {
          debugPrint('Speech error: $val');
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (val) {
          debugPrint('Speech status: $val');
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  Future<void> _startListening() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      Get.snackbar(
        'Permission Required',
        'Please allow microphone permission to use voice typing.',
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (!_speechEnabled) {
      _speechEnabled = await _speechToText.initialize(
        onError: (val) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    }

    if (_speechEnabled) {
      _wordsSpokenBeforeListening = _ctrl.text;
      setState(() => _isListening = true);

      await _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            final recognized = result.recognizedWords;
            final prefix = _wordsSpokenBeforeListening.isEmpty
                ? ''
                : _wordsSpokenBeforeListening.endsWith(' ')
                ? _wordsSpokenBeforeListening
                : '$_wordsSpokenBeforeListening ';
            final newText = '$prefix$recognized';
            _ctrl.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: newText.length),
            );
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
      );
    }
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    if (mounted) setState(() => _isListening = false);
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  // ─────────────────────────────────────────
  // 🔥 MEDIA PICKER (Images & Videos)
  // ─────────────────────────────────────────
  // ignore: unused_element
  Future<void> _pickMedia() async {
    if (_showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
    }
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) {
        return Container(
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: const Color(0xFF141520),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                Text(
                  "Share Media",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 18.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _mediaOptionItem(
                      icon: Icons.camera_alt_rounded,
                      label: "Camera",
                      color: const Color(0xFFFF5252),
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 75,
                        );
                        if (image != null) _addImage(image.path);
                      },
                    ),
                    _mediaOptionItem(
                      icon: Icons.videocam_rounded,
                      label: "Record Video",
                      color: const Color(0xFFFF9800),
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? video = await _picker.pickVideo(
                          source: ImageSource.camera,
                          maxDuration: const Duration(minutes: 2),
                        );
                        if (video != null) _addVideo(video.path);
                      },
                    ),
                    _mediaOptionItem(
                      icon: Icons.photo_library_rounded,
                      label: "Photos",
                      color: const Color(0xFF2196F3),
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 75,
                        );
                        if (image != null) _addImage(image.path);
                      },
                    ),
                    _mediaOptionItem(
                      icon: Icons.video_library_rounded,
                      label: "Videos",
                      color: const Color(0xFF9C27B0),
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? video = await _picker.pickVideo(
                          source: ImageSource.gallery,
                        );
                        if (video != null) _addVideo(video.path);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mediaOptionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54.w,
            height: 54.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _nowStr() {
    final t = TimeOfDay.now();
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? "AM" : "PM"}';
  }

  Future<void> _handleBlockOrReport(bool isBlock) async {
    if (isBlock) {
      final chatListId =
          _resolvedChatListId ??
          int.tryParse(
            (widget.messageData["ChatListId"] ??
                    widget.messageData["chatListId"] ??
                    widget.messageData["id"] ??
                    "0")
                .toString(),
          ) ??
          0;

      try {
        final myEmail = await SecureStorage().getUserEmail() ?? "";
        if (myEmail.isNotEmpty) {
          final res = await RegisterService().blockChatUser(
            chatListId: chatListId,
            email: myEmail.trim(),
          );
          debugPrint(
            "[MessageDetailPage] BlockChatUser response: ${res.statusCode} -> ${res.body}",
          );

          if (res.statusCode == 200) {
            try {
              final doc = xml.XmlDocument.parse(res.body);
              String innerText = "";
              final resultNodes = doc.findAllElements('BlockChatUserResult');
              if (resultNodes.isNotEmpty) {
                innerText = resultNodes.first.innerText;
              } else {
                final stringNodes = doc.findAllElements('string');
                if (stringNodes.isNotEmpty) {
                  innerText = stringNodes.first.innerText;
                } else {
                  innerText = doc.rootElement.innerText;
                }
              }

              if (innerText.trim().isNotEmpty) {
                final apiResult = jsonDecode(innerText.trim());
                final msg =
                    (apiResult is Map
                            ? (apiResult["Message"] ??
                                  (apiResult["Data"] is Map
                                      ? apiResult["Data"]["Message"]
                                      : null))
                            : null)
                        ?.toString();
                if (mounted) {
                  Get.snackbar(
                    'Blocked',
                    msg ?? 'User has been blocked successfully',
                    backgroundColor: const Color(
                      0xFFFF5252,
                    ).withValues(alpha: 0.85),
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );
                }
              }
            } catch (_) {
              if (mounted) {
                Get.snackbar(
                  'Blocked',
                  'User has been blocked successfully',
                  backgroundColor: const Color(
                    0xFFFF5252,
                  ).withValues(alpha: 0.85),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );
              }
            }
          }
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint("[MessageDetailPage] Error blocking user: $e");
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
      return;
    }

    final targetEmail =
        (widget.messageData["email"] ??
                widget.messageData["EmailAddress"] ??
                widget.messageData["ActionEmail"] ??
                widget.messageData["OtherUser"] ??
                "")
            .toString()
            .trim();

    try {
      final myEmail = await SecureStorage().getUserEmail() ?? "";
      if (myEmail.isNotEmpty && targetEmail.isNotEmpty) {
        final res = await RegisterService().blockageReport(
          actionFrom: myEmail.trim(),
          actionTo: targetEmail.trim(),
        );
        debugPrint(
          "[MessageDetailPage] Blockage_Report response: ${res.statusCode} -> ${res.body}",
        );

        if (res.statusCode == 200) {
          try {
            final doc = xml.XmlDocument.parse(res.body);
            String innerText = "";
            final resultNodes = doc.findAllElements('Blockage_ReportResult');
            if (resultNodes.isNotEmpty) {
              innerText = resultNodes.first.innerText;
            } else {
              final stringNodes = doc.findAllElements('string');
              if (stringNodes.isNotEmpty) {
                innerText = stringNodes.first.innerText;
              } else {
                innerText = doc.rootElement.innerText;
              }
            }

            if (innerText.trim().isNotEmpty) {
              final apiResult = jsonDecode(innerText.trim());
              final msg =
                  (apiResult is Map
                          ? (apiResult["Message"] ??
                                (apiResult["Data"] is Map
                                    ? apiResult["Data"]["Message"]
                                    : null))
                          : null)
                      ?.toString();
              if (mounted) {
                Get.snackbar(
                  'Success',
                  msg ?? 'User reported successfully.',
                  backgroundColor: const Color(0xFF241522),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                  duration: const Duration(seconds: 3),
                );
              }
            }
          } catch (_) {
            if (mounted) {
              Get.snackbar(
                'Success',
                'User reported successfully.',
                backgroundColor: const Color(0xFF241522),
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
                duration: const Duration(seconds: 3),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint("[MessageDetailPage] Error calling Blockage_Report: $e");
    }
  }

  Future<void> _handleUnblockUser() async {
    final targetEmail = (widget.messageData["email"] ??
            widget.messageData["EmailAddress"] ??
            widget.messageData["ActionEmail"] ??
            widget.messageData["OtherUser"] ??
            "")
        .toString()
        .trim();

    try {
      final myEmail = await SecureStorage().getUserEmail() ?? "";
      if (myEmail.isNotEmpty && targetEmail.isNotEmpty) {
        final res = await RegisterService().chatUnblock(
          myEmail: myEmail.trim(),
          blockedEmail: targetEmail.trim(),
        );
        debugPrint(
          "[MessageDetailPage] Chat_Unblock response: ${res.statusCode} -> ${res.body}",
        );

        if (res.statusCode == 200) {
          try {
            final doc = xml.XmlDocument.parse(res.body);
            String innerText = "";
            final resultNodes = doc.findAllElements('Chat_UnblockResult');
            if (resultNodes.isNotEmpty) {
              innerText = resultNodes.first.innerText;
            } else {
              final stringNodes = doc.findAllElements('string');
              if (stringNodes.isNotEmpty) {
                innerText = stringNodes.first.innerText;
              } else {
                innerText = doc.rootElement.innerText;
              }
            }

            if (innerText.trim().isNotEmpty) {
              final apiResult = jsonDecode(innerText.trim());
              final msg = (apiResult is Map
                      ? (apiResult["Message"] ??
                          (apiResult["Data"] is Map
                              ? apiResult["Data"]["Message"]
                              : null))
                      : null)
                  ?.toString();
              if (mounted) {
                Get.snackbar(
                  'Unblocked',
                  msg ?? 'User unblocked successfully',
                  backgroundColor:
                      const Color(0xFF1E2E20).withValues(alpha: 0.95),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );
              }
            }
          } catch (_) {
            if (mounted) {
              Get.snackbar(
                'Unblocked',
                'User unblocked successfully',
                backgroundColor:
                    const Color(0xFF1E2E20).withValues(alpha: 0.95),
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _blockMessage = null;
          _isLoadingMessages = true;
        });
        _fetchChatMessages();
      }
    } catch (e) {
      debugPrint("[MessageDetailPage] Error unblocking user: $e");
    }
  }

  // ─────────────────────────────────────────
  // 🔥 BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    String name =
        (widget.messageData["name"] ??
                widget.messageData["FullName"] ??
                widget.messageData["Name"] ??
                "")
            .toString()
            .trim();
    String image =
        (widget.messageData["image"] ??
                widget.messageData["Image"] ??
                widget.messageData["Media"] ??
                widget.messageData["ProfileImage"] ??
                "")
            .toString()
            .trim();

    final senderName = (widget.messageData["SenderName"] ?? "")
        .toString()
        .trim();
    final receiverName =
        (widget.messageData["RecieverName"] ??
                widget.messageData["ReceiverName"] ??
                "")
            .toString()
            .trim();
    final senderImage = (widget.messageData["SenderImage"] ?? "")
        .toString()
        .trim();
    final receiverImage =
        (widget.messageData["RecieverImage"] ??
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
    final bool isVerified =
        widget.messageData["isVerified"] == "true" ||
        widget.messageData["isVerified"] == "1";

    final String rawOnlineStatus =
        (widget.messageData["OnlineStatus"] ??
                widget.messageData["onlineStatus"] ??
                widget.messageData["online_status"] ??
                "")
            .toString()
            .trim();

    final onlineValue =
        (widget.messageData["isOnline"] ??
                widget.messageData["IsOnline"] ??
                widget.messageData["Online"] ??
                "")
            .toString()
            .trim()
            .toLowerCase();

    String displayStatus = "Offline";
    bool isOnline = false;

    if (rawOnlineStatus.isNotEmpty &&
        rawOnlineStatus.toLowerCase() != "null" &&
        rawOnlineStatus.toLowerCase() != "accepted" &&
        rawOnlineStatus.toLowerCase() != "pending") {
      final sLower = rawOnlineStatus.toLowerCase();
      if (sLower == "online" ||
          sLower == "online now" ||
          sLower == "active" ||
          sLower == "active now") {
        displayStatus = "Online";
        isOnline = true;
      } else if (sLower == "hidden") {
        displayStatus = "Hidden";
        isOnline = false;
      } else if (sLower == "away") {
        displayStatus = "Away";
        isOnline = false;
      } else {
        displayStatus = "Offline";
        isOnline = false;
      }
    } else if (onlineValue.isNotEmpty && onlineValue != "null") {
      if (onlineValue == "true" ||
          onlineValue == "1" ||
          onlineValue == "yes" ||
          onlineValue == "online") {
        displayStatus = "Online";
        isOnline = true;
      } else if (onlineValue == "hidden") {
        displayStatus = "Hidden";
        isOnline = false;
      } else {
        displayStatus = "Offline";
        isOnline = false;
      }
    }

    final String lastSeen =
        widget.messageData["lastSeen"] ?? widget.messageData["LastSeen"] ?? "";

    return Material(
      color: AppColors.bg,
      child: SafeArea(
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
              isVerified: isVerified,
              isOnline: isOnline,
              onlineStatus: displayStatus,
              lastSeen: lastSeen,
              isBlocked: _blockMessage != null &&
                  _blockMessage!.toLowerCase().contains("block"),
              onBlockUser: () => _handleBlockOrReport(true),
              onUnblockUser: _handleUnblockUser,
              onReportUser: () => _handleBlockOrReport(false),
            ),

            Expanded(child: _chatArea()),
            if (_isLoadingMessages)
              const SizedBox.shrink()
            else if (_blockMessage != null)
              _blockedNoticeBanner(_blockMessage!)
            else
              _inputBar(name),
            if (!_isLoadingMessages &&
                _showEmojiPicker &&
                _blockMessage == null)
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
        : (_isSenderPending ? Icons.hourglass_top_rounded : Icons.info_outline);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: tintColor.withValues(alpha: 0.3)),
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
                child: Icon(icon, color: tintColor, size: 36.sp),
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
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14.r),
                          child: _buildImageWidget(c),
                        ),
                        if (c.isUploading)
                          Container(
                            width: 180.w,
                            height: 230.h,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 32.w,
                                  height: 32.w,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.8,
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  "Sending image...",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    )
                  : c.isVideo
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180.w,
                          height: 230.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1017),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_circle_fill_rounded,
                                color: Colors.white,
                                size: 54.sp,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                "Video",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (c.isUploading)
                          Container(
                            width: 180.w,
                            height: 230.h,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 32.w,
                                  height: 32.w,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.8,
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  "Compressing &\nSending...",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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

  Widget _buildImageWidget(ChatMessage c) {
    if (c.localFilePath != null && File(c.localFilePath!).existsSync()) {
      return Image.file(
        File(c.localFilePath!),
        width: 180.w,
        height: 230.h,
        fit: BoxFit.cover,
      );
    }
    if (File(c.text).existsSync()) {
      return Image.file(
        File(c.text),
        width: 180.w,
        height: 230.h,
        fit: BoxFit.cover,
      );
    }
    if (c.text.startsWith('http://') || c.text.startsWith('https://')) {
      return Image.network(
        c.text,
        width: 180.w,
        height: 230.h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _mediaErrorPlaceholder(Icons.broken_image_rounded),
      );
    }
    if (c.text.startsWith('/') || c.text.contains('.')) {
      final fullUrl = c.text.startsWith('/')
          ? '${AppConstants.baseUrl}${c.text.substring(1)}'
          : '${AppConstants.baseUrl}${c.text}';
      return Image.network(
        fullUrl,
        width: 180.w,
        height: 230.h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _mediaErrorPlaceholder(Icons.broken_image_rounded),
      );
    }
    try {
      return Image.memory(
        base64Decode(c.text),
        width: 180.w,
        height: 230.h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _mediaErrorPlaceholder(Icons.broken_image_rounded),
      );
    } catch (_) {
      return _mediaErrorPlaceholder(Icons.broken_image_rounded);
    }
  }

  Widget _mediaErrorPlaceholder(IconData icon) {
    return Container(
      width: 180.w,
      height: 230.h,
      color: const Color(0xFF161722),
      child: Center(
        child: Icon(icon, color: Colors.white38, size: 32.sp),
      ),
    );
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isListening)
            Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, color: Colors.redAccent, size: 16.sp),
                  SizedBox(width: 6.w),
                  Text(
                    "Listening... Speak now",
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // _circleBtn(icon: Icons.camera_alt_rounded, onTap: _pickMedia),
              // SizedBox(width: AppSize.w(8)),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(28.r),
                    border: Border.all(
                      color: _isListening
                          ? Colors.redAccent.withValues(alpha: 0.5)
                          : AppColors.inputBorder,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: AppSize.w(14)),
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
                            hintText: _isListening
                                ? 'Listening...'
                                : 'Message $name...',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              color: _isListening
                                  ? Colors.redAccent
                                  : AppColors.grey,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: AppSize.h(12),
                            ),
                          ),
                        ),
                      ),
                      // ─── VOICE TO TEXT BUTTON ───
                      GestureDetector(
                        onTap: _toggleListening,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: _isListening
                                  ? Colors.redAccent.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none_rounded,
                              color: _isListening
                                  ? Colors.redAccent
                                  : AppColors.grey,
                              size: 22.sp,
                            ),
                          ),
                        ),
                      ),
                      // ─── EMOJI BUTTON ───
                      GestureDetector(
                        onTap: () {
                          setState(() => _showEmojiPicker = !_showEmojiPicker);
                          if (_showEmojiPicker) {
                            FocusScope.of(context).unfocus();
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.only(left: 2.w),
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
    this.isVerified = false,
    this.isOnline = false,
    this.onlineStatus = "Offline",
    this.lastSeen = "",
    this.isBlocked = false,
    this.onBlockUser,
    this.onUnblockUser,
    this.onReportUser,
  });

  final String name, imageUrl, age, city, flag;
  final bool isVerified;
  final bool isOnline;
  final String onlineStatus;
  final String lastSeen;
  final bool isBlocked;
  final VoidCallback? onBlockUser;
  final VoidCallback? onUnblockUser;
  final VoidCallback? onReportUser;

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

                if (isBlocked)
                  _menuItem(
                    context: context,
                    icon: Icons.lock_open_rounded,
                    label: "Unblock $name",
                    color: Colors.lightGreenAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _confirmAction(
                        context,
                        title: "Unblock $name?",
                        subtitle: "You will be able to exchange messages again.",
                        actionLabel: "Unblock",
                        color: Colors.lightGreenAccent,
                        onConfirm: () {
                          onUnblockUser?.call();
                        },
                      );
                    },
                  )
                else
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
                        onReportUser?.call();
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

        // Online / Offline Status
        if (onlineStatus.isNotEmpty) ...[
          Row(
            children: [
              Container(
                width: 7.w,
                height: 7.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? const Color(0xFF00E676) : Colors.grey,
                ),
              ),
              SizedBox(width: 5.w),
              Text(
                onlineStatus,
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  color: isOnline ? const Color(0xFF00E676) : Colors.grey,
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
                    style: GoogleFonts.poppins(fontSize: 11.sp, color: _grey),
                  ),
                ),
              if (flag.isNotEmpty) ...[
                if (city.isNotEmpty || age.isNotEmpty)
                  SizedBox(width: AppSize.w(6)),
                Text(flag, style: TextStyle(fontSize: 15.sp)),
              ],
            ],
          ),
      ],
    );
  }

  Widget _meta(String t) => Text(
    t,
    style: GoogleFonts.poppins(fontSize: 11.sp, color: _grey),
  );
}
