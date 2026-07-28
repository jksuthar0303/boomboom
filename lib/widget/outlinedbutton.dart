import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
class GradientBorderButton extends StatefulWidget {
  final String title;
  final VoidCallback onTap;
  final bool isTablet;

  final double? height;
  final double? width;

  /// 🔥 NEW CUSTOMIZATION
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? borderRadius;

  const GradientBorderButton({
    super.key,
    required this.title,
    required this.onTap,
    required this.isTablet,
    this.height,
    this.width,
    this.fontSize,
    this.fontWeight,
    this.borderRadius,
  });

  @override
  State<GradientBorderButton> createState() =>
      _GradientBorderButtonState();
}

class _GradientBorderButtonState
    extends State<GradientBorderButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    /// 🔥 HEIGHT WIDTH
    final btnHeight =
        widget.height ?? (widget.isTablet ? 60.h : 52.h);

    final btnWidth = widget.width ?? double.infinity;

    /// 🔥 FONT SIZE
    final textSize =
        widget.fontSize ?? (widget.isTablet ? 18.sp : 16.sp);

    /// 🔥 FONT WEIGHT
    final textWeight = widget.fontWeight ?? FontWeight.w700;

    /// 🔥 BORDER RADIUS
    final radius = widget.borderRadius ?? 40.r;

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) {
        setState(() => isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => isPressed = false),

      child: AnimatedScale(
        scale: isPressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),

        child: Container(
          width: btnWidth,
          padding: EdgeInsets.all(2.w),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),

            gradient: const LinearGradient(
              colors: [
                Color(0xFF20305F),
                Color(0xFF3D215D),
              ],
            ),
          ),

          child: Container(
            height: btnHeight,

            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(radius - 2),
            ),

            child: Center(
              child: Text(
                widget.title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: textSize,
                  fontWeight: textWeight,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}