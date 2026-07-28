import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomLottie extends StatelessWidget {

  final String asset;

  final double? height;
  final double? width;

  final bool repeat;
  final bool animate;

  final BoxFit fit;

  const CustomLottie({
    super.key,

    required this.asset,

    this.height,
    this.width,

    this.repeat = true,
    this.animate = true,

    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {

    return Lottie.asset(

      asset,

      height: height,
      width: width,

      repeat: repeat,
      animate: animate,

      fit: fit,
    );
  }
}