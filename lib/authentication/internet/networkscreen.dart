import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'nointernetcontroller.dart';

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _retryCtrl;
  late AnimationController _blinkCtrl;

  late Animation<double> _pulseAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _particleAnim;
  late Animation<double> _blinkAnim;

  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat(reverse: true);

    _particleCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: 6),
    )..repeat();

    _retryCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _particleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _particleCtrl, curve: Curves.linear),
    );

    _blinkAnim = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _particleCtrl.dispose();
    _retryCtrl.dispose();
    _blinkCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    _retryCtrl.forward(from: 0);
    await Get.find<NetworkController>().refresh();
    if (mounted) {
      setState(() => _isRetrying = false);
      _retryCtrl.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0a0e2e),
              Color(0xFF080c25),
              Color(0xFF0d1035),
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Blue glow top center
            Positioned(
              top: -60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: isTablet ? 480 : 340,
                  height: isTablet ? 300 : 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF5078FF).withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Blue glow mid center
            Positioned(
              top: 160,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: isTablet ? 360 : 260,
                  height: isTablet ? 360 : 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF3C64FF).withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Particles
            AnimatedBuilder(
              animation: _particleAnim,
              builder: (_, _) => CustomPaint(
                painter: _ParticlePainter(_particleAnim.value),
                size: Size(
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height,
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 80.w : 24.w,
                    vertical: 32.h,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBadge(),
                      SizedBox(height: isTablet ? 40.h : 28.h),
                      _buildIconCard(isTablet),
                      SizedBox(height: isTablet ? 44.h : 32.h),
                      _buildInfoCard(isTablet),
                      SizedBox(height: isTablet ? 28.h : 22.h),
                      _buildRetryButton(isTablet),
                      SizedBox(height: isTablet ? 16.h : 12.h),
                      _buildBottomHint(isTablet),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── STATUS BADGE
  Widget _buildBadge() {
    return AnimatedBuilder(
      animation: _blinkAnim,
      builder: (_, _) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFe05c6a), Color(0xFFc04060)],
          ),
        ),
        padding: EdgeInsets.all(1.5),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 7.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: Color(0xFFb4283c).withValues(alpha: 0.45),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: _blinkAnim.value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(0xFFff4d6a),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFff4d6a).withValues(alpha: 0.9),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                "Connection Lost",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFffb3be),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── WIFI ICON CARD
  Widget _buildIconCard(bool isTablet) {
    double size = isTablet ? 160 : 128;

    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: child,
      ),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Transform.scale(
          scale: _pulseAnim.value,
          child: child,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // pulse ring 1
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) => Container(
                width: size + 28 + (_pulseCtrl.value * 12),
                height: size + 28 + (_pulseCtrl.value * 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isTablet ? 52 : 44),
                  border: Border.all(
                    color: Color(0xFF6496FF)
                        .withValues(alpha: 0.22 * (1 - _pulseCtrl.value)),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            // pulse ring 2
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) {
                double delayed = (_pulseCtrl.value + 0.45) % 1.0;
                return Container(
                  width: size + 48 + (delayed * 14),
                  height: size + 48 + (delayed * 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isTablet ? 60 : 52),
                    border: Border.all(
                      color: Color(0xFF5078FF)
                          .withValues(alpha: 0.13 * (1 - delayed)),
                      width: 1,
                    ),
                  ),
                );
              },
            ),

            // card with gradient border
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isTablet ? 44 : 36),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2a4ccc),
                    Color(0xFF1a3aaa),
                    Color(0xFF3060dd),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF3264FF).withValues(alpha: 0.35),
                    blurRadius: 40,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Color(0xFF1e3cc8).withValues(alpha: 0.18),
                    blurRadius: 80,
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: EdgeInsets.all(2),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isTablet ? 43 : 34),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF162060),
                      Color(0xFF0e1848),
                    ],
                  ),
                ),
                child: Center(
                  child: CustomPaint(
                    size: Size(size * 0.58, size * 0.58),
                    painter: _WifiOffPainter(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── INFO CARD
  Widget _buildInfoCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 32.w : 20.w,
        vertical: isTablet ? 28.h : 22.h,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Color(0xFF1e3282).withValues(alpha: 0.45),
        border: Border.all(
          color: Color(0xFF5078DC).withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Title
          Text(
            "No Internet",
            style: GoogleFonts.syne(
              fontSize: isTablet ? 28.sp : 26.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Color(0xFF4d9fff), Color(0xFF60cfff)],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            blendMode: BlendMode.srcIn,
            child: Text(
              "Connection",
              style: GoogleFonts.syne(
                fontSize: isTablet ? 28.sp : 26.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),

          SizedBox(height: isTablet ? 12.h : 10.h),

          Text(
            "Looks like you're offline.\nPlease check your connection and try again.",
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: isTablet ? 14.sp : 13.sp,
              fontWeight: FontWeight.w400,
              color: Color(0xFFb4c8ff).withValues(alpha: 0.55),
              height: 1.65,
            ),
          ),

          SizedBox(height: isTablet ? 20.h : 18.h),

          // Gradient divider
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Colors.transparent,
                Color(0xFF6496FF).withValues(alpha: 0.25),
                Colors.transparent,
              ],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            blendMode: BlendMode.srcIn,
            child: Container(height: 1, color: Colors.white),
          ),

          SizedBox(height: isTablet ? 18.h : 16.h),

          // Chips row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChip(Icons.wifi_off_rounded, "Wi-Fi", "Check your\nWi-Fi connection"),
              SizedBox(width: 8.w),
              _buildChip(Icons.signal_cellular_off_rounded, "Mobile", "Check your\nmobile data"),
              SizedBox(width: 8.w),
              _buildChip(Icons.router_rounded, "Router", "Restart your\nrouter"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, String sub) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Color(0xFF2846b4).withValues(alpha: 0.45),
          border: Border.all(
            color: Color(0xFF5078DC).withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Color(0xFFc8dcff).withValues(alpha: 0.8), size: 18),
            SizedBox(height: 4.h),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Color(0xFFc8dcff).withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9.sp,
                color: Color(0xFF96b4ff).withValues(alpha: 0.45),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── RETRY BUTTON
  Widget _buildRetryButton(bool isTablet) {
    return GestureDetector(
      onTap: _onRetry,
      child: AnimatedBuilder(
        animation: _retryCtrl,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - (_retryCtrl.value * 0.03),
          child: child,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF3366ff),
                Color(0xFF5599ff),
                Color(0xFF3e80ff),
              ],
            ),
            boxShadow: _isRetrying
                ? []
                : [
              BoxShadow(
                color: Color(0xFF3264FF).withValues(alpha: 0.45),
                blurRadius: 28,
                spreadRadius: -2,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.all(1.5),
          child: Container(
            height: isTablet ? 60.h : 54.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              gradient: _isRetrying
                  ? LinearGradient(
                colors: [
                  Color(0xFF0a143c).withValues(alpha: 0.7),
                  Color(0xFF0a143c).withValues(alpha: 0.7),
                ],
              )
                  : LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF2255ee), Color(0xFF4488ff)],
              ),
            ),
            child: Center(
              child: _isRetrying
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation(Colors.white54),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Color(0xFF80cfff), Color(0xFFa0e0ff)],
                    ).createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                    child: Text(
                      "Checking...",
                      style: GoogleFonts.syne(
                        fontSize: isTablet ? 17.sp : 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: isTablet ? 22 : 20,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    "Try Again",
                    style: GoogleFonts.syne(
                      fontSize: isTablet ? 17.sp : 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── BOTTOM HINT
  Widget _buildBottomHint(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color(0xFF1e3278).withValues(alpha: 0.35),
        border: Border.all(
          color: Color(0xFF5078c8).withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text("💡", style: TextStyle(fontSize: 20)),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Still having trouble?",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFd2e1ff).withValues(alpha: 0.85),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  "Check Wi-Fi  •  Mobile Data  •  Airplane Mode",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10.sp,
                    color: Color(0xFF96b4ff).withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF96b4ff).withValues(alpha: 0.4),
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// WIFI OFF PAINTER
// ══════════════════════════════════════════════════════

class _WifiOffPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double cx = size.width / 2;
    double cy = size.height * 0.52;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.46),
      math.pi + math.pi * 0.175,
      math.pi * 0.65,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.076
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.30),
      math.pi + math.pi * 0.175,
      math.pi * 0.65,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.076
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.16),
      math.pi + math.pi * 0.175,
      math.pi * 0.65,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.076
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      Offset(cx, cy + size.height * 0.10),
      size.width * 0.062,
      Paint()..color = Colors.white.withValues(alpha: 0.88),
    );

    // Red diagonal slash
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.12),
      Offset(size.width * 0.88, size.height * 0.88),
      Paint()
        ..shader = LinearGradient(
          colors: [Color(0xFFff6b6b), Color(0xFFff3355)],
        ).createShader(
          Rect.fromPoints(
            Offset(size.width * 0.12, size.height * 0.12),
            Offset(size.width * 0.88, size.height * 0.88),
          ),
        )
        ..strokeWidth = size.width * 0.090
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════
// PARTICLE PAINTER
// ══════════════════════════════════════════════════════

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  static List<_Particle> particles = List.generate(28, (i) {
    math.Random rng = math.Random(i * 137 + 3);
    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      radius: rng.nextDouble() * 2.0 + 0.6,
      speed: rng.nextDouble() * 0.08 + 0.03,
      phase: rng.nextDouble(),
      isBlue: i % 4 != 0,
      opacity: rng.nextDouble() * 0.20 + 0.05,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (_Particle p in particles) {
      double y = ((p.y - p.speed * progress + p.phase) % 1.0) * size.height;
      canvas.drawCircle(
        Offset(p.x * size.width, y),
        p.radius,
        Paint()
          ..color = (p.isBlue ? Color(0xFF508CFF) : Color(0xFF78B4FF))
              .withValues(alpha: p.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  double x, y, radius, speed, phase, opacity;
  bool isBlue;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.isBlue,
    required this.opacity,
  });
}