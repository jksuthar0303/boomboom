import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../../constant/colors.dart';
import '../../../controller/user_controller.dart';

// ── Paste your actual import paths below ──────────────────────────────────────
// import 'package:your_app/core/theme/colors.dart';
// import 'package:your_app/core/theme/text_styles.dart';
// import 'package:your_app/core/utils/app_size.dart';
// ─────────────────────────────────────────────────────────────────────────────
// For self-contained preview the colours / styles are inlined here.
// Remove these and use your imports once you integrate.

// ─────────────────────────────────────────────────────────────────────────────

enum DeleteReason {
  noLongerNeeded,
  privacyConcerns,
  foundBetterAlternative,
  difficultToUse,
  other,
}

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final UserController _controller = Get.put(UserController());
  DeleteReason? _selectedReason;

  final List<_ReasonItem> _reasons = const [
    _ReasonItem(
      reason: DeleteReason.noLongerNeeded,
      label: 'I no longer need this account',
    ),
    _ReasonItem(
      reason: DeleteReason.privacyConcerns,
      label: 'I have privacy concerns',
    ),
    _ReasonItem(
      reason: DeleteReason.foundBetterAlternative,
      label: 'I found a better alternative',
    ),
    _ReasonItem(reason: DeleteReason.difficultToUse, label: 'Difficult to use'),
    _ReasonItem(reason: DeleteReason.other, label: 'Other'),
  ];

  void _onReasonTap(DeleteReason reason) {
    setState(() => _selectedReason = reason);
  }

  void _onDeleteTap() {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason to continue.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(
          'Are you sure?',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This action cannot be undone.',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close confirmation dialog
              _controller.deleteAccount(context);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive helpers — works for both phone and tablet
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double horizontalPadding = isTablet ? 64.w : 20.w;
    final double maxContentWidth = isTablet ? 600.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Title ──────────────────────────────────────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.sp),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.12,
                            ), // soft glass effect
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.08),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 15.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 50.w),
                      Text(
                        'Delete Account',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 26.sp : 22.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10.h),

                  // ── Subtitle ───────────────────────────────────────────────
                  Text(
                    "We're sorry to see you go. Please let us know why you're leaving.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 15.sp : 13.sp,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // ── Section label ──────────────────────────────────────────
                  Text(
                    'SELECT A REASON',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 13.sp : 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),

                  SizedBox(height: 14.h),

                  // ── Radio options ──────────────────────────────────────────
                  ..._reasons.map(
                    (item) => _ReasonTile(
                      item: item,
                      isSelected: _selectedReason == item.reason,
                      isTablet: isTablet,
                      onTap: () => _onReasonTap(item.reason),
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // ── Warning banner ─────────────────────────────────────────
                  _WarningBanner(isTablet: isTablet),

                  SizedBox(height: 28.h),

                  // ── Delete button ──────────────────────────────────────────
                  _DeleteButton(
                    isTablet: isTablet,
                    enabled: _selectedReason != null,
                    onTap: _onDeleteTap,
                  ),

                  SizedBox(height: 20.h),

                  // ── Cancel ─────────────────────────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(
                        'Cancel and go back',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 15.sp : 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ReasonItem {
  final DeleteReason reason;
  final String label;
  const _ReasonItem({required this.reason, required this.label});
}

class _ReasonTile extends StatelessWidget {
  final _ReasonItem item;
  final bool isSelected;
  final bool isTablet;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.item,
    required this.isSelected,
    required this.isTablet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: isTablet ? 18.h : 16.h,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? AppColors.error.withValues(alpha: 0.7)
                : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Custom radio circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isTablet ? 24.w : 22.w,
              height: isTablet ? 24.w : 22.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.error : AppColors.grey,
                  width: isSelected ? 5.5 : 1.8,
                ),
                color: Colors.transparent,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                item.label,
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 15.sp : 14.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final bool isTablet;
  const _WarningBanner({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: isTablet ? 20.h : 16.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lightning icon inside red circle
          Container(
            width: isTablet ? 40.w : 36.w,
            height: isTablet ? 40.w : 36.w,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.bolt,
                color: AppColors.accent,
                size: isTablet ? 22.sp : 20.sp,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warning',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 15.sp : 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'This action cannot be undone. All your data will be permanently deleted from our servers.',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 13.sp : 12.sp,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final bool isTablet;
  final bool enabled;
  final VoidCallback onTap;

  const _DeleteButton({
    required this.isTablet,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: isTablet ? 60.h : 54.h,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.error.withValues(alpha: 0.15)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: enabled
                ? AppColors.error.withValues(alpha: 0.4)
                : AppColors.cardBorder,
          ),
        ),
        child: Center(
          child: Text(
            'Delete Account Permanently',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 16.sp : 15.sp,
              fontWeight: FontWeight.w600,
              color: enabled ? AppColors.textPrimary : AppColors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
