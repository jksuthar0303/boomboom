import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'privacyscreen.dart';
import 'termsscreen.dart';

class AppColors {
  static const bg           = Color(0xFF070709);
  static const cardBg       = Color(0xFF0F1017);
  static const cardBorder   = Color(0xFF1C1D2A);
  static const textPrimary  = Color(0xFFFFFFFF);
  static const textSecondary= Color(0xFFB0B0B0);
  static const grey         = Color(0xFF55576E);
  static const purple       = Color(0xFF7B3FE4);
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int selectedPlan = 1;

  final List<Map<String, dynamic>> plans = [
    {"title": "Standart",     "price": "\$9.99",  "duration": "/ Month"},
    {"title": "Popular",      "price": "\$19.99", "duration": "/ 6 Months", "popular": true},
    {"title": "Special Offer","price": "\$30.99", "duration": "/ year"},
  ];

  @override
  Widget build(BuildContext context) {
    final size     = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final hPad     = isTablet ? 40.0 : 22.0;
    final topPad   = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── HERO IMAGE ────────────────────────────────────────
            Stack(
              children: [
                // Image
                SizedBox(
                  width: double.infinity,
                  height: size.height * 0.45,
                  child: Image.network(
                    'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.cardBg,
                      child: const Icon(Icons.person, size: 100, color: Color(0x40FFFFFF)),
                    ),
                  ),
                ),

                // Bottom fade
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.bg.withValues(alpha: 0), AppColors.bg],
                      ),
                    ),
                  ),
                ),

                // Close ×
                Positioned(
                  top: topPad + 12,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 40, width: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),

            // ── CONTENT ───────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Title
                  Text(
                    "Premium Access",
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: isTablet ? 30 : 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    "Upgrade to Premium and quickly find new people in your area and chat without having to match first!",
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: isTablet ? 15 : 13,
                      height: 1.55,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── PLAN TILES ──────────────────────────────────
                  ...List.generate(plans.length, (index) {
                    final plan       = plans[index];
                    final isSelected = selectedPlan == index;
                    final isPopular  = plan['popular'] == true;

                    return GestureDetector(
                      onTap: () => setState(() => selectedPlan = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.purple.withValues(alpha: 0.12)
                              : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.purple : AppColors.cardBorder,
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [

                            // Radio
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 22, width: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.purple : AppColors.grey,
                                  width: 2,
                                ),
                                color: isSelected ? AppColors.purple : Colors.transparent,
                              ),
                              child: isSelected
                                  ? Center(
                                child: Container(
                                  height: 8, width: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                                  : null,
                            ),

                            const SizedBox(width: 16),

                            // Title + badge
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        plan['title'],
                                        style: GoogleFonts.poppins(
                                          color: AppColors.textPrimary,
                                          fontSize: isTablet ? 17 : 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (isPopular) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.purple,
                                            borderRadius: BorderRadius.circular(50),
                                          ),
                                          child: Text(
                                            "Popular",
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  // Price
                                  Text(
                                    "${plan['price']} ${plan['duration']}",
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textSecondary,
                                      fontSize: isTablet ? 14 : 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 10),

                  // Fine print
                  Center(
                    child: Text(
                      "This is an auto-renewable subscription. Payment is charged to your Apple ID account at the confirmation of purchase.",
                      style: GoogleFonts.poppins(
                        color: AppColors.grey,
                        fontSize: isTablet ? 11 : 10,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── SUBSCRIBE BUTTON ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: isTablet ? 64 : 56,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "SUBSCRIBE NOW",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: isTablet ? 17 : 15,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _link("Restore"),
                      _sep(),
                      _link("Privacy Policy"),
                      _sep(),
                      _link("Terms of Use"),
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

  Widget _link(String t) => GestureDetector(
    onTap: () {
      if (t == "Privacy Policy") {
        Get.to(() => const PrivacyPolicyScreen());
      } else if (t == "Terms of Use") {
        Get.to(() => const TermsOfUseScreen());
      }
    },
    child: Text(
      t,
      style: GoogleFonts.poppins(
        color: AppColors.grey,
        fontSize: 11,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.cardBorder,
      ),
    ),
  );

  Widget _sep() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 6),
    child: Text("·", style: TextStyle(color: AppColors.grey, fontSize: 14)),
  );
}