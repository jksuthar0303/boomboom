import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constant/colors.dart';

enum FeedbackTopic { bugReport, suggestion, compliment, other }

class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({super.key});

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  FeedbackTopic? _selectedTopic = FeedbackTopic.suggestion; // default selected
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_selectedTopic == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a topic.')));
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your message.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback submitted! Thank you.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double hPad = isTablet ? 48.w : 20.w;
    final double maxW = isTablet ? 620.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.bg,
      // ── AppBar ──────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            margin: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(10.r),
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
          'Send Feedback',
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 18.sp : 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),

      // ── Body ────────────────────────────────────────────────────────────────
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad,
                      vertical: 24.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Hero heading ───────────────────────────────────
                        Text(
                          'How can we improve?',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 28.sp : 24.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Help us build the best experience for you.',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 14.sp : 13.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        SizedBox(height: 28.h),

                        // ── Section label ──────────────────────────────────
                        Text(
                          'Select Topic',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 16.sp : 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        SizedBox(height: 14.h),

                        // ── 2×2 Topic Grid ─────────────────────────────────
                        _TopicGrid(
                          selected: _selectedTopic,
                          isTablet: isTablet,
                          onSelect: (t) => setState(() => _selectedTopic = t),
                        ),

                        SizedBox(height: 28.h),

                        // ── Message label ──────────────────────────────────
                        Text(
                          'Your Message',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 16.sp : 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // ── TextField ──────────────────────────────────────
                        TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          maxLines: isTablet ? 10 : 8,
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 14.sp : 13.sp,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type your feedback here...',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: isTablet ? 14.sp : 13.sp,
                              color: AppColors.grey,
                            ),
                            filled: true,
                            fillColor: AppColors.inputBg,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: BorderSide(
                                color: AppColors.inputBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: BorderSide(
                                color: AppColors.inputBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: BorderSide(
                                color: AppColors.grey,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ),

                // ── Submit button (pinned bottom) ──────────────────────────
                _SubmitButton(isTablet: isTablet, onTap: _onSubmit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2×2 Topic Grid
// ─────────────────────────────────────────────────────────────────────────────

class _TopicGrid extends StatelessWidget {
  final FeedbackTopic? selected;
  final bool isTablet;
  final ValueChanged<FeedbackTopic> onSelect;

  const _TopicGrid({
    required this.selected,
    required this.isTablet,
    required this.onSelect,
  });

  static const List<_TopicData> _topics = [
    _TopicData(
      topic: FeedbackTopic.bugReport,
      label: 'Bug Report',
      icon: Icons.bug_report_rounded,
    ),
    _TopicData(
      topic: FeedbackTopic.suggestion,
      label: 'Suggestion',
      icon: Icons.lightbulb_outline_rounded,
    ),
    _TopicData(
      topic: FeedbackTopic.compliment,
      label: 'Compliment',
      icon: Icons.favorite_rounded,
    ),
    _TopicData(
      topic: FeedbackTopic.other,
      label: 'Other',
      icon: Icons.more_horiz_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double gap = 12.w;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: gap,
      mainAxisSpacing: gap,
      childAspectRatio: isTablet ? 1.4 : 1.25,
      children: _topics.map((t) {
        final bool isSelected = selected == t.topic;
        return _TopicCard(
          data: t,
          isSelected: isSelected,
          isTablet: isTablet,
          onTap: () => onSelect(t.topic),
        );
      }).toList(),
    );
  }
}

class _TopicData {
  final FeedbackTopic topic;
  final String label;
  final IconData icon;
  const _TopicData({
    required this.topic,
    required this.label,
    required this.icon,
  });
}

class _TopicCard extends StatelessWidget {
  final _TopicData data;
  final bool isSelected;
  final bool isTablet;
  final VoidCallback onTap;

  const _TopicCard({
    required this.data,
    required this.isSelected,
    required this.isTablet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Selected = white card with dark icon/text; unselected = dark card
    final Color cardColor = isSelected ? AppColors.white : AppColors.cardBg;
    final Color iconBg = isSelected
        ? const Color(0xFFE0E0E0)
        : const Color(0xFF1C1D2A);
    final Color iconColor = isSelected
        ? AppColors.black
        : AppColors.textPrimary;
    final Color labelColor = isSelected
        ? AppColors.black
        : AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.cardBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon circle
            Container(
              width: isTablet ? 56.w : 48.w,
              height: isTablet ? 56.w : 48.w,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(
                data.icon,
                color: iconColor,
                size: isTablet ? 26.sp : 22.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              data.label,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 14.sp : 13.sp,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submit Button (pinned at bottom)
// ─────────────────────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final bool isTablet;
  final VoidCallback onTap;

  const _SubmitButton({required this.isTablet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: isTablet ? 62.h : 54.h,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(32.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Submit Feedback',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 17.sp : 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.send_rounded,
                color: AppColors.black,
                size: isTablet ? 20.sp : 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
