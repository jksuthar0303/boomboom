import 'package:boomboom/authentication/registerscreen/registerfirst.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════
// 🔥 SIGNUP SCREEN
// Dark premium aesthetic — matches app theme
// ═══════════════════════════════════════════
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _retypeCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureRetype = true;
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ─────────────────────────────────────────
  // Colors
  // ─────────────────────────────────────────
  static const _bg = Color(0xFF0A0B0F);
  static const _cardBg = Color(0xFF0F1017);
  static const _blue = Color(0xFF2B5CE6);
  static const _blueLight = Color(0xFF4B7BFF);
  static const _border = Color(0xFF1C1D2A);
  // ignore: unused_field
  static const _inputBg = Color(0xFF13141E);
  // ignore: unused_field
  static const _grey = Color(0xFF6B7280);
  static const _greyLight = Color(0xFFAAAAAA);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _retypeCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // 🔥 SUBMIT — Create Account → Next Screen
  // ─────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    // 🔥 NEXT PAGE PE NAVIGATE KARO
    // Yahan apna next screen class naam replace karo
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CompleteProfileScreen(), // ← apna screen yahan dalo
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🔥 BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ─── BACKGROUND GLOW ───
          Positioned(
            top: -100.h,
            left: -80.w,
            child: Container(
              width: 300.w,
              height: 300.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _blue.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80.h,
            right: -60.w,
            child: Container(
              width: 250.w,
              height: 250.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _blueLight.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ─── MAIN CONTENT ───
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 40.h),

                        // ─── LOGO / ICON ───
                        Center(
                          child: Container(
                            width: 70.w,
                            height: 70.w,
                            decoration: BoxDecoration(
                              color: _blue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(22.r),
                              border: Border.all(
                                  color: _blue.withValues(alpha: 0.3), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: _blue.withValues(alpha: 0.25),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.favorite_rounded,
                              color: _blue,
                              size: 32.sp,
                            ),
                          ),
                        ),

                        SizedBox(height: 28.h),

                        // ─── HEADING ───
                        Center(
                          child: Text(
                            'Create Account',
                            style: GoogleFonts.poppins(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Center(
                          child: Text(
                            'Find your perfect match today ✨',
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              color: _greyLight,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),

                        SizedBox(height: 36.h),

                        // ─── FORM CARD ───
                        Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(28.r),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // NAME
                              _buildField(
                                controller: _nameCtrl,
                                label: 'Full Name',
                                hint: 'Enter your name',
                                icon: Icons.person_rounded,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Name is required';
                                  }
                                  if (v.trim().length < 2) {
                                    return 'Name too short';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 16.h),

                              // EMAIL
                              _buildField(
                                controller: _emailCtrl,
                                label: 'Email Address',
                                hint: 'Enter your email',
                                icon: Icons.email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Email is required';
                                  }
                                  final emailReg = RegExp(
                                      r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
                                  if (!emailReg.hasMatch(v.trim())) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 16.h),

                              // PASSWORD
                              _buildField(
                                controller: _passCtrl,
                                label: 'Password',
                                hint: 'Create a password',
                                icon: Icons.lock_rounded,
                                obscure: _obscurePass,
                                toggleObscure: () => setState(
                                        () => _obscurePass = !_obscurePass),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (v.length < 6) {
                                    return 'Minimum 6 characters';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 16.h),

                              // RETYPE PASSWORD
                              _buildField(
                                controller: _retypeCtrl,
                                label: 'Confirm Password',
                                hint: 'Re-enter your password',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscureRetype,
                                toggleObscure: () => setState(
                                        () => _obscureRetype = !_obscureRetype),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Please confirm password';
                                  }
                                  if (v != _passCtrl.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // ─── SIGN UP BUTTON ───
                        SizedBox(
                          width: double.infinity,
                          height: 54.h,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _blue,
                              disabledBackgroundColor: _blue.withValues(alpha: 0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.r),
                              ),
                              shadowColor: _blue.withValues(alpha: 0.5),
                            ).copyWith(
                              elevation: WidgetStateProperty.all(8),
                            ),
                            child: _isLoading
                                ? SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                                : Text(
                              'Next',
                              style: GoogleFonts.poppins(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // ─── DIVIDER (commented out) ───
                        // SizedBox(height: 20.h),
                        // Row(
                        //   children: [
                        //     Expanded(child: Divider(color: _border, thickness: 1)),
                        //     Padding(
                        //       padding: EdgeInsets.symmetric(horizontal: 12.w),
                        //       child: Text(
                        //         'or sign up with',
                        //         style: GoogleFonts.poppins(fontSize: 11.sp, color: _grey),
                        //       ),
                        //     ),
                        //     Expanded(child: Divider(color: _border, thickness: 1)),
                        //   ],
                        // ),

                        // ─── SOCIAL BUTTONS (commented out) ───
                        // SizedBox(height: 20.h),
                        // Row(
                        //   children: [
                        //     Expanded(
                        //       child: _socialBtn(
                        //         label: 'Google',
                        //         icon: Icons.g_mobiledata_rounded,
                        //         color: const Color(0xFFEA4335),
                        //       ),
                        //     ),
                        //     SizedBox(width: 12.w),
                        //     Expanded(
                        //       child: _socialBtn(
                        //         label: 'Apple',
                        //         icon: Icons.apple_rounded,
                        //         color: Colors.white,
                        //       ),
                        //     ),
                        //   ],
                        // ),

                        // ─── LOGIN LINK (commented out) ───
                        // SizedBox(height: 28.h),
                        // Center(
                        //   child: RichText(
                        //     text: TextSpan(
                        //       text: 'Already have an account? ',
                        //       style: GoogleFonts.poppins(
                        //         fontSize: 13.sp,
                        //         color: _greyLight,
                        //       ),
                        //       children: [
                        //         TextSpan(
                        //           text: 'Log In',
                        //           style: GoogleFonts.poppins(
                        //             fontSize: 13.sp,
                        //             color: _blue,
                        //             fontWeight: FontWeight.w600,
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),

                        SizedBox(height: 32.h),
                      ],
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

  // ─────────────────────────────────────────
  // 🔥 INPUT FIELD BUILDER
  // ─────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? toggleObscure,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFAAAAAA),
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13.sp,
              color: const Color(0xFF4A4B5A),
            ),
            filled: true,
            fillColor: const Color(0xFF13141E),
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Icon(icon, color: const Color(0xFF2B5CE6), size: 20.sp),
            ),
            suffixIcon: toggleObscure != null
                ? GestureDetector(
              onTap: toggleObscure,
              child: Padding(
                padding: EdgeInsets.only(right: 14.w),
                child: Icon(
                  obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: const Color(0xFF6B7280),
                  size: 20.sp,
                ),
              ),
            )
                : null,
            contentPadding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide:
              const BorderSide(color: Color(0xFF1C1D2A), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide:
              const BorderSide(color: Color(0xFF2B5CE6), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorStyle: GoogleFonts.poppins(
              fontSize: 11.sp,
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
    );
  }

// ─────────────────────────────────────────
// 🔥 SOCIAL BUTTON (commented out — kept for future use)
// ─────────────────────────────────────────
// Widget _socialBtn({
//   required String label,
//   required IconData icon,
//   required Color color,
// }) {
//   return GestureDetector(
//     onTap: () {},
//     child: Container(
//       height: 48.h,
//       decoration: BoxDecoration(
//         color: const Color(0xFF13141E),
//         borderRadius: BorderRadius.circular(16.r),
//         border: Border.all(color: const Color(0xFF1C1D2A), width: 1.2),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, color: color, size: 22.sp),
//           SizedBox(width: 8.w),
//           Text(
//             label,
//             style: GoogleFonts.poppins(
//               fontSize: 13.sp,
//               fontWeight: FontWeight.w500,
//               color: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
}