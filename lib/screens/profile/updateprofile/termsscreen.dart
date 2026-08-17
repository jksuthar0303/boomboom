import 'package:boomboom/constant/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.white,
            size: 18.sp,
          ),
          onPressed: () {
            Get.back();
          },
        ),
        title: Text(
          'Terms of Use',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            // Header Section with App's Purple Gradient
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9B59B6), Color(0xFF7B3FE4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B3FE4).withValues(alpha: 0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Terms of Use',
                        style: GoogleFonts.poppins(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Effective: 10/11/2025 | Updated: 10/11/2025',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5.sp,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Please read these terms carefully before using BoomBoom.',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Terms Sections (Expandable)
            const ExpandableTermsSection(
              icon: Icons.gavel_rounded,
              title: '1. Acceptance of Terms',
              content:
                  'By accessing or using the BoomBoom mobile application, website, or services, you agree to be bound by these Terms of Use and our Privacy Policy. If you do not agree to these terms, you must not access or use the application.',
            ),

            const ExpandableTermsSection(
              icon: Icons.verified_user_outlined,
              title: '2. Eligibility & Age Restriction',
              content:
                  'You must be at least 18 years of age (or the age of legal majority in your jurisdiction) to create an account and use BoomBoom.\n\n'
                  'By creating an account, you represent and warrant that:\n'
                  '• You can form a binding contract with BoomBoom.\n'
                  '• You have never been convicted of a felony or sexual offense.\n'
                  '• You are not barred from using our services under applicable law.',
            ),

            const ExpandableTermsSection(
              icon: Icons.account_circle_outlined,
              title: '3. Account Security & Responsibilities',
              content:
                  'You are responsible for maintaining the confidentiality of your login credentials. You agree that all information provided during registration is accurate, true, and up to date.\n\n'
                  'You must not share your account or allow any other individual to access your account. You agree to notify us immediately of any unauthorized use or security breach.',
            ),

            const ExpandableTermsSection(
              icon: Icons.rule_rounded,
              title: '4. Community Guidelines & Conduct',
              content:
                  'BoomBoom is built on mutual respect and safe connections. You agree NOT to:\n'
                  '• Harass, stalk, intimidate, abuse, or defame any person.\n'
                  '• Post explicit, defamatory, hate speech, or sexually unlawful content.\n'
                  '• Solicit money, perpetrate scams, or conduct financial fraud.\n'
                  '• Impersonate any person or entity or misrepresent your identity.\n'
                  '• Send spam, commercial promotions, or unauthorized advertisements.',
            ),

            const ExpandableTermsSection(
              icon: Icons.security_rounded,
              title: '5. Safety & Offline Interaction Disclaimer',
              content:
                  'BoomBoom is an online platform for social interaction. We do not conduct criminal background checks or verify user intentions.\n\n'
                  'Offline meetings with other users are solely at your own risk. Always prioritize your personal safety: meet in public places, do not share financial details, inform a trusted contact, and report suspicious activities immediately.',
            ),

            const ExpandableTermsSection(
              icon: Icons.credit_card_rounded,
              title: '6. Subscriptions & In-App Purchases',
              content:
                  'Certain features may require a paid subscription or purchase. Payments are processed through the respective app store (Apple App Store / Google Play Store).\n\n'
                  'Subscriptions auto-renew unless cancelled at least 24 hours prior to the end of the current billing cycle. All purchases are final and non-refundable unless required by applicable law.',
            ),

            const ExpandableTermsSection(
              icon: Icons.copyright_rounded,
              title: '7. Intellectual Property & Content Rights',
              content:
                  'You retain ownership of the content you upload, but you grant BoomBoom a worldwide, royalty-free, non-exclusive license to host, display, and distribute your content solely for operating and promoting the service.\n\n'
                  'All BoomBoom trademarks, graphics, and code are owned exclusively by the Company.',
            ),

            const ExpandableTermsSection(
              icon: Icons.block_rounded,
              title: '8. Suspension & Account Termination',
              content:
                  'We reserve the right to investigate, suspend, or permanently terminate your account without prior notice if you violate these Terms of Use, engage in misconduct, or pose a safety risk to other users.',
            ),

            const ExpandableTermsSection(
              icon: Icons.warning_amber_rounded,
              title: '9. Limitation of Liability',
              content:
                  'To the maximum extent permitted by law, BoomBoom, its founders, affiliates, and developers shall not be liable for any indirect, incidental, punitive, or consequential damages, or for any loss of data, bodily injury, emotional distress, or financial harm resulting from user interactions or platform access.',
            ),

            const ExpandableTermsSection(
              icon: Icons.headset_mic_rounded,
              title: '10. Contact & Grievance',
              content:
                  'If you have questions regarding these Terms of Use or wish to report a violation, please contact our support team at support@boomboom.com.',
            ),

            SizedBox(height: 14.h),
            Center(
              child: Text(
                'support@boomboom.com',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: const Color(0xFF9B59B6),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFF9B59B6),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}

class ExpandableTermsSection extends StatefulWidget {
  final IconData icon;
  final String title;
  final String content;

  const ExpandableTermsSection({
    super.key,
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  State<ExpandableTermsSection> createState() => _ExpandableTermsSectionState();
}

class _ExpandableTermsSectionState extends State<ExpandableTermsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: _isExpanded
                ? const Color(0xFF9B59B6).withValues(alpha: 0.6)
                : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF9B59B6).withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      widget.icon,
                      color: const Color(0xFF9B59B6),
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _isExpanded
                        ? const Color(0xFF9B59B6)
                        : AppColors.textSecondary,
                    size: 22.sp,
                  ),
                ],
              ),
              if (_isExpanded) ...[
                SizedBox(height: 12.h),
                Divider(
                  color: AppColors.cardBorder,
                  height: 1,
                ),
                Padding(
                  padding: EdgeInsets.only(top: 12.h),
                  child: Text(
                    widget.content,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
