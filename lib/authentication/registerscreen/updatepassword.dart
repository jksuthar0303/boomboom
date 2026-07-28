import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controller/auth_controller.dart';
import '../../constant/appsize.dart';
import '../../constant/apptextstyle.dart';
import '../../constant/colors.dart';
import '../../widget/bouncelogo.dart';
import '../../widget/outlinedbutton.dart';

class Updatepassword extends StatefulWidget {
  const Updatepassword({super.key});

  @override
  State<Updatepassword> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<Updatepassword> {
  final AuthController _controller = Get.put(AuthController());
  String email = "";
  String password = "";
  bool isPasswordHidden = true;

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
            Center(child: BounceLogo(imagePath: "assets/logo.png", size: 120)),
            Column(
              children: [
                Center(
                  child: Text(
                    "Start Your Journey",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading.copyWith(
                      fontSize: AppSize.sp(26), // 🔥 bada
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                SizedBox(height: AppSize.h(5)),

                Center(
                  child: Text(
                    "Update Your Password",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subHeading.copyWith(
                      fontSize: AppSize.sp(16),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSize.h(20)),
            _label("Email"),
            SizedBox(height: AppSize.h(8)),

            _neuField(
              child: Row(
                children: [
                  Icon(Icons.email, color: AppColors.textSecondary),
                  SizedBox(width: AppSize.w(10)),

                  Expanded(
                    child: TextField(
                      onChanged: (v) {
                        setState(() => email = v);
                      },
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter email",
                        hintStyle: AppTextStyles.body,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSize.h(20)),

            /// 🔥 PASSWORD
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
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter password",
                        hintStyle: AppTextStyles.body,
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

            /// 🔥 PASSWORD
            _label(" Confirm Password"),
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
                      ),
                      decoration: InputDecoration(
                        hintText: "Confirm  password",
                        hintStyle: AppTextStyles.body,
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

            const Spacer(),

            /// 🔥 STEP BOX
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
                  _step(" Confirm Password", isPasswordDone),
                ],
              ),
            ),

            SizedBox(height: 10),

            /// 🔥 LOGIN BUTTON
            Obx(
              () => _controller.isLoading.value
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    )
                  : GradientBorderButton(
                      title: "Update Password",
                      isTablet: isTablet,
                      width: 400,
                      height: 55,
                      onTap: () {
                        _controller.updatePassword(
                          email: email,
                          password: password,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 LABEL
  Widget _label(String text) {
    return Text(
      text,
      style: AppTextStyles.body.copyWith(
        color: AppColors.white,
        fontSize: AppSize.sp(13),
      ),
    );
  }

  /// 🔥 FIELD
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

  /// 🔥 STEP
  Widget _step(String title, bool done) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSize.h(6)),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_off,
            color: done ? Colors.green : AppColors.textSecondary,
            size: 18.sp,
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
