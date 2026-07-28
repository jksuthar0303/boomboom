// help_support_screen.dart
//
// 📌 REQUIRED PACKAGES (pubspec.yaml):
//   flutter_screenutil: ^5.9.3
//   google_fonts: ^6.2.1
//   url_launcher: ^6.3.1
//
// 📌 NOTE: main.dart mein ScreenUtilInit already lagaya hua hona chahiye.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────
// 🎨 THEME / COLORS
// ─────────────────────────────────────────────────────────
class AppColors {
  static const Color bg = Color(0xFF0A0A0A);
  static const Color card = Color(0xFF141414);
  static const Color cardBorder = Color(0xFF262626);
  static const Color accent = Color(0xFFFF2D78); // neon pink
  static const Color accent2 = Color(0xFF7A3CFF); // purple
  static const Color success = Color(0xFF2ECC71);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color chipBg = Color(0xFF1C1C1C);
}

// ─────────────────────────────────────────────────────────
// 📱 HELP & SUPPORT SCREEN
// ─────────────────────────────────────────────────────────
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const String supportEmail = "support@boomboom.app";

  Future<void> _launch(String url, {required String errorMsg}) async {
    final uri = Uri.parse(url);
    final ok = await canLaunchUrl(uri);
    if (ok) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack(errorMsg);
    }
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.lightImpact();
    _showSnack("$label copied to clipboard");
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5.sp)),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 40.h),
          children: [
            SizedBox(height: 8.h),
            _buildEmailCard(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // 🧩 APP BAR
  // ─────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.bg,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18.sp),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        "Help & Support",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // 💌 EMAIL SUPPORT CARD (single centered card, image jaisa)
  // ─────────────────────────────────────────────────────
  Widget _buildEmailCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 22.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Icon illustration ──
          Container(
            width: 84.w,
            height: 84.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.14),
            ),
            child: Icon(Icons.mark_email_read_rounded, color: AppColors.accent, size: 40.sp),
          ),
          SizedBox(height: 18.h),

          Text(
            "Email Support",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),

          Text(
            "For any queries, feel free to reach out to us\nvia email. We're happy to help!",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 12.5.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 22.h),

          // ── Email chip (tap = copy) ──
          GestureDetector(
            onTap: () => _copyToClipboard(supportEmail, "Email"),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email_rounded, color: AppColors.accent, size: 17.sp),
                  SizedBox(width: 8.w),
                  Text(
                    supportEmail,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),

          Divider(color: AppColors.cardBorder, thickness: 1),
          SizedBox(height: 14.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time_rounded, color: AppColors.textSecondary, size: 14.sp),
              SizedBox(width: 6.w),
              Text(
                "We usually respond within 24 hours.",
                style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11.5.sp),
              ),
            ],
          ),

          SizedBox(height: 22.h),

          // ── Contact Support button ──
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: () => _launch(
                "mailto:$supportEmail?subject=Support%20Request",
                errorMsg: "Unable to open email app",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Text(
                "Contact Support",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}