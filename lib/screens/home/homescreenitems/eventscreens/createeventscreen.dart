import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../constant/apptextstyle.dart';
import '../../../../constant/colors.dart';
import '../../../../widget/outlinedbutton.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 19, minute: 10);

  /// ✅ Empty string = kuch select nahi hua
  String selectedCategory = "";

  final List<Map<String, dynamic>> categories = [
    {
      "title": "Dinner",
      "subtitle": "Find someone for a great meal together.",
      "icon": Icons.dinner_dining_outlined,
      "color": AppColors.accent,
    },
    {
      "title": "Party Buddy",
      "subtitle": "Looking for a fun companion for parties.",
      "icon": Icons.celebration_outlined,
      "color": Colors.pinkAccent,
    },
    {
      "title": "Drinks Tonight",
      "subtitle": "Grab drinks & good conversations.",
      "icon": Icons.local_bar_outlined,
      "color": AppColors.green,
    },
    {
      "title": "Party",
      "subtitle": "Discreet & exclusive company.",
      "icon": Icons.workspace_premium_outlined,
      "color": Colors.pinkAccent,
    },
    {
      "title": "Spontaneous Plans",
      "subtitle": "Open to anything fun and last-minute.",
      "icon": Icons.bolt_outlined,
      "color": AppColors.purple,
    },
    {
      "title": "Nightlife Out",
      "subtitle": "Explore the city like a local.",
      "icon": Icons.location_on_outlined,
      "color": AppColors.accent,
    },
    {
      "title": "Party",
      "subtitle": "Discreet & exclusive company.",
      "icon": Icons.workspace_premium_outlined,
      "color": Colors.pinkAccent,
    },
  ];

  @override
  void dispose() {
    _descController.dispose();
    _locationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search category...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = categories[index]["title"];
                          });

                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 14.h),
                          padding: EdgeInsets.all(16.w),

                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(24.r),

                            border: Border.all(color: AppColors.cardBorder),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .25),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),

                          child: Row(
                            children: [
                              Container(
                                width: 50.w,
                                height: 50.w,

                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,

                                  border: Border.all(
                                    color: categories[index]["color"],
                                    width: 1.5,
                                  ),
                                ),

                                child: Icon(
                                  categories[index]["icon"],
                                  color: categories[index]["color"],
                                  size: 28.sp,
                                ),
                              ),

                              SizedBox(width: 16.w),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      categories[index]["title"],
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),

                                    SizedBox(height: 5.h),

                                    Text(
                                      categories[index]["subtitle"],
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11.sp,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                width: 42.w,
                                height: 42.w,

                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                ),

                                child: Icon(
                                  Icons.chevron_right,
                                  color: AppColors.white.withValues(alpha: .8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  RESPONSIVE HELPERS
  // ─────────────────────────────────────────────────────────────

  /// Tablet threshold
  bool _isTablet(BuildContext ctx) => MediaQuery.of(ctx).size.width > 600;

  /// Responsive font size: phone value → scaled up for tablet
  double _fs(BuildContext ctx, double phone, {double tabletScale = 1.20}) {
    final base = _isTablet(ctx) ? phone * tabletScale : phone;
    return base.sp;
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isTablet = _isTablet(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hPad = isTablet ? 28.0 : 18.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(
              left: hPad.w,
              right: hPad.w,
              top: isTablet ? 22.h : 16.h,
              bottom: bottomInset + 28.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── TOP BAR ────────────────────────────────────
                _buildTopBar(context, isTablet),

                SizedBox(height: isTablet ? 28.h : 22.h),

                // ── HERO BANNER ─────────────────────────────────
                _buildHeroBanner(context, isTablet),

                SizedBox(height: isTablet ? 28.h : 22.h),

                // ── CATEGORY DROPDOWN ───────────────────────────
                _buildCategoryDropdown(context, isTablet),

                SizedBox(height: isTablet ? 20.h : 16.h),

                // ── DESCRIPTION ─────────────────────────────────
                _descriptionField(context, isTablet),

                SizedBox(height: isTablet ? 20.h : 16.h),

                // ── LOCATION ────────────────────────────────────
                _locationField(context, isTablet),

                SizedBox(height: isTablet ? 20.h : 16.h),

                // ── ADD PHOTO ───────────────────────────────────
                _buildAddPhoto(context, isTablet),

                SizedBox(height: 8.h),

                Text(
                  "✨ A good photo gets more people excited!",
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: _fs(context, 11),
                  ),
                ),

                SizedBox(height: isTablet ? 24.h : 18.h),

                // ── DATE + TIME ─────────────────────────────────
                Row(
                  children: [
                    Expanded(child: _dateCard(context, isTablet)),
                    SizedBox(width: 14.w),
                    Expanded(child: _timeCard(context, isTablet)),
                  ],
                ),

                SizedBox(height: isTablet ? 40.h : 32.h),

                // ── CREATE BUTTON ────────────────────────────────
                GradientBorderButton(
                  title: "Create Tonight",
                  isTablet: isTablet,
                  width: double.infinity,
                  height: isTablet ? 70 : 62,
                  onTap: () {},
                ),

                SizedBox(height: 18.h),

                Center(
                  child: Text(
                    "🛡️ Your event will be visible to people in your area.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: _fs(context, 11),
                    ),
                  ),
                ),

                SizedBox(height: 28.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  TOP BAR
  // ─────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, bool isTablet) {
    final btnSize = isTablet ? 54.0 : 46.0;
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: btnSize.w,
            height: btnSize.w,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.purple,
              size: _fs(context, 18),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Text(
            "Create Your Tonight",
            style: AppTextStyles.heading.copyWith(
              fontSize: isTablet ? 28.sp : 22.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  HERO BANNER
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeroBanner(BuildContext context, bool isTablet) {
    return Container(
      width: double.infinity,
      height: isTablet ? 230.h : 175.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: AppColors.cardBorder),
        image: const DecorationImage(
          image: AssetImage("assets/night.jpg"),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 28.w : 22.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.r),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.black.withValues(alpha: 0.90),
              Colors.black.withValues(alpha: 0.45),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Make tonight unforgettable 🌙",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: isTablet ? 24.sp : 19.sp,
              ),
            ),
            SizedBox(height: 10.h),
            SizedBox(
              width: isTablet ? 340.w : 220.w,
              child: Text(
                "Plan a vibe. Meet new people. Make memories.",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: isTablet ? 14.sp : 12.sp,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  ✅ CATEGORY DROPDOWN — FIXED
  //  Sirf "Select ▼" dikhega, click par list open hogi,
  //  select karne par value neeche show hogi
  // ─────────────────────────────────────────────────────────────

  Widget _buildCategoryDropdown(BuildContext context, bool isTablet) {
    final iconSize = isTablet ? 54.0 : 50.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 18.w : 14.w,
        vertical: isTablet ? 14.h : 12.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.7),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // ── Left Icon ──
          Container(
            width: iconSize.w,
            height: iconSize.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.local_bar_rounded,
              color: AppColors.purple,
              size: _fs(context, 22),
            ),
          ),

          SizedBox(width: 14.w),

          // ── Label + Selected Value ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What are you planning?",
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: _fs(context, 12),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  // ✅ Agar kuch select nahi → "Select" dikhao
                  selectedCategory.isEmpty ? "Select" : selectedCategory,
                  style: GoogleFonts.poppins(
                    color: selectedCategory.isEmpty
                        ? Colors.white38
                        : Colors.white,
                    fontWeight: selectedCategory.isEmpty
                        ? FontWeight.w400
                        : FontWeight.w600,
                    fontSize: _fs(context, 15),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 6.w),

          // ✅ Sirf arrow visible hoga — dropdown yahan attach hai
          GestureDetector(
            onTap: _showCategoryBottomSheet,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.purple,
              size: isTablet ? 28.sp : 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  DESCRIPTION FIELD
  // ─────────────────────────────────────────────────────────────

  Widget _descriptionField(BuildContext context, bool isTablet) {
    final iconSize = isTablet ? 50.0 : 46.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 18.w : 14.w,
        vertical: isTablet ? 16.h : 13.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconSize.w,
            height: iconSize.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.description_outlined,
              color: AppColors.purple,
              size: _fs(context, 21),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Description *",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: _fs(context, 13),
                  ),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: _descController,
                  minLines: 2,
                  maxLines: isTablet ? 6 : 4,
                  textAlignVertical: TextAlignVertical.top,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: _fs(context, 14),
                  ),
                  decoration: InputDecoration(
                    hintText: "Tell people what's special about your plan...",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: _fs(context, 14),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
                SizedBox(height: 8.h),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    "${_descController.text.length}/250",
                    style: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: _fs(context, 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  LOCATION FIELD
  // ─────────────────────────────────────────────────────────────

  Widget _locationField(BuildContext context, bool isTablet) {
    final iconSize = isTablet ? 50.0 : 46.0;

    return Container(
      padding: EdgeInsets.all(isTablet ? 16.w : 14.w),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: iconSize.w,
            height: iconSize.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.location_on_outlined,
              color: AppColors.purple,
              size: _fs(context, 21),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: TextField(
              controller: _locationController,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: _fs(context, 14),
              ),
              decoration: InputDecoration(
                hintText: "Add a location",
                hintStyle: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: _fs(context, 14),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          Icon(
            Icons.my_location_rounded,
            color: AppColors.purple,
            size: _fs(context, 22),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  ADD PHOTO
  // ─────────────────────────────────────────────────────────────

  Widget _buildAddPhoto(BuildContext context, bool isTablet) {
    final iconBoxSize = isTablet ? 52.0 : 46.0;

    return GestureDetector(
      onTap: () {},
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: AppColors.purple,
          strokeWidth: 1.3,
          dashPattern: const [8, 5],
          radius: Radius.circular(20.r),
          padding: EdgeInsets.zero,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 18.w : 14.w,
            vertical: isTablet ? 18.h : 14.h,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            children: [
              // Left icon
              Container(
                width: iconBoxSize.w,
                height: iconBoxSize.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: AppColors.purple,
                  size: _fs(context, 22),
                ),
              ),

              SizedBox(width: 14.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Add Photo",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: _fs(context, 15),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Upload a photo to set the vibe",
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: _fs(context, 11),
                      ),
                    ),
                  ],
                ),
              ),

              // Right "+" icon
              Container(
                width: iconBoxSize.w,
                height: iconBoxSize.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.add,
                  color: AppColors.purple,
                  size: _fs(context, 26),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ─────────────────────────────────────────────────────────────
  //  DATE CARD
  // ─────────────────────────────────────────────────────────────

  Widget _dateCard(BuildContext context, bool isTablet) {
    final iconSize = isTablet ? 50.0 : 44.0;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
        );
        if (picked != null) setState(() => selectedDate = picked);
      },
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16.w : 13.w),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: iconSize.w,
              height: iconSize.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: AppColors.purple,
                size: _fs(context, 19),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Date",
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: _fs(context, 11),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    _formatDate(selectedDate),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: _fs(context, 14),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.purple,
              size: _fs(context, 20),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  TIME CARD
  // ─────────────────────────────────────────────────────────────

  Widget _timeCard(BuildContext context, bool isTablet) {
    final iconSize = isTablet ? 50.0 : 44.0;

    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: selectedTime,
        );
        if (picked != null) setState(() => selectedTime = picked);
      },
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16.w : 13.w),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: iconSize.w,
              height: iconSize.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                Icons.access_time_rounded,
                color: AppColors.purple,
                size: _fs(context, 19),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Time",
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: _fs(context, 11),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    _formatTime(selectedTime),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: _fs(context, 14),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.purple,
              size: _fs(context, 20),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────────

  String _formatDate(DateTime d) => "${_month(d.month)} ${d.day}, ${d.year}";

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return "$h:$m $period";
  }

  String _month(int m) => [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];
}
