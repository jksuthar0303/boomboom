import 'package:boomboom/authentication/registerscreen/updatepassword.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:boomboom/controller/auth_controller.dart';
import 'package:boomboom/screens/profile/updateprofile/privacyscreen.dart';
import 'package:boomboom/screens/profile/updateprofile/termsscreen.dart';
import '../../constant/appsize.dart';
import '../../constant/apptextstyle.dart';
import '../../constant/colors.dart';
import '../../widget/bouncelogo.dart';
import '../../widget/outlinedbutton.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _authController = Get.put(AuthController());
  String email = "";
  String password = "";

  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    final isEmailDone = email.isNotEmpty;
    final isPasswordDone = password.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.primary,
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: EdgeInsets.all(AppSize.w(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSize.h(70)),

            Center(child: BounceLogo(imagePath: "assets/logos.png", size: 95)),

            Column(
              children: [
                Center(
                  child: Text(
                    "Start Your Journey",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading.copyWith(
                      fontSize: AppSize.sp(20),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                SizedBox(height: AppSize.h(5)),

                Center(
                  child: Text(
                    "Log In & Continue",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subHeading.copyWith(
                      fontSize: AppSize.sp(12),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSize.h(20)),

            /// EMAIL
            _label("Email"),
            SizedBox(height: AppSize.h(8)),

            _neuField(
              child: Row(
                children: [
                  Icon(Icons.email, color: AppColors.textSecondary),

                  SizedBox(width: AppSize.w(10)),

                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) {
                        setState(() => email = v.trim());
                      },
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white,
                        fontSize: AppSize.sp(12),
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter email",
                        hintStyle: AppTextStyles.body.copyWith(
                          fontSize: AppSize.sp(12),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSize.h(20)),

            /// PASSWORD
            _label("Password"),
            SizedBox(height: AppSize.h(8)),

            _neuField(
              child: Row(
                children: [
                  Icon(Icons.lock, color: AppColors.textSecondary),

                  SizedBox(width: AppSize.w(10)),

                  Expanded(
                    child: TextField(
                      obscureText: isPasswordHidden,
                      onChanged: (v) {
                        setState(() => password = v);
                      },
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white,
                        fontSize: AppSize.sp(12),
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter password",
                        hintStyle: AppTextStyles.body.copyWith(
                          fontSize: AppSize.sp(12),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isPasswordHidden = !isPasswordHidden;
                      });
                    },
                    child: Icon(
                      isPasswordHidden
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSize.h(20)),

            /// CONFIRM PASSWORD
            SizedBox(height: AppSize.h(10)),

            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Get.to(() => Updatepassword());
                },
                child: Text(
                  "Forgot Password ?",
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white,
                    fontSize: AppSize.sp(11),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const Spacer(),

            /// STEP BOX
            Container(
              padding: EdgeInsets.all(AppSize.w(15)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.r),
                color: AppColors.secondary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.03),
                    offset: const Offset(-3, -3),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.9),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _step("Email", isEmailDone),
                  _step("Password", isPasswordDone),
                ],
              ),
            ),

            SizedBox(height: AppSize.h(14)),

            /// 📝 Terms of Use - Privacy Policy (Above Login Button)
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: AppSize.sp(11),
                  ),
                  children: [
                    const TextSpan(text: "By logging in, you agree to our "),
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

            /// LOGIN BUTTON
            Obx(
              () => _authController.isLoading.value
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    )
                  : GradientBorderButton(
                      title: "Login",
                      isTablet: isTablet,
                      width: 400,
                      height: 55,
                      onTap: () {
                        _authController.login(email: email, password: password);
                      },
                    ),
            ),
            SizedBox(height: AppSize.h(10)),
          ],
        ),
      ),
    );
  }

  /// LABEL
  Widget _label(String text) {
    return Text(
      text,
      style: AppTextStyles.body.copyWith(
        color: AppColors.white,
        fontSize: AppSize.sp(11),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// FIELD
  Widget _neuField({required Widget child}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w(15)),
      height: AppSize.h(55),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.r),
        color: AppColors.secondary,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            offset: const Offset(-4, -4),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.9),
            offset: const Offset(4, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: child,
    );
  }

  /// STEP
  Widget _step(String title, bool done) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSize.h(6)),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_off,
            color: done ? Colors.green : AppColors.textSecondary,
            size: 15.sp,
          ),

          SizedBox(width: AppSize.w(10)),

          Text(
            title,
            style: AppTextStyles.body.copyWith(
              color: done ? AppColors.white : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
