import 'package:boomboom/authentication/welcomscreens.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constant/colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> fadeAnim;
  late Animation<double> scaleAnim;
  late Animation<double> textAnim;

  Future<void> _requestNotificationPermission() async {
    await Permission.notification.request();
  }

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    scaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    textAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [

          // ── 1. FULLSCREEN BACKGROUND IMAGE (letsimage = complete composite image) ──
          AnimatedBuilder
            (
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: scaleAnim.value,
                alignment: Alignment.center,
                child: Opacity(
                  opacity: fadeAnim.value,
                  child: child,
                ),
              );
            },

            // ✅ FIX: Transform.translate hatao, width FULL rakho,
            // alignment center karo taaki dono sides dikhe
            child: Image.asset(
              "assets/letsimage.png",
              fit: BoxFit.contain,              // cover full screen
              width: size.width,                // ✅ 0.94 nahi, FULL width
              height: size.height,
              // ✅ (-0.90, 1) nahi, center
            ),
          ),

          // ── 2. BOTTOM GRADIENT (button ke peeche thoda dark) ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.20,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0xBB000000),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── 3. BUTTON at bottom ──
          Positioned(
            bottom: -10,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, textAnim.value),
                    child: Opacity(
                      opacity: fadeAnim.value,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 80.w : 20.w,
                    0,
                    isTablet ? 80.w : 20.w,
                    24.h,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Get.to(
                            () => WelcomeScreen(),
                        transition: Transition.rightToLeft,
                        duration: const Duration(milliseconds: 500),
                      );
                    },
                    child: Container(
                      height: 55.h,  // ← height badhaao
                      width: 80.w,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(40.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: .35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 24.w),
                          Expanded(
                            child: Center(
                              child: Text(
                                "Let's Get Started",
                                style: GoogleFonts.poppins(
                                  color: AppColors.black,
                                  fontSize: isTablet ? 22.sp : 18.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(right: 24.w),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.black,
                              size: 34.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}