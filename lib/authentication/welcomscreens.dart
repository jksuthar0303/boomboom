import 'package:boomboom/authentication/registerscreen/login.dart';
import 'package:boomboom/authentication/registerscreen/otpscreen.dart';
import 'package:boomboom/authentication/registerscreen/registerfirst.dart';
import 'package:boomboom/backend/permission_service.dart';
import 'package:boomboom/backend/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'dart:convert';
import 'dart:math';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:xml/xml.dart' as xml;
import '../backend/registerservice.dart';
import '../controller/auth_controller.dart';
import '../constant/appsize.dart';
import '../constant/apptextstyle.dart';
import '../constant/colors.dart';
import '../screens/bottombar.dart';
import '../screens/profile/updateprofile/privacyscreen.dart';
import '../screens/profile/updateprofile/termsscreen.dart';
import '../widget/bouncelogo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController emailController = TextEditingController();
  bool _locationPermissionAsked = false;
  bool _isGoogleLoading = false;
  bool _isSendingOtp = false;

  Future<void> _handleSendEmailOtp() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar(
        "Error",
        "Please enter your email address",
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      Get.snackbar(
        "Invalid Email",
        "Please enter a valid email address",
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_isSendingOtp) return;
    setState(() => _isSendingOtp = true);

    try {
      // 1. Generate 6-digit random OTP
      final otp = (100000 + Random().nextInt(900000)).toString();
      debugPrint("🚀 [WelcomeScreen] Generated OTP: $otp for $email");

      // 2. Call SendEmailOTP SOAP API
      await RegisterService().sendEmailOTP(email: email, otp: otp);

      // 3. Save OTP in SecureStorage with 5-minute expiry
      await SecureStorage().saveUserEmail(email);
      await SecureStorage().saveEmailOtp(email: email, otp: otp);

      if (!mounted) return;
      setState(() => _isSendingOtp = false);

      // 4. Show success snackbar with Spam folder tip
      Get.snackbar(
        "OTP Sent Successfully!",
        "6-digit code has been sent to $email. (Check your Inbox / Spam folder)",
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        icon: const Icon(
          Icons.mark_email_read_rounded,
          color: Color(0xFF00E676),
        ),
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(12.w),
        borderRadius: 12.r,
      );

      // 5. Navigate to EmailOtpScreen
      Get.to(
        () => EmailOtpScreen(email: email),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 400),
      );
    } catch (e) {
      debugPrint("❌ [WelcomeScreen] Error sending OTP: $e");
      if (mounted) setState(() => _isSendingOtp = false);
      Get.snackbar(
        "Failed to send OTP",
        "Unable to send verification code. Please check your network & try again.",
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

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

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);

      // Clear previous cached session so account selection dialog always appears
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        // User cancelled sign in dialog
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      final String googleEmail = account.email.trim();

      // Check if user exists with profile in backend
      final response = await RegisterService().showCompleteProfile(
        email: googleEmail,
      );

      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        final res = doc.findAllElements('ShowCompleteProfileResult');
        if (res.isNotEmpty) {
          final Map<String, dynamic> profileJson = jsonDecode(
            res.first.innerText,
          );
          final int status = profileJson["Status"] ?? 0;
          if (status == 1 && profileJson["ResultSets"] is List) {
            final List resultSets = profileJson["ResultSets"];
            if (resultSets.length >= 2 && (resultSets[1] as List).isNotEmpty) {
              // Existing registered user -> Save & Go to MainScreen
              await SecureStorage().saveUserEmail(googleEmail);
              final AuthController authController = Get.put(AuthController());
              await authController.fetchAndStoreFullProfile(email: googleEmail);
              await authController.updateFCMTokenIfAvailable(
                email: googleEmail,
              );

              if (mounted) setState(() => _isGoogleLoading = false);
              Get.offAll(
                () => const MainScreen(),
                transition: Transition.rightToLeftWithFade,
                duration: const Duration(milliseconds: 600),
              );
              return;
            }
          }
        }
      }

      // New User or Incomplete Profile -> Save email & Go to CompleteProfileScreen
      await SecureStorage().saveUserEmail(googleEmail);
      if (mounted) setState(() => _isGoogleLoading = false);
      Get.to(() => CompleteProfileScreen(email: googleEmail));
    } catch (e) {
      if (mounted) setState(() => _isGoogleLoading = false);
      debugPrint("[Google Sign In Error]: $e");
      Get.snackbar(
        "Google Sign-In",
        "Sign in failed. Please try again.",
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
      );
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

              /// 📝 Terms of Use - Privacy Policy (Above Send Email OTP Button)
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.grey,
                      fontSize: AppSize.sp(11),
                    ),
                    children: [
                      const TextSpan(text: "By continuing, you agree to our "),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () {
                            Get.to(
                              () => const TermsOfUseScreen(),
                              transition: Transition.cupertino,
                              duration: const Duration(milliseconds: 350),
                            );
                          },
                          child: Text(
                            "Terms of Use",
                            style: AppTextStyles.small.copyWith(
                              color: const Color(0xFF9B59B6),
                              fontWeight: FontWeight.w600,
                              fontSize: AppSize.sp(11),
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFF9B59B6),
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: " and "),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () {
                            Get.to(
                              () => const PrivacyPolicyScreen(),
                              transition: Transition.cupertino,
                              duration: const Duration(milliseconds: 350),
                            );
                          },
                          child: Text(
                            "Privacy Policy",
                            style: AppTextStyles.small.copyWith(
                              color: const Color(0xFF9B59B6),
                              fontWeight: FontWeight.w600,
                              fontSize: AppSize.sp(11),
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFF9B59B6),
                            ),
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
                onTap: _isSendingOtp ? null : _handleSendEmailOtp,
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
                      if (_isSendingOtp)
                        SizedBox(
                          width: AppSize.w(18),
                          height: AppSize.w(18),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      else ...[
                        Text("Send Email OTP", style: AppTextStyles.button),
                        SizedBox(width: AppSize.w(10)),
                        Icon(
                          Icons.send_outlined,
                          color: AppColors.white,
                          size: AppSize.sp(16),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // SizedBox(height: AppSize.h(22)),

              // /// ── Or continue with ──
              // _orDivider(text: "Or continue with"),

              // SizedBox(height: AppSize.h(18)),

              // /// 🌐 Social Buttons: Facebook + Google
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     _socialCircleButton(
              //       onTap: () {},
              //       child: ClipOval(
              //         child: Image.network(
              //           "https://cdn-icons-png.flaticon.com/512/733/733547.png",
              //           height: AppSize.w(38),
              //           width: AppSize.w(38),
              //           fit: BoxFit.cover,
              //         ),
              //       ),
              //     ),
              //     SizedBox(width: AppSize.w(20)),
              //     _socialCircleButton(
              //       onTap: _isGoogleLoading ? () {} : _handleGoogleSignIn,
              //       child: _isGoogleLoading
              //           ? SizedBox(
              //               width: AppSize.w(24),
              //               height: AppSize.w(24),
              //               child: const CircularProgressIndicator(
              //                 strokeWidth: 2.5,
              //                 valueColor: AlwaysStoppedAnimation<Color>(
              //                   Color(0xFF9B59B6),
              //                 ),
              //               ),
              //             )
              //           : Image.network(
              //               "https://cdn-icons-png.flaticon.com/512/300/300221.png",
              //               height: AppSize.w(26),
              //             ),
              //     ),
              //   ],
              // ),

              SizedBox(height: AppSize.h(24)),

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

              SizedBox(height: AppSize.h(16)),
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
