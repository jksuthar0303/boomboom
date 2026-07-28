import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlassButton extends StatefulWidget {
  final VoidCallback onTap;
  final String text;
  final Widget icon;

  const GlassButton({
    super.key,
    required this.onTap,
    required this.text,
    required this.icon,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
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

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),

        /// 🔥 PRESS EFFECT (down feel)
        transform: Matrix4.translationValues(0, isPressed ? 4 : 0, 0),

        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(2), // 🔥 border thickness

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),

            /// 🔥 GRADIENT BORDER (purple → blue → gold touch)
            gradient: const LinearGradient(
              colors: [
                Color(0xFF3D215D), // purple
                Color(0xFF0F537B), // blue
                Color(0xFFFFD700), // gold touch
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),

            /// 🔥 shadow (press pe kam ho jayega)
            boxShadow: isPressed
                ? []
                : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),

          /// 🔥 INNER WHITE CONTAINER
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(38),
            ),

            child: Row(
              children: [

                /// 🔥 ICON CIRCLE
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade100,
                  ),
                  child: Center(child: widget.icon),
                ),

                const SizedBox(width: 12),

                /// 🔥 TEXT
                Expanded(
                  child: Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                ),

                const SizedBox(width: 40), // balance for center
              ],
            ),
          ),
        ),
      ),
    );
  }
}