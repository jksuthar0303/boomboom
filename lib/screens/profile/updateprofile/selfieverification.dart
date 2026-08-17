import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xml/xml.dart' as xml;

import '../../../backend/registerservice.dart';
import '../../../backend/secure_storage.dart';

class AppColors {
  static const bg = Color(0xFF070709);
  static const cardBg = Color(0xFF0F1017);
  static const cardBorder = Color(0xFF1C1D2A);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0B0);
  static const grey = Color(0xFF55576E);
  static const purple = Color(0xFF7B3FE4);
  static const purpleDark = Color(0xFF1A1030);
  static const white = Colors.white;
  static const black = Colors.black;
}

// ─────────────────────────────────────────────────────────────────────────────

class SelfieVerificationScreen extends StatefulWidget {
  const SelfieVerificationScreen({super.key});

  @override
  State<SelfieVerificationScreen> createState() =>
      _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState extends State<SelfieVerificationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  bool _isLoading = false;
  bool _isSuccessSubmitted = false;
  File? _capturedImage;
  final ImagePicker _picker = ImagePicker();
  final RegisterService _registerService = RegisterService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Retrieve lost data on Android if MainActivity was recreated after Camera intent
    _checkLostData();
  }

  Future<void> _checkLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.file != null) {
        await _processAndUploadSelfie(response.file!);
      }
    } catch (e) {
      debugPrint('Error retrieving lost data: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<bool> _checkAndRequestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    if (result.isGranted) return true;

    if (result.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Camera permission is permanently denied. Please enable it in Settings.',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission was denied.')),
        );
      }
    }
    return false;
  }

  Future<void> _onTakeSelfie() async {
    if (_isLoading) return;

    // 1. Check & Request Camera Permission
    final hasPermission = await _checkAndRequestCameraPermission();
    if (!hasPermission) return;

    try {
      // 2. Launch Camera with optimized resolution & quality
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (photo == null) return; // User cancelled capture

      await _processAndUploadSelfie(photo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processAndUploadSelfie(XFile photo) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _capturedImage = File(photo.path);
    });

    try {
      // 1. Convert captured image to Base64
      final bytes = await photo.readAsBytes();
      final String base64Image = base64Encode(bytes);

      // 2. Retrieve logged-in user email
      final String? userEmail = await SecureStorage().getUserEmail();
      if (userEmail == null || userEmail.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User email not found. Please log in again.'),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 3. Call SOAP MediaInsert API with Base64 image and type 'verify'
      final response = await _registerService.mediaInsert(
        email: userEmail.trim(),
        mediaBase64: base64Image,
        type: 'verify',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        bool isSuccess = false;
        String message = 'Selfie uploaded successfully for verification!';

        try {
          final doc = xml.XmlDocument.parse(response.body);
          final resElements = doc.findAllElements('MediaInsertResult');
          if (resElements.isNotEmpty) {
            final jsonStr = resElements.first.innerText;
            final resJson = jsonDecode(jsonStr);
            if ((resJson['Status'] ?? 0) == 1) {
              isSuccess = true;
              message = resJson['Message'] ?? 'Verification submitted successfully!';
            } else {
              message = resJson['Message'] ?? 'Failed to submit verification.';
            }
          } else {
            isSuccess = true;
          }
        } catch (_) {
          isSuccess = true;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isSuccess ? Colors.green : Colors.red,
          ),
        );

        if (isSuccess) {
          setState(() {
            _isSuccessSubmitted = true;
          });
          Future.delayed(const Duration(seconds: 2), () {
            _safeNavigateBack();
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server Error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _safeNavigateBack() {
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double hPad = isTablet ? 56.w : 20.w;
    final double maxW = isTablet ? 640.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(isTablet),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Shield icon ──────────────────────────────────────────
                  _ShieldIcon(isTablet: isTablet),

                  SizedBox(height: 20.h),

                  // ── Title ────────────────────────────────────────────────
                  Text(
                    'Verify Your Identity',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 30.sp : 26.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // ── Subtitle ─────────────────────────────────────────────
                  Text(
                    'Take a clear selfie to verify your profile\nand build trust',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 14.sp : 13.sp,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // ── Quick Tips card ──────────────────────────────────────
                  _QuickTipsCard(isTablet: isTablet),

                  SizedBox(height: 40.h),

                  // ── Pulsing camera button ────────────────────────────────
                  _CameraButton(
                    isTablet: isTablet,
                    pulseAnim: _pulseAnim,
                    isLoading: _isLoading,
                    capturedImage: _capturedImage,
                    onTap: _onTakeSelfie,
                  ),

                  SizedBox(height: 16.h),

                  Text(
                    _isLoading
                        ? 'Uploading Selfie...'
                        : (_isSuccessSubmitted
                            ? 'Verification Submitted!'
                            : (_capturedImage != null
                                ? 'Tap to Retake Selfie'
                                : 'Tap to Take Selfie')),
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 17.sp : 15.sp,
                      fontWeight: FontWeight.w700,
                      color: _isSuccessSubmitted ? Colors.greenAccent : AppColors.textPrimary,
                    ),
                  ),

                  SizedBox(height: 36.h),

                  // ── Footer note ──────────────────────────────────────────
                  Text(
                    'Your photo will be reviewed by our team within 24-48 hours',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 13.sp : 12.sp,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(bool isTablet) {
    return AppBar(
      backgroundColor: AppColors.bg,
      elevation: 0,
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.cardBorder),
      ),
      leading: GestureDetector(
        onTap: _safeNavigateBack,
        child: Container(
          margin: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(
            Icons.chevron_left,
            color: AppColors.textPrimary,
            size: isTablet ? 26.sp : 22.sp,
          ),
        ),
      ),
      title: Text(
        'Selfie Verification',
        style: GoogleFonts.poppins(
          fontSize: isTablet ? 18.sp : 16.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shield icon
// ─────────────────────────────────────────────────────────────────────────────

class _ShieldIcon extends StatelessWidget {
  final bool isTablet;
  const _ShieldIcon({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final double size = isTablet ? 90.w : 74.w;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.purple,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.verified_user_rounded,
        color: AppColors.white,
        size: isTablet ? 44.sp : 36.sp,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Tips Card
// ─────────────────────────────────────────────────────────────────────────────

class _QuickTipsCard extends StatelessWidget {
  final bool isTablet;
  const _QuickTipsCard({required this.isTablet});

  static const List<_TipData> _tips = [
    _TipData(
      icon: Icons.wb_sunny_rounded,
      title: 'Good Lighting',
      sub: 'Natural light works best',
    ),
    _TipData(
      icon: Icons.face_retouching_natural,
      title: 'Face Visible',
      sub: 'Center your face clearly',
    ),
    _TipData(
      icon: Icons.remove_red_eye_rounded,
      title: 'Look at Camera',
      sub: 'Make eye contact',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 24.w : 18.w),
      decoration: BoxDecoration(
        color: AppColors.purpleDark,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Tips',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 16.sp : 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          ..._tips.map((t) => _TipRow(data: t, isTablet: isTablet)),
        ],
      ),
    );
  }
}

class _TipData {
  final IconData icon;
  final String title;
  final String sub;
  const _TipData({required this.icon, required this.title, required this.sub});
}

class _TipRow extends StatelessWidget {
  final _TipData data;
  final bool isTablet;
  const _TipRow({required this.data, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final double iconCircle = isTablet ? 50.w : 42.w;
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Container(
            width: iconCircle,
            height: iconCircle,
            decoration: const BoxDecoration(
              color: AppColors.purple,
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              color: AppColors.white,
              size: isTablet ? 24.sp : 20.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 15.sp : 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                data.sub,
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 13.sp : 11.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing Camera Button
// ─────────────────────────────────────────────────────────────────────────────

class _CameraButton extends StatelessWidget {
  final bool isTablet;
  final Animation<double> pulseAnim;
  final bool isLoading;
  final File? capturedImage;
  final VoidCallback onTap;

  const _CameraButton({
    required this.isTablet,
    required this.pulseAnim,
    required this.isLoading,
    required this.capturedImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double btnSize = isTablet ? 150.w : 120.w;
    final double ringSize = isTablet ? 180.w : 148.w;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulseAnim,
        builder: (_, child) =>
            Transform.scale(scale: pulseAnim.value, child: child),
        child: SizedBox(
          width: ringSize,
          height: ringSize,
          child: CustomPaint(
            painter: _DashedCirclePainter(
              color: AppColors.purple.withValues(alpha: 0.5),
              strokeWidth: 2,
              dashCount: 24,
            ),
            child: Center(
              child: Container(
                width: btnSize,
                height: btnSize,
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  shape: BoxShape.circle,
                  image: capturedImage != null
                      ? DecorationImage(
                          image: FileImage(capturedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                        ),
                      )
                    : (capturedImage == null
                        ? Icon(
                            Icons.camera_alt_rounded,
                            color: AppColors.white,
                            size: isTablet ? 58.sp : 46.sp,
                          )
                        : const SizedBox.shrink()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed circle painter
// ─────────────────────────────────────────────────────────────────────────────

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashCount;

  const _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;
    final dashAngle = (2 * pi) / dashCount;
    final gapAngle = dashAngle * 0.45;
    final sweepAngle = dashAngle - gapAngle;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle - pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
