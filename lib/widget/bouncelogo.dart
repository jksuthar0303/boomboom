import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BounceLogo extends StatefulWidget {
  final String imagePath;
  final double size;

  const BounceLogo({
    super.key,
    required this.imagePath,
    this.size = 120,
  });

  @override
  State<BounceLogo> createState() => _BounceLogoState();
}

class _BounceLogoState extends State<BounceLogo>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> bounceAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    bounceAnim = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    /// 🔥 Repeat bounce (smooth loop)
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, bounceAnim.value),
          child: child,
        );
      },

      child: Image.asset(
        widget.imagePath,
        width: widget.size.w,
        height: widget.size.w,
        fit: BoxFit.contain,
      ),
    );
  }

}