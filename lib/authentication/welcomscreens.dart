import 'package:boomboom/authentication/registerscreen/login.dart';
import 'package:boomboom/authentication/registerscreen/otpscreen.dart';
import 'package:boomboom/authentication/registerscreen/registerfirst.dart';
import 'package:boomboom/backend/permission_service.dart';
import 'package:boomboom/backend/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../constant/appsize.dart';
import '../constant/apptextstyle.dart';
import '../constant/colors.dart';
import '../screens/bottombar.dart';
import '../widget/bouncelogo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController emailController = TextEditingController();
  bool _locationPermissionAsked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _askLocationPermissionIfNeeded();
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _askLocationPermissionIfNeeded() async {
    if (_locationPermissionAsked || !mounted) return;
    _locationPermissionAsked = true;

    try {
      final alreadyGranted = await PermissionService.isLocationGranted();
      if (!alreadyGranted && mounted) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          await PermissionService.requestLocationPermission();
        }
      }
    } catch (e) {
      debugPrint("[WelcomeScreen] Location permission error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        // ✅ SafeArea added — screen niche aayegi
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSize.w(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: AppSize.h(20)), // ✅ thoda top space
              /// 🔙 Back Button
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: AppSize.w(40),
                      height: AppSize.h(40),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.white,
                        size: AppSize.sp(18),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSize.h(14)),

              /// 🔤 Logo
              BounceLogo(imagePath: "assets/logos.png", size: 100),

              SizedBox(height: AppSize.h(14)),

              /// 🔤 Title
              Text(
                "Login to your account",
                style: AppTextStyles.heading.copyWith(
                  fontSize: AppSize.sp(18),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: AppSize.h(20)),

              /// 🔒 Login with Email & Password Button (gradient border)
              _loginOptionButton(
                icon: Icons.lock_outline,
                title: "Login with Email & Password",
                subtitle: "Enter your email and password to login",
                showArrow: true,
                showGradientBorder: true,
                onTap: () {
                  Get.to(
                    () => LoginScreen(),
                    transition: Transition.cupertino,
                    duration: const Duration(milliseconds: 800),
                  );
                },
              ),

              SizedBox(height: AppSize.h(16)),

              /// ── Or ──
              _orDivider(),

              SizedBox(height: AppSize.h(16)),

              /// 📧 Email OTP tile
              _loginOptionButton(
                icon: Icons.mail_outline,
                title: "Email",
                subtitle: "We'll send an OTP to your email",
                showArrow: false,
                showRightIcon: true,
                showGradientBorder: true,
                onTap: () {},
              ),

              SizedBox(height: AppSize.h(14)),

              /// 📧 Email Input Field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSize.w(14)),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9B59B6), Color(0xFF3498DB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(1.5),
                child: Container(
                  height: AppSize.h(52),
                  padding: EdgeInsets.symmetric(horizontal: AppSize.w(16)),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(AppSize.w(13)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mail_outline,
                        color: AppColors.grey,
                        size: AppSize.sp(20),
                      ),
                      SizedBox(width: AppSize.w(10)),
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter your email address",
                            hintStyle: AppTextStyles.body.copyWith(
                              color: AppColors.grey,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppSize.h(14)),

              /// 🚀 Send Email OTP Button (Gradient)
              GestureDetector(
                onTap: () async {
                  if (emailController.text.trim().isEmpty) {
                    Get.snackbar(
                      "Error",
                      "Please enter email",
                      backgroundColor: AppColors.error,
                      colorText: AppColors.white,
                    );
                    return;
                  }
                  await SecureStorage().saveUserEmail(
                    emailController.text.trim(),
                  );
                  Get.to(
                    () => EmailOtpScreen(email: emailController.text.trim()),
                    transition: Transition.rightToLeft,
                    duration: const Duration(milliseconds: 400),
                  );
                },
                child: Container(
                  height: AppSize.h(48),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSize.w(14)),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9B59B6), Color(0xFF3498DB)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Send Email OTP", style: AppTextStyles.button),
                      SizedBox(width: AppSize.w(10)),
                      Icon(
                        Icons.send_outlined,
                        color: AppColors.white,
                        size: AppSize.sp(16),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppSize.h(22)),

              /// ── Or continue with ──
              _orDivider(text: "Or continue with"),

              SizedBox(height: AppSize.h(18)),

              /// 🌐 Social Buttons: Facebook + Google + Apple
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialCircleButton(
                    onTap: () {},
                    child: ClipOval(
                      child: Image.network(
                        "https://cdn-icons-png.flaticon.com/512/733/733547.png",
                        height: AppSize.w(38),
                        width: AppSize.w(38),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSize.w(16)),
                  _socialCircleButton(
                    onTap: () async {
                      await SecureStorage().saveUserEmail(
                        "google_user@gmail.com",
                      );
                      Get.to(
                        () => const CompleteProfileScreen(
                          email: "google_user@gmail.com",
                        ),
                      );
                    },
                    child: Image.network(
                      "https://cdn-icons-png.flaticon.com/512/300/300221.png",
                      height: AppSize.w(26),
                    ),
                  ),
                  SizedBox(width: AppSize.w(16)),
                  _socialCircleButton(
                    onTap: () {
                      Get.to(MainScreen());
                    },
                    child: Icon(
                      Icons.apple,
                      color: AppColors.black,
                      size: AppSize.sp(35),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSize.h(20)),

              /// 🔒 Bottom Safety Text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: AppColors.grey,
                    size: AppSize.sp(12),
                  ),
                  SizedBox(width: AppSize.w(5)),
                  Text(
                    "Your data is safe and secure",
                    style: AppTextStyles.small,
                  ),
                ],
              ),

              SizedBox(height: AppSize.h(10)),

              /// 📝 Terms of Use - Privacy Policy
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.small.copyWith(color: AppColors.grey),
                  children: [
                    TextSpan(text: "Terms of Use"),
                    TextSpan(text: "  •  "),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: Get.context!,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColors.cardBg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSize.w(16),
                                ),
                                side: BorderSide(color: AppColors.cardBorder),
                              ),
                              title: Text(
                                "Privacy Policy",
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              content: SingleChildScrollView(
                                child: Text(
                                  "We value your privacy. Your personal data is collected only to provide and improve our services. We do not sell or share your information with third parties without your consent.\n\nData collected includes your email and usage information. You may request deletion of your data at any time by contacting our support team.",
                                  style: AppTextStyles.small.copyWith(
                                    color: AppColors.grey,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: Text(
                                    "Got it",
                                    style: AppTextStyles.body.copyWith(
                                      color: const Color(0xFF9B59B6),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text(
                          "Privacy Policy",
                          style: AppTextStyles.small.copyWith(
                            color: const Color(0xFF9B59B6),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFF9B59B6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSize.h(12)),
            ],
          ),
        ),
      ),
    );
  }

  /// ── Divider ──
  Widget _orDivider({String text = "Or"}) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.cardBorder)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSize.w(12)),
          child: Text(text, style: AppTextStyles.small),
        ),
        Expanded(child: Divider(color: AppColors.cardBorder)),
      ],
    );
  }

  /// ── Login Option Button ──
  Widget _loginOptionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showArrow = false,
    bool showRightIcon = false,
    bool showGradientBorder = false,
  }) {
    Widget container = Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w(16),
        vertical: AppSize.h(14),
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppSize.w(14)),
        border: showGradientBorder
            ? null
            : Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          /// ✅ Icon with subtle circle background
          Container(
            width: AppSize.w(42),
            height: AppSize.h(42),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface, // dark fill
              border: Border.all(
                color: AppColors.cardBorder, // subtle border ring
                width: 1.2,
              ),
            ),
            child: Icon(icon, color: AppColors.white, size: AppSize.sp(20)),
          ),

          SizedBox(width: AppSize.w(14)),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: AppSize.sp(14),
                  ),
                ),
                SizedBox(height: AppSize.h(2)),
                Text(
                  subtitle,
                  style: AppTextStyles.small.copyWith(fontSize: 10.sp),
                ),
              ],
            ),
          ),

          if (showArrow)
            Icon(
              Icons.chevron_right,
              color: AppColors.grey,
              size: AppSize.sp(22),
            ),

          if (showRightIcon)
            /// ✅ Right person icon also with circle
            Container(
              width: AppSize.w(36),
              height: AppSize.h(36),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.cardBorder, width: 1.2),
              ),
              child: Icon(
                Icons.person_outline,
                color: AppColors.white,
                size: AppSize.sp(18),
              ),
            ),
        ],
      ),
    );

    if (showGradientBorder) {
      container = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSize.w(14)),
          gradient: const LinearGradient(
            colors: [Color(0xFF9B59B6), Color(0xFF3498DB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(1.5),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(AppSize.w(13)),
          ),
          child: container,
        ),
      );
    }

    return GestureDetector(onTap: onTap, child: container);
  }

  /// ── Social Circle Button ──
  Widget _socialCircleButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSize.w(62),
        height: AppSize.h(62),
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}
