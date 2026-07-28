import 'dart:async';

import 'package:boomboom/authentication/registerscreen/registerfirst.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sms_autofill/sms_autofill.dart';

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
  int seconds = 30;
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

  /// ✅ Yeh method auto call hota hai jab SMS aata hai
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
    // Last box pe focus le jao
    FocusScope.of(context).requestFocus(focusNodes[5]);
  }

  // ================= TIMER =================

  void startTimer() {
    seconds = 30;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (seconds == 0) {
        timer.cancel();
      } else {
        setState(() => seconds--);
      }
    });
  }

  // ================= DISPOSE =================

  @override
  void dispose() {
    timer?.cancel();
    cancel(); // ✅ sms_autofill listener cancel
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            "Please enter complete OTP",
            style: AppTextStyles.body.copyWith(color: Colors.white),
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            "Email verified successfully",
            style: AppTextStyles.body.copyWith(color: Colors.white),
          ),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(email: widget.email),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            "Something went wrong",
            style: AppTextStyles.body.copyWith(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= RESEND OTP =================

  Future<void> resendOtp() async {
    if (seconds != 0) return;

    setState(() => isResending = true);

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            "OTP sent successfully",
            style: AppTextStyles.body.copyWith(color: Colors.white),
          ),
        ),
      );

      startTimer();
      _startSmsListening(); // ✅ Resend ke baad dobara listen karo
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            "Failed to resend OTP",
            style: AppTextStyles.body.copyWith(color: Colors.white),
          ),
        ),
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

              SizedBox(height: AppSize.h(45)),

              // ================= ICON =================
              Center(
                child: Container(
                  width: isTablet ? AppSize.w(150) : AppSize.w(120),
                  height: isTablet ? AppSize.h(150) : AppSize.h(120),
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
                    size: isTablet ? 60.sp : 48.sp,
                  ),
                ),
              ),

              SizedBox(height: AppSize.h(45)),

              // ================= TITLE =================
              Center(
                child: Text(
                  "Email Verification",
                  style: AppTextStyles.heading.copyWith(
                    fontSize: isTablet ? 36.sp : 30.sp,
                  ),
                ),
              ),

              SizedBox(height: AppSize.h(14)),

              // ================= SUBTITLE =================
              Center(
                child: Text(
                  "Enter the 6-digit code sent to\n${widget.email}",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    height: 1.7,
                    fontSize: isTablet ? 16.sp : 14.sp,
                  ),
                ),
              ),

              SizedBox(height: AppSize.h(50)),

              // ================= OTP BOXES =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final isFilled = controllers[index].text.isNotEmpty;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: isTablet ? AppSize.w(82) : AppSize.w(48),
                    height: isTablet ? AppSize.h(90) : AppSize.h(58),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20.r),

                      // ✅ Border hamesha white — filled ho to bright, empty ho to soft white
                      border: Border.all(
                        color: isFilled
                            ? Colors
                                  .white // filled → pure white
                            : Colors.white.withValues(
                                alpha: 0.35,
                              ), // empty → soft white
                        width: isFilled ? 1.8 : 1.2,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: isFilled
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.15),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
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
                          fontSize: isTablet ? 32.sp : 24.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          setState(() {});
                          if (value.isNotEmpty && index < 5) {
                            FocusScope.of(
                              context,
                            ).requestFocus(focusNodes[index + 1]);
                          }
                          if (value.isEmpty && index > 0) {
                            FocusScope.of(
                              context,
                            ).requestFocus(focusNodes[index - 1]);
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

              SizedBox(height: AppSize.h(35)),

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

              SizedBox(height: AppSize.h(18)),

              // ================= RESEND =================
              Center(
                child: GestureDetector(
                  onTap: isResending ? null : resendOtp,
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

              SizedBox(height: AppSize.h(60)),

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
