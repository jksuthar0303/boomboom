import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xml/xml.dart' as xml;

import '../../backend/registerservice.dart';
import '../../backend/secure_storage.dart';
import '../../constant/appsize.dart';
import '../../constant/apptextstyle.dart';
import '../../constant/colors.dart';
import '../../widget/bouncelogo.dart';
import 'login.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Current step: 0 = Enter Email, 1 = Verify OTP, 2 = New & Confirm Password
  int _currentStep = 0;

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State flags
  bool _isLoading = false;
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  // Timer for OTP
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startOtpTimer() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        if (mounted) {
          setState(() => _secondsRemaining--);
        }
      }
    });
  }

  // ================= STEP 1: SEND OTP =================
  Future<void> _sendOtp({bool isResend = false}) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackbar("Error", "Please enter your email address", isError: true);
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackbar("Invalid Email", "Please enter a valid email address",
          isError: true);
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // 1. Generate 6-digit random OTP
      final otp = (100000 + Random().nextInt(900000)).toString();
      debugPrint("🚀 [ForgotPassword] Generated OTP: $otp for $email");

      // 2. Call SendEmailOTP SOAP API
      await RegisterService().sendEmailOTP(
        email: email,
        otp: otp,
      );

      // 3. Save OTP in SecureStorage with 5-minute expiry
      await SecureStorage().saveEmailOtp(email: email, otp: otp);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!isResend) _currentStep = 1;
      });

      _startOtpTimer();

      _showSnackbar(
        isResend ? "OTP Resent Successfully!" : "OTP Sent Successfully!",
        "6-digit code has been sent to $email. (Check Inbox / Spam folder)",
        isError: false,
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("[ForgotPassword SendOtp Error]: $e");
      _showSnackbar("Error", "Failed to send OTP. Please try again.",
          isError: true);
    }
  }

  // ================= STEP 2: VERIFY OTP =================
  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final enteredOtp =
        _otpControllers.map((c) => c.text.trim()).join().trim();

    if (enteredOtp.length < 6) {
      _showSnackbar("Incomplete OTP", "Please enter complete 6-digit code",
          isError: true);
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final verifyResult = await SecureStorage().verifyEmailOtp(
        email: email,
        enteredOtp: enteredOtp,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      final bool isSuccess = verifyResult["success"] == true;
      final String msg = verifyResult["message"] ?? "";

      if (isSuccess) {
        _showSnackbar("Verified!", "Email verified successfully.",
            isError: false);
        setState(() => _currentStep = 2);
      } else {
        _showSnackbar(
          "Verification Failed",
          msg.isNotEmpty ? msg : "Invalid OTP. Please check and try again.",
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnackbar("Error", "Failed to verify OTP: $e", isError: true);
    }
  }

  // ================= STEP 3: RESET PASSWORD =================
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass.isEmpty) {
      _showSnackbar("Error", "Please enter new password", isError: true);
      return;
    }
    if (newPass.length < 6) {
      _showSnackbar("Weak Password", "Password must be at least 6 characters",
          isError: true);
      return;
    }
    if (confirmPass.isEmpty) {
      _showSnackbar("Error", "Please confirm your password", isError: true);
      return;
    }
    if (newPass != confirmPass) {
      _showSnackbar("Mismatch", "New password and Confirm password do not match",
          isError: true);
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final response = await RegisterService().forgotPassword(
        email: email,
        newPassword: newPass,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final resultElements =
            document.findAllElements('ForgotPasswordResult');

        if (resultElements.isNotEmpty) {
          final String jsonResultStr = resultElements.first.innerText;
          try {
            final Map<String, dynamic> resultJson = jsonDecode(jsonResultStr);
            final int status = resultJson["Status"] ?? 0;
            final String message =
                resultJson["Message"] ?? "An error occurred.";

            if (status == 1) {
              // Clear stored OTP
              await SecureStorage().clearEmailOtp(email);

              // Show success dialog
              _showSuccessDialog();
              return;
            } else {
              _showSnackbar("Failed", message, isError: true);
              return;
            }
          } catch (e) {
            debugPrint("[ForgotPassword JSON Parse Error]: $e");
          }
        }
      }

      _showSnackbar("Error", "Failed to reset password. Please try again.",
          isError: true);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("[ForgotPassword Reset Error]: $e");
      _showSnackbar("Error", "Connection error. Please try again.",
          isError: true);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22.r),
          side: BorderSide(
            color: const Color(0xFF00E676).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF00E676),
                size: 26,
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              "Success!",
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Text(
          "Your password has been reset successfully! You can now log in using your new password.",
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            color: Colors.white70,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Get.offAll(() => const LoginScreen());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B59B6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
            child: Text(
              "Go to Login",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String title, String message, {required bool isError}) {
    Get.snackbar(
      title,
      message,
      backgroundColor:
          isError ? const Color(0xFFE74C3C) : const Color(0xFF1E293B),
      colorText: Colors.white,
      icon: Icon(
        isError ? Icons.error_outline_rounded : Icons.mark_email_read_rounded,
        color: isError ? Colors.white : const Color(0xFF00E676),
      ),
      duration: Duration(seconds: isError ? 4 : 5),
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(12.w),
      borderRadius: 12.r,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSize.w(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: AppSize.h(16)),

              /// Top Navigation & Title
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_currentStep > 0) {
                        setState(() => _currentStep--);
                      } else {
                        Get.back();
                      }
                    },
                    child: Container(
                      width: AppSize.w(40),
                      height: AppSize.h(40),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.white,
                        size: AppSize.sp(18),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildStepIndicator(),
                ],
              ),

              SizedBox(height: AppSize.h(14)),

              /// Logo
              BounceLogo(imagePath: "assets/logos.png", size: 90),

              SizedBox(height: AppSize.h(12)),

              /// Main Dynamic Content based on _currentStep
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildCurrentStepView(),
              ),

              SizedBox(height: AppSize.h(30)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFF9B59B6).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        "Step ${_currentStep + 1} of 3",
        style: GoogleFonts.poppins(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF00E5FF),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Email();
      case 1:
        return _buildStep2Otp();
      case 2:
        return _buildStep3NewPassword();
      default:
        return _buildStep1Email();
    }
  }

  // ================= STEP 1: EMAIL UI =================
  Widget _buildStep1Email() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            "Forgot Password 🔐",
            style: AppTextStyles.heading.copyWith(
              fontSize: AppSize.sp(20),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Center(
          child: Text(
            "Enter your registered email address to receive a 6-digit verification code.",
            textAlign: TextAlign.center,
            style: AppTextStyles.small.copyWith(
              color: Colors.white70,
              fontSize: 12.sp,
            ),
          ),
        ),
        SizedBox(height: 24.h),

        /// Email Input
        Text(
          "Email Address",
          style: AppTextStyles.small.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
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
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.mail_outline_rounded,
                  color: const Color(0xFF9B59B6),
                  size: AppSize.sp(20),
                ),
                SizedBox(width: AppSize.w(10)),
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: "e.g. name@example.com",
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

        SizedBox(height: 24.h),

        /// Send OTP Button
        _buildActionButton(
          title: "Send Verification Code",
          icon: Icons.arrow_forward_rounded,
          onTap: () => _sendOtp(isResend: false),
        ),

        SizedBox(height: 18.h),

        /// Back to login link
        Center(
          child: GestureDetector(
            onTap: () => Get.back(),
            child: Text(
              "Remember your password? Log In",
              style: GoogleFonts.poppins(
                color: const Color(0xFF00E5FF),
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================= STEP 2: OTP UI =================
  Widget _buildStep2Otp() {
    final email = _emailController.text.trim();

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            "Verify Code 📩",
            style: AppTextStyles.heading.copyWith(
              fontSize: AppSize.sp(20),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.small.copyWith(
                color: Colors.white70,
                fontSize: 12.sp,
              ),
              children: [
                const TextSpan(text: "Enter 6-digit code sent to "),
                TextSpan(
                  text: email,
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 18.h),

        /// Spam Tip Banner
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFF59E0B),
                size: 18,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  "Didn't receive the email? Please check your Spam / Junk folder. OTP is valid for 5 minutes.",
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: const Color(0xFFFCD34D),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 22.h),

        /// 6 OTP Digits
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return _buildOtpBox(index);
          }),
        ),

        SizedBox(height: 18.h),

        /// Resend Timer & Button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_secondsRemaining > 0)
              Text(
                "Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}",
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.white60,
                ),
              )
            else
              GestureDetector(
                onTap: () => _sendOtp(isResend: true),
                child: Text(
                  "Resend Code",
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00E676),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),

        SizedBox(height: 22.h),

        /// Verify OTP Button
        _buildActionButton(
          title: "Verify & Continue",
          icon: Icons.check_circle_outline_rounded,
          onTap: _verifyOtp,
        ),

        SizedBox(height: 14.h),

        /// Change email
        Center(
          child: TextButton(
            onPressed: () => setState(() => _currentStep = 0),
            child: Text(
              "Change Email Address",
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Colors.white60,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 44.w,
      height: 52.h,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _otpControllers[index].text.isNotEmpty
              ? const Color(0xFF9B59B6)
              : Colors.white.withValues(alpha: 0.15),
          width: _otpControllers[index].text.isNotEmpty ? 1.8 : 1,
        ),
        boxShadow: [
          if (_otpControllers[index].text.isNotEmpty)
            BoxShadow(
              color: const Color(0xFF9B59B6).withValues(alpha: 0.3),
              blurRadius: 8,
            ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          decoration: const InputDecoration(border: InputBorder.none),
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (index < 5) {
                FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
              } else {
                _otpFocusNodes[index].unfocus();
              }
            } else {
              if (index > 0) {
                FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
              }
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  // ================= STEP 3: NEW PASSWORD UI =================
  Widget _buildStep3NewPassword() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            "Set New Password 🔑",
            style: AppTextStyles.heading.copyWith(
              fontSize: AppSize.sp(20),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Center(
          child: Text(
            "Create a new password that is secure and easy for you to remember.",
            textAlign: TextAlign.center,
            style: AppTextStyles.small.copyWith(
              color: Colors.white70,
              fontSize: 12.sp,
            ),
          ),
        ),
        SizedBox(height: 24.h),

        /// New Password
        Text(
          "New Password",
          style: AppTextStyles.small.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        _buildPasswordField(
          controller: _newPasswordController,
          hintText: "Enter new password",
          isHidden: _isPasswordHidden,
          onToggle: () =>
              setState(() => _isPasswordHidden = !_isPasswordHidden),
        ),

        SizedBox(height: 16.h),

        /// Confirm Password
        Text(
          "Confirm New Password",
          style: AppTextStyles.small.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        _buildPasswordField(
          controller: _confirmPasswordController,
          hintText: "Re-enter new password",
          isHidden: _isConfirmPasswordHidden,
          onToggle: () => setState(
              () => _isConfirmPasswordHidden = !_isConfirmPasswordHidden),
        ),

        SizedBox(height: 28.h),

        /// Update Password Button
        _buildActionButton(
          title: "Update Password",
          icon: Icons.lock_reset_rounded,
          onTap: _resetPassword,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool isHidden,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
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
          borderRadius: BorderRadius.circular(13.r),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: const Color(0xFF9B59B6),
              size: AppSize.sp(20),
            ),
            SizedBox(width: AppSize.w(10)),
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: isHidden,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: AppTextStyles.body.copyWith(
                    color: AppColors.grey,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            GestureDetector(
              onTap: onToggle,
              child: Icon(
                isHidden
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white54,
                size: 20.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        height: AppSize.h(50),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSize.w(14)),
          gradient: const LinearGradient(
            colors: [Color(0xFF9B59B6), Color(0xFF3498DB)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9B59B6).withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              SizedBox(
                width: AppSize.w(20),
                height: AppSize.w(20),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else ...[
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: AppSize.w(10)),
              Icon(
                icon,
                color: AppColors.white,
                size: AppSize.sp(18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
