import 'dart:convert';
import 'package:boomboom/backend/registerservice.dart';
import 'package:boomboom/backend/secure_storage.dart';
import 'package:boomboom/constant/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xml/xml.dart' as xml;

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _unblockingEmails = {};

  @override
  void initState() {
    super.initState();
    _fetchBlockedUsers();
  }

  Future<void> _fetchBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final myEmail = await SecureStorage().getUserEmail() ?? "";
      if (myEmail.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Please log in to view blocked users.";
          });
        }
        return;
      }

      final response = await RegisterService().blockageShowBlockList(
        actionFrom: myEmail.trim(),
      );

      debugPrint(
        "[BlockedUsersScreen] Blockage_ShowBlockList: ${response.statusCode} -> ${response.body}",
      );

      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        String innerText = "";
        final resultNodes = doc.findAllElements('Blockage_ShowBlockListResult');
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
          final decoded = jsonDecode(innerText.trim());
          if (decoded is Map && decoded["Data"] is List) {
            final list = List<Map<String, dynamic>>.from(decoded["Data"]);
            if (mounted) {
              setState(() {
                _blockedUsers = list;
                _isLoading = false;
              });
            }
            return;
          }
        }
      }

      if (mounted) {
        setState(() {
          _blockedUsers = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("[BlockedUsersScreen] Error fetching blocked users: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load blocked users.";
        });
      }
    }
  }

  Future<void> _unblockUser(Map<String, dynamic> user) async {
    final blockedEmail = (user["EmailAddress"] ??
            user["actionto"] ??
            user["Actionto"] ??
            user["email"] ??
            "")
        .toString()
        .trim();

    final userName = (user["FullName"] ?? user["Name"] ?? "User").toString();

    if (blockedEmail.isEmpty) return;

    setState(() {
      _unblockingEmails.add(blockedEmail);
    });

    try {
      final myEmail = await SecureStorage().getUserEmail() ?? "";
      if (myEmail.trim().isNotEmpty) {
        final res = await RegisterService().chatUnblock(
          myEmail: myEmail.trim(),
          blockedEmail: blockedEmail,
        );

        debugPrint(
          "[BlockedUsersScreen] Chat_Unblock: ${res.statusCode} -> ${res.body}",
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
              Get.snackbar(
                'Unblocked',
                msg ?? '$userName has been unblocked',
                backgroundColor:
                    const Color(0xFF1E2E20).withValues(alpha: 0.95),
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            }
          } catch (_) {
            Get.snackbar(
              'Unblocked',
              '$userName has been unblocked',
              backgroundColor: const Color(0xFF1E2E20).withValues(alpha: 0.95),
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          _blockedUsers.removeWhere((u) {
            final uEmail = (u["EmailAddress"] ??
                    u["actionto"] ??
                    u["Actionto"] ??
                    u["email"] ??
                    "")
                .toString()
                .trim();
            return uEmail.toLowerCase() == blockedEmail.toLowerCase();
          });
        });
      }
    } catch (e) {
      debugPrint("[BlockedUsersScreen] Error unblocking user: $e");
      Get.snackbar(
        'Error',
        'Failed to unblock user. Please try again.',
        backgroundColor: const Color(0xFF2E1212).withValues(alpha: 0.95),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _unblockingEmails.remove(blockedEmail);
        });
      }
    }
  }

  void _confirmUnblock(BuildContext context, Map<String, dynamic> user) {
    final userName = (user["FullName"] ?? user["Name"] ?? "User").toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161622),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          "Unblock $userName?",
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: Text(
          "They will be able to see your profile and send you messages again.",
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            color: Colors.white70,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _unblockUser(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B59B6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            child: Text(
              "Unblock",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.white,
            size: 18.sp,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Blocked Users',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBlockedUsers,
        color: const Color(0xFF9B59B6),
        backgroundColor: const Color(0xFF1E1E2C),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: _isLoading
              ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF9B59B6),
                          strokeWidth: 2.5,
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.white38,
                                  size: 40.sp,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  _errorMessage!,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                ElevatedButton(
                                  onPressed: _fetchBlockedUsers,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9B59B6),
                                  ),
                                  child: const Text("Retry"),
                                ),
                              ],
                            ),
                          )
                        : _blockedUsers.isEmpty
                            ? _buildEmptyState()
                            : _buildUserList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing icon container
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF9B59B6).withValues(alpha: 0.25),
                      const Color(0xFF1E1428).withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF9B59B6).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9B59B6).withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.person_off_rounded,
                    color: const Color(0xFFCE93D8),
                    size: 46.sp,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'No Blocked Users',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'You haven\'t blocked anyone yet.\nWhen you block someone, they will appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5.sp,
                  color: Colors.white60,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _blockedUsers.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final user = _blockedUsers[index];
        final name =
            (user['FullName'] ?? user['Name'] ?? 'User').toString().trim();
        final email =
            (user['EmailAddress'] ?? user['actionto'] ?? user['email'] ?? '')
                .toString()
                .trim();
        String image =
            (user['Media'] ?? user['Image'] ?? '').toString().trim();
        if (image.isNotEmpty && !image.startsWith('http')) {
          image = 'https://boomboomdate.com/$image';
        }

        final isUnblocking = _unblockingEmails.contains(email);

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: const Color(0xFF161622),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24.r),
                child: Container(
                  width: 48.w,
                  height: 48.w,
                  color: const Color(0xFF2A2A3E),
                  child: image.isNotEmpty
                      ? Image.network(
                          image,
                          width: 48.w,
                          height: 48.w,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 11.5.sp,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              ElevatedButton(
                onPressed: isUnblocking ? null : () => _confirmUnblock(context, user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A1526),
                  foregroundColor: const Color(0xFFFF5252),
                  elevation: 0,
                  side: BorderSide(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                ),
                child: isUnblocking
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF5252),
                        ),
                      )
                    : Text(
                        'Unblock',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF5252),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
