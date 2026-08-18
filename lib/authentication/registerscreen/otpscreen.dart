import 'dart:async';
import 'dart:math';

import 'package:boomboom/authentication/registerscreen/registerfirst.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../backend/registerservice.dart';
import '../../backend/secure_storage.dart';
import '../../constant/appsize.dart';
import '../../constant/apptextstyle.dart';
import '../../constant/colors.dart';
import '../../widget/button.dart';

class EmailOtpScreen extends StatefulWidget {
  final String email;

  const EmailOtpScreen({super.key, required this.email});

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> with CodeAutoFill {
  // ================= CONTROLLERS =================

  final List<TextEditingController> controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

  bool isLoading = false;
  bool isResending = false;
  int seconds = 60;
  Timer? timer;

  // ================= INIT =================

  @override
  void initState() {
    super.initState();
    startTimer();
    _startSmsListening();
  }

  // ================= SMS AUTO FILL =================

  Future<void> _startSmsListening() async {
    await SmsAutoFill().listenForCode();
  }

  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      _fillOtpBoxes(code!);
    }
  }

  void _fillOtpBoxes(String otpCode) {
    for (int i = 0; i < 6 && i < otpCode.length; i++) {
      controllers[i].text = otpCode[i];
    }
    setState(() {});
    FocusScope.of(context).requestFocus(focusNodes[5]);
  }

  // ================= TIMER =================

  void startTimer() {
    seconds = 60;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (seconds == 0) {
        timer.cancel();
      } else {
        if (mounted) setState(() => seconds--);
      }
    });
  }

  // ================= DISPOSE =================

  @override
  void dispose() {
    timer?.cancel();
    cancel();
    SmsAutoFill().unregisterListener();
    for (var c in controllers) {
      c.dispose();
    }
    for (var f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ================= OTP =================

  String get otp => controllers.map((e) => e.text).join();

  // ================= VERIFY OTP =================

  Future<void> verifyOtp() async {
    if (otp.length != 6) {
      Get.snackbar(
        "Incomplete Code",
        "Please enter the complete 6-digit OTP",
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 🛡️ Validate with stored OTP and 5-minute expiry
      final verificationResult = await SecureStorage().verifyEmailOtp(
        email: widget.email,
        enteredOtp: otp,
      );

      if (!mounted) return;

      if (verificationResult["success"] == true) {
        Get.snackbar(
          "Verified!",
          "Email verified successfully! Proceeding to setup your profile...",
          backgroundColor: const Color(0xFF1E293B),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676)),
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
        );

        await Future.delayed(const Duration(milliseconds: 600));

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(email: widget.email),
          ),
        );
      } else {
        Get.snackbar(
          "Verification Failed",
          verificationResult["message"] ?? "Invalid OTP code",
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Verification failed. Please try again.",
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= RESEND OTP =================

  Future<void> resendOtp() async {
    if (seconds != 0 || isResending) return;

    setState(() => isResending = true);

    try {
      // 1. Generate new 6-digit OTP
      final newOtp = (100000 + Random().nextInt(900000)).toString();
      debugPrint("🚀 [Resend OTP] Generated: $newOtp for ${widget.email}");

      // 2. Call SendEmailOTP SOAP API
      await RegisterService().sendEmailOTP(
        email: widget.email,
        otp: newOtp,
      );

      // 3. Save updated OTP in SecureStorage with fresh 5-minute expiry
      await SecureStorage().saveEmailOtp(email: widget.email, otp: newOtp);

      if (!mounted) return;

      // Clear input boxes
      for (var c in controllers) {
        c.clear();
      }
      FocusScope.of(context).requestFocus(focusNodes[0]);

      Get.snackbar(
        "New Code Sent!",
        "A fresh OTP has been sent to ${widget.email}. (Please check your Inbox / Spam folder)",
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        icon: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF00E676)),
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(12.w),
      );

      startTimer();
      _startSmsListening();
    } catch (e) {
      Get.snackbar(
        "Failed to resend",
        "Unable to send new OTP. Please check your network and try again.",
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => isResending = false);
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? AppSize.w(60) : AppSize.w(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSize.h(20)),

              // ================= BACK =================
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: isTablet ? AppSize.w(58) : AppSize.w(46),
                  height: isTablet ? AppSize.h(58) : AppSize.h(46),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: isTablet ? 22.sp : 18.sp,
                  ),
                ),
              ),

              SizedBox(height: AppSize.h(30)),

              // ================= ICON =================
              Center(
                child: Container(
                  width: isTablet ? AppSize.w(140) : AppSize.w(110),
                  height: isTablet ? AppSize.h(140) : AppSize.h(110),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.25),
                        AppColors.purple.withValues(alpha: 0.15),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    Icons.mark_email_read_rounded,
                    color: AppColors.accent,
                    size: isTablet ? 56.sp : 44.sp,
                  ),
                ),
              ),

              SizedBox(height: AppSize.h(30)),

              // ================= TITLE =================
              Center(
                child: Text(
                  "Email Verification",
                  style: AppTextStyles.heading.copyWith(
                    fontSize: isTablet ? 34.sp : 26.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: AppSize.h(10)),

              // ================= SUBTITLE =================
              Center(
                child: Text(
                  "Enter the 6-digit code sent to\n${widget.email}",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    height: 1.5,
                    fontSize: isTablet ? 15.sp : 13.sp,
                    color: Colors.white70,
                  ),
                ),
              ),

              SizedBox(height: AppSize.h(16)),

              // ================= 💡 SPAM FOLDER & EXPIRY NOTICE =================
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 10.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.accent,
                      size: 18.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        "Note: If you don't find the email in your inbox, please check your Spam / Junk folder. Code is valid for 5 minutes.",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 11.5.sp,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSize.h(30)),

              // ================= OTP BOXES =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final isFilled = controllers[index].text.isNotEmpty;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isTablet ? AppSize.w(80) : AppSize.w(46),
                    height: isTablet ? AppSize.h(86) : AppSize.h(56),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isFilled
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        width: isFilled ? 1.8 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isFilled
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: TextField(
                        controller: controllers[index],
                        focusNode: focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: isTablet ? 30.sp : 22.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          setState(() {});
                          if (value.isNotEmpty && index < 5) {
                            FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                          }
                          if (value.isEmpty && index > 0) {
                            FocusScope.of(context).requestFocus(focusNodes[index - 1]);
                          }
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: "",
                        ),
                      ),
                    ),
                  );
                }),
              ),

              SizedBox(height: AppSize.h(28)),

              // ================= TIMER =================
              Center(
                child: RichText(
                  text: TextSpan(
                    text: "Resend code in ",
                    style: AppTextStyles.body,
                    children: [
                      TextSpan(
                        text: "00:${seconds.toString().padLeft(2, '0')}",
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppSize.h(14)),

              // ================= RESEND =================
              Center(
                child: GestureDetector(
                  onTap: seconds == 0 && !isResending ? resendOtp : null,
                  child: Text(
                    isResending ? "Sending..." : "Resend OTP",
                    style: AppTextStyles.body.copyWith(
                      color: seconds == 0 ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              SizedBox(height: AppSize.h(40)),

              // ================= BUTTON =================
              PrimaryButton(
                title: isLoading ? "Verifying..." : "Verify Email",
                isTablet: isTablet,
                onTap: isLoading ? () {} : verifyOtp,
              ),

              SizedBox(height: AppSize.h(30)),
            ],
          ),
        ),
      ),
    );
  }
}
