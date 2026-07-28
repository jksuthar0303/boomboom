import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PrimaryButton extends StatefulWidget {
  final String title;
  final VoidCallback onTap;
  final bool isTablet;

  // ── Optional customization ──
  final Color? backgroundColor;   // button fill color
  final Color? textColor;         // label color
  final double? fontSize;         // override font size
  final double? borderRadius;     // corner curve
  final Color? borderColor;       // border line color (null = no border)
  final double? borderWidth;      // border thickness
  final double? elevation;        // shadow strength (0 = no shadow)
  final List<Color>? gradient;    // if set, ignores backgroundColor

  const PrimaryButton({
    super.key,
    required this.title,
    required this.onTap,
    required this.isTablet,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    this.elevation,
    this.gradient,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  double get _resolvedElevation => widget.elevation ?? 1.0;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? 40.0;
    final bgColor = widget.backgroundColor ?? Colors.white;
    final txtColor = widget.textColor ?? Colors.black;
    final fSize = widget.fontSize ?? (widget.isTablet ? 18.sp : 16.sp);
    final bWidth = widget.borderWidth ?? 1.5;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        height: widget.isTablet ? 60.h : 52.h,
        transform: Matrix4.identity()..scale(_pressed ? 0.97 : 1.0),
        decoration: BoxDecoration(
          // Gradient takes priority over solid color
          gradient: widget.gradient != null
              ? LinearGradient(
            colors: widget.gradient!,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
              : null,
          color: widget.gradient == null ? bgColor : null,
          borderRadius: BorderRadius.circular(radius.r),

          // Border — only if borderColor provided
          border: widget.borderColor != null
              ? Border.all(color: widget.borderColor!, width: bWidth)
              : null,

          // Elevation / shadow — skip when pressed or elevation == 0
          boxShadow: (_pressed || _resolvedElevation == 0)
              ? []
              : [
            BoxShadow(
              color: (widget.gradient != null
                  ? widget.gradient!.last
                  : bgColor)
                  .withValues(alpha: 0.35),
              blurRadius: _resolvedElevation * 10,
              offset: Offset(0, _resolvedElevation * 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.title,
            style: GoogleFonts.poppins(
              color: txtColor,
              fontSize: fSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}