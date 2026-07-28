import 'package:boomboom/constant/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart'; // For navigation

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg, // Set the screen background to black
      appBar: AppBar(
        backgroundColor: AppColors.blue,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white, // 👈 BACK BUTTON COLOR
          ),
          onPressed: () {
            Get.back();
          },
        ),

        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: ListView(
          children: [
            // Header Section
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policy',
                    style: GoogleFonts.poppins(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Effective: 10/11/2025 | Updated: 10/11/2025',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    'GDPR + Indian Law Compliant',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Legal Compliance Section (Expandable)
            ExpandableSection(
              icon: Icons.gavel,
              title: 'Legal Compliance',
              content:
                  'BoomBoom is committed to protecting user privacy in compliance with the Information Technology Act, 2000 (India), SPDI Rules, 2011, and GDPR (EU) wherever applicable.',
            ),

            ExpandableSection(
              icon: Icons.data_usage,
              title: '1. Information We Collect',
              content:
                  'A. Information you provide directly: Name, phone number, email, gender, date of birth, profile photos, bio, matching preferences and interests.\n\n'
                  'B. Automatically collected information: IP address, device ID, location data (if permitted), app analytics and crash logs.\n\n'
                  'C. Third-party information: If you sign in using Google or other providers, limited profile information may be received.',
            ),

            ExpandableSection(
              icon: Icons.track_changes,
              title: '2. Purpose of Data Collection',
              content:
                  'We use your information to create and manage user profiles, provide relevant matches, enable chatting and communication, prevent fraud, abuse and fake profiles, and improve app performance through analytics.\n\n'
                  'We do NOT sell user data or share data for marketing without your consent.',
            ),

            ExpandableSection(
              icon: Icons.share,
              title: '3. Data Sharing',
              content:
                  'We may share data with cloud storage providers for storing user media and information, analytics providers such as Firebase for app performance monitoring, and payment gateways for subscription processing.\n\n'
                  'All service providers are bound by confidentiality obligations.',
            ),

            ExpandableSection(
              icon: Icons.access_time,
              title: '4. Retention of Data',
              content:
                  'We retain your information while your account remains active or as required by applicable law. If you delete your account, data is removed except where retention is required for taxation, legal compliance, record-keeping, or abuse investigations.',
            ),

            ExpandableSection(
              icon: Icons.security,
              title: '5. User Rights',
              content:
                  'Subject to applicable law, you have the right to access your personal data, request corrections, request deletion, and withdraw consent.\n\n'
                  'Requests can be sent to support@boomboom.com.',
            ),

            ExpandableSection(
              icon: Icons.lock,
              title: '6. Security',
              content:
                  'We use encryption, access controls, and secure servers to protect user information. However, no online service can guarantee 100% security.\n\n'
                  'The Company is not liable for unauthorized access resulting from user negligence, such as sharing devices or using weak passwords.',
            ),

            ExpandableSection(
              icon: Icons.child_care,
              title: '7. Child Safety',
              content:
                  'BoomBoom does not knowingly allow anyone under the age of 18 to use the platform. Any account found to belong to a minor may be removed immediately.',
            ),

            ExpandableSection(
              icon: Icons.info,
              title: '8. Changes to Policy',
              content:
                  'Privacy Policy updates may be made from time to time. Any changes will be posted within the application and on the official website where applicable.',
            ),

            ExpandableSection(
              icon: Icons.warning,
              title: '9. Disclaimer & No Liability Policy',
              content:
                  'BoomBoom is a platform for connecting people and is not a matchmaking or marriage bureau.\n\n'
                  'The Company does not verify user identity, intentions, criminal background, or marital status. Offline meetings are conducted entirely at the user’s own risk.\n\n'
                  'The Company, its directors, employees, and developers shall not be responsible for fraud, scams, abuse, sexual harassment, financial loss, emotional suffering, injury, or death arising from user interactions.\n\n'
                  'Users are advised to verify identities, meet in public places, avoid sharing financial information, and contact local law enforcement in case of harassment or criminal activity.',
            ),
            SizedBox(height: 5.h),
            Text(
              'support@boomboom.com',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: AppColors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpandableSection extends StatefulWidget {
  final IconData icon;
  final String title;
  final String content;

  const ExpandableSection({
    super.key,
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ExpandableSectionState createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        color: AppColors.surface,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.icon, color: AppColors.blue, size: 24.sp),
                  SizedBox(width: 10.w),
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
              if (_isExpanded)
                Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: Text(
                    widget.content,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
