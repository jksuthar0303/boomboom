import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constant/appconstants.dart';

/// 🌐 GLOBAL IMAGE HELPER & WIDGET
/// Centralizes all image URL formatting, caching, placeholder, and error handling.
class AppImageHelper {
  /// Base media URL - change this single constant if the server domain changes
  static String baseMediaUrl = AppConstants.baseUrl;

  /// Helper to convert any image path to full valid URL
  static String getFullImageUrl(dynamic path) {
    if (path == null) return '';
    final String str = path.toString().trim();
    if (str.isEmpty || str == 'null' || str == 'undefined') return '';

    if (str.startsWith('http://') || str.startsWith('https://')) {
      return str;
    }

    if (str.startsWith('data:image')) {
      return str;
    }

    final cleanBase = baseMediaUrl.endsWith('/')
        ? baseMediaUrl.substring(0, baseMediaUrl.length - 1)
        : baseMediaUrl;
    final cleanPath = str.startsWith('/') ? str.substring(1) : str;

    return '$cleanBase/$cleanPath';
  }

  /// Helper to get an ImageProvider with safe URL or fallback
  static ImageProvider provider(
    dynamic path, {
    String defaultAsset = 'assets/images/placeholder.png',
  }) {
    final fullUrl = getFullImageUrl(path);
    if (fullUrl.isNotEmpty &&
        (fullUrl.startsWith('http://') || fullUrl.startsWith('https://'))) {
      return CachedNetworkImageProvider(fullUrl);
    }
    return AssetImage(defaultAsset);
  }
}

/// 🖼️ GLOBAL REUSABLE IMAGE WIDGET
class AppNetworkImage extends StatelessWidget {
  final dynamic imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool isCircle;
  final Widget? placeholder;
  final Widget? errorWidget;
  final IconData fallbackIcon;
  final double? fallbackIconSize;
  final Color? backgroundColor;
  final BoxBorder? border;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.isCircle = false,
    this.placeholder,
    this.errorWidget,
    this.fallbackIcon = Icons.person,
    this.fallbackIconSize,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final fullUrl = AppImageHelper.getFullImageUrl(imageUrl);
    final bool hasValidUrl =
        fullUrl.isNotEmpty &&
        (fullUrl.startsWith('http://') || fullUrl.startsWith('https://'));

    final defaultFallback = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF161E31),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle
            ? null
            : (borderRadius ?? BorderRadius.circular(16.r)),
        border: border,
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          color: Colors.white38,
          size: fallbackIconSize ?? 32.sp,
        ),
      ),
    );

    if (!hasValidUrl) {
      return errorWidget ?? defaultFallback;
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: fullUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: backgroundColor ?? const Color(0xFF141B2D),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF8E2DE2),
                ),
              ),
            ),
          ),
      errorWidget: (context, url, error) => errorWidget ?? defaultFallback,
    );

    if (isCircle) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(shape: BoxShape.circle, border: border),
        child: ClipOval(child: imageWidget),
      );
    }

    if (borderRadius != null) {
      return Container(
        decoration: BoxDecoration(borderRadius: borderRadius, border: border),
        child: ClipRRect(borderRadius: borderRadius!, child: imageWidget),
      );
    }

    return imageWidget;
  }
}

/// 👤 GLOBAL AVATAR WIDGET
class AppAvatar extends StatelessWidget {
  final dynamic imageUrl;
  final double radius;
  final Color? backgroundColor;
  final IconData fallbackIcon;
  final BoxBorder? border;

  const AppAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24,
    this.backgroundColor,
    this.fallbackIcon = Icons.person,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final double size = radius * 2;
    return AppNetworkImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      isCircle: true,
      backgroundColor: backgroundColor,
      fallbackIcon: fallbackIcon,
      fallbackIconSize: radius * 0.9,
      border: border,
    );
  }
}
