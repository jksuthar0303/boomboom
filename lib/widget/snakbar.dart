import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ──────────────────────────────────────────────────────────────────────────────
// 🎨  NEU SNACKBAR  –  Top | Full Colored | Neumorphic
//
//  Usage:
//    NeuSnackbar.success("Withdraw Requested Successfully");
//    NeuSnackbar.error("Enter a valid amount");
//    NeuSnackbar.info("Processing your request...");
//    NeuSnackbar.warning("Insufficient balance!");
// ──────────────────────────────────────────────────────────────────────────────

class NeuSnackbar {
  NeuSnackbar._();

  // SUCCESS — green
  static const _successBg    = Color(0xFF2E7D52);
  static const _successLight = Color(0xFF4CAF82);
  static const _successDark  = Color(0xFF1B5C3A);

  // ERROR — red
  static const _errorBg      = Color(0xFFC0392B);
  static const _errorLight   = Color(0xFFE57373);
  static const _errorDark    = Color(0xFF922B21);

  // INFO — blue
  static const _infoBg       = Color(0xFF1C5FAD);
  static const _infoLight    = Color(0xFF5B8DEF);
  static const _infoDark     = Color(0xFF154A8A);

  // WARNING — amber
  static const _warningBg    = Color(0xFFBF7000);
  static const _warningLight = Color(0xFFF5A623);
  static const _warningDark  = Color(0xFF8C5200);

  static void success(String message, {String title = "Success"}) => _show(
      title: title, message: message, icon: Icons.check_circle_rounded,
      bgColor: _successBg, lightShadow: _successLight, darkShadow: _successDark);

  static void error(String message, {String title = "Oops!"}) => _show(
      title: title, message: message, icon: Icons.cancel_rounded,
      bgColor: _errorBg, lightShadow: _errorLight, darkShadow: _errorDark);

  static void info(String message, {String title = "Info"}) => _show(
      title: title, message: message, icon: Icons.info_rounded,
      bgColor: _infoBg, lightShadow: _infoLight, darkShadow: _infoDark);

  static void warning(String message, {String title = "Warning"}) => _show(
      title: title, message: message, icon: Icons.warning_amber_rounded,
      bgColor: _warningBg, lightShadow: _warningLight, darkShadow: _warningDark);

  static void _show({
    required String title,
    required String message,
    required IconData icon,
    required Color bgColor,
    required Color lightShadow,
    required Color darkShadow,
  }) {
    Get.rawSnackbar(
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 52, 16, 0),
      padding: EdgeInsets.zero,
      borderRadius: 20,
      backgroundColor: Colors.transparent,
      boxShadows: [
        BoxShadow(
          color: darkShadow.withValues(alpha: 0.6),
          offset: const Offset(6, 8),
          blurRadius: 18,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: lightShadow.withValues(alpha: 0.35),
          offset: const Offset(-4, -4),
          blurRadius: 12,
        ),
      ],
      messageText: _NeuSnackbarBody(
        title: title,
        message: message,
        icon: icon,
        bgColor: bgColor,
        lightShadow: lightShadow,
        darkShadow: darkShadow,
      ),
    );
  }
}

class _NeuSnackbarBody extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color bgColor;
  final Color lightShadow;
  final Color darkShadow;

  const _NeuSnackbarBody({
    required this.title,
    required this.message,
    required this.icon,
    required this.bgColor,
    required this.lightShadow,
    required this.darkShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [lightShadow.withValues(alpha: 0.30), bgColor, darkShadow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // ── Icon bubble
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [darkShadow, bgColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: darkShadow.withValues(alpha: 0.7),
                  offset: const Offset(4, 4),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color: lightShadow.withValues(alpha: 0.5),
                  offset: const Offset(-4, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          // ── Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ── Close button
          GestureDetector(
            onTap: () => Get.closeCurrentSnackbar(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [bgColor, darkShadow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: darkShadow.withValues(alpha: 0.7),
                    offset: const Offset(3, 3),
                    blurRadius: 7,
                  ),
                  BoxShadow(
                    color: lightShadow.withValues(alpha: 0.4),
                    offset: const Offset(-3, -3),
                    blurRadius: 7,
                  ),
                ],
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white.withValues(alpha: 0.85),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}