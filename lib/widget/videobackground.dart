import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class VideoBackgroundCard extends StatefulWidget {
  final String videoAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final VoidCallback? onVideoEnd;

  const VideoBackgroundCard({
    super.key,
    required this.videoAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.borderRadius,
    this.onVideoEnd,
  });

  @override
  State<VideoBackgroundCard> createState() => _VideoBackgroundCardState();
}

class _VideoBackgroundCardState extends State<VideoBackgroundCard> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _endFired = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoAsset)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        _controller.setLooping(false);
        _controller.setVolume(0);
        _controller.play();
        _controller.addListener(_checkVideoEnd);
      });
  }

  void _checkVideoEnd() {
    if (_endFired || !mounted) return;
    final pos = _controller.value.position;
    final dur = _controller.value.duration;
    if (dur > Duration.zero && pos >= dur - const Duration(milliseconds: 400)) {
      _endFired = true;
      widget.onVideoEnd?.call();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkVideoEnd);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── VIDEO ─────────────────────────────────────
            if (_initialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            else
              Container(color: Colors.black),

            // ── LIGHT DARK OVERLAY ────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                ),
              ),
            ),

            // ── BOTTOM LEFT CONTENT — same as screenshot ──
            Positioned(
              bottom: 14,
              left: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Dark box with airplane icon
                  Container(
                    width: 34.w,
                    height: 34.h,
                    decoration: BoxDecoration(

                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(2.w),
                      child: Image.asset(
                        "assets/aeroplane.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  SizedBox(width: 2.w),

                  // Title + subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Travel Alert",
                        style: TextStyle(
                          fontFamily: "Poppins",
                          color: Colors.white,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(height: 0.h),
                      Text(
                        "Upcoming Traveller meet",
                        style: TextStyle(
                          fontFamily: "Poppins",
                          color: Colors.white70,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w400,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
