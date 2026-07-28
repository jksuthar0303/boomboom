import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GradientCircleButtont extends StatefulWidget {
  final VoidCallback onTap;
  final Widget image; // 🔥 image instead of text
  final double size;  // 🔥 size control

  const GradientCircleButtont({
    super.key,
    required this.onTap,
    required this.image,
    this.size = 60, // default size
  });

  @override
  State<GradientCircleButtont> createState() =>
      _GradientCircleButtontState();
}

class _GradientCircleButtontState extends State<GradientCircleButtont> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) {
        setState(() => isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => isPressed = false),

      child: AnimatedScale(
        scale: isPressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),

        child: Container(
          padding: EdgeInsets.all(2.w),

          decoration: BoxDecoration(
            shape: BoxShape.circle,

            /// 🔥 GRADIENT BORDER
            gradient: const LinearGradient(
              colors: [
                Color(0xFF20305F),
                Color(0xFF3D215D),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),

            /// 🔥 glow
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3D215D)
                    .withValues(alpha: isPressed ? 0.3 : 0.7),
                blurRadius: isPressed ? 8 : 16,
              )
            ],
          ),

          /// 🔥 INNER CIRCLE
          child: Container(
            height: widget.size.w,
            width: widget.size.w,

            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white, // inner color
            ),

            child: Center(
              child: widget.image,
            ),
          ),
        ),
      ),
    );
  }
}