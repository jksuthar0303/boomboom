import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../backend/countryapi.dart';
import '../../../constant/appsize.dart';
import '../../../constant/apptextstyle.dart';
import '../../../constant/colors.dart';

// ─────────────────────────────────────────────
// DATA
// ─────────────────────────────────────────────

const List<String> kNationalities = [
  'Afghan',
  'Albanian',
  'Algerian',
  'American',
  'Andorran',
  'Angolan',
  'Argentine',
  'Armenian',
  'Australian',
  'Austrian',
  'Azerbaijani',
  'Bahraini',
  'Bangladeshi',
  'Belarusian',
  'Belgian',
  'Bolivian',
  'Bosnian',
  'Brazilian',
  'British',
  'Bulgarian',
  'Cambodian',
  'Cameroonian',
  'Canadian',
  'Chilean',
  'Chinese',
  'Colombian',
  'Congolese',
  'Croatian',
  'Cuban',
  'Czech',
  'Danish',
  'Dutch',
  'Egyptian',
  'Emirati',
  'Ethiopian',
  'Filipino',
  'Finnish',
  'French',
  'Georgian',
  'German',
  'Ghanaian',
  'Greek',
  'Guatemalan',
  'Haitian',
  'Honduran',
  'Hungarian',
  'Indian',
  'Indonesian',
  'Iranian',
  'Iraqi',
  'Irish',
  'Israeli',
  'Italian',
  'Ivorian',
  'Jamaican',
  'Japanese',
  'Jordanian',
  'Kazakhstani',
  'Kenyan',
  'Korean',
  'Kuwaiti',
  'Lebanese',
  'Libyan',
  'Lithuanian',
  'Malaysian',
  'Mexican',
  'Moroccan',
  'Mozambican',
  'Nepalese',
  'New Zealander',
  'Nigerian',
  'Norwegian',
  'Omani',
  'Pakistani',
  'Palestinian',
  'Paraguayan',
  'Peruvian',
  'Polish',
  'Portuguese',
  'Qatari',
  'Romanian',
  'Russian',
  'Saudi',
  'Senegalese',
  'Serbian',
  'Singaporean',
  'Somali',
  'South African',
  'Spanish',
  'Sri Lankan',
  'Sudanese',
  'Swedish',
  'Swiss',
  'Syrian',
  'Taiwanese',
  'Tanzanian',
  'Thai',
  'Tunisian',
  'Turkish',
  'Ugandan',
  'Ukrainian',
  'Uruguayan',
  'Uzbek',
  'Venezuelan',
  'Vietnamese',
  'Yemeni',
  'Zimbabwean',
];
// const List<String> kProfession = [
//   'Business Owner',
//   'Software Engineer',
//   'Doctor',
//   'Teacher',
//   'Lawyer',
//   'CA',
//   'Government Job',
//   'Private Job',
//   'Student',
//   'Entrepreneur',
//   'Designer',
//   'Influencer',
//   'Marketing',
//   'Sales',
//   'Freelancer',
//   'Other',
// ];

const List<String> kInterests = [
  '✈️ Travel',
  '📸 Photography',
  '📚 Reading',
  '🍷 Drink',
  '🥾 Hiking',
  '💃 Dancing',
  '🍕 Food',
  '🎉 Party',
];

//const List<String> kEthnicities  = ['Asian','Black','Hispanic','White','Mixed','Other'];
const List<String> kBodyTypes = [
  'Slim',
  'Athletic',
  'Average',
  'Curvy',
  'Muscular',
  'Plus Size',
];
//const List<String> kHeights      = ['Short (< 5\'4")','Average (5\'4" - 5\'9")','Tall (> 5\'9")'];
// HEIGHT SLIDER
double _heightCm = 175;
//const List<String> kEyeColors    = ['Brown','Blue','Green','Hazel','Gray','Other'];
const List<String> kSmoking = ['Non-smoker', 'Occasional', 'Regular', 'Social'];
const List<String> kDrinking = [
  'Non-drinker',
  'Social',
  'Regular',
  'Occasionally',
];
const List<String> kWorkout = [
  'Never',
  'Sometimes',
  'Regular',
  'Daily',
  'Fitness Enthusiast',
];
// const List<String> kLanguages    = ['English','Hindi','Spanish','French','Arabic','Mandarin',
//   'Portuguese','Russian','Japanese','Korean','German','Italian',
//   'Turkish','Bengali','Chinese','Other'];
//const List<String> kPersonality  = ['Introvert','Extrovert','Funny','Romantic','Chill','Ambitious'];
const List<String> kRelationship = [
  'Serious Love',
  'Casual',
  'Short Term',
  'Long Term',
  'Friendship',
  'Marriage',
  'Travel Partner',
  'Meet New People',
  'Mutual Support Partner',
];
//const List<String> kShowProfile  = ['Everyone','Matches Only'];

// ─────────────────────────────────────────────
// RESPONSIVE HELPER
// ─────────────────────────────────────────────

class _R {
  static bool isTablet(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 600;
  static double hPad(BuildContext ctx) => isTablet(ctx) ? 28.w : 16.w;

  static double titleFs(BuildContext ctx) => isTablet(ctx) ? 18.sp : 16.sp;

  static double labelFs(BuildContext ctx) => isTablet(ctx) ? 14.sp : 12.sp;

  static double chipFs(BuildContext ctx) => isTablet(ctx) ? 13.sp : 11.sp;

  static double sectionFs(BuildContext ctx) => isTablet(ctx) ? 16.sp : 14.sp;

  static double btnFs(BuildContext ctx) => isTablet(ctx) ? 17.sp : 15.sp;
}

// ─────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────

class FilterPreferencesScreen extends StatefulWidget {
  const FilterPreferencesScreen({super.key});

  @override
  State<FilterPreferencesScreen> createState() =>
      _FilterPreferencesScreenState();
}

class _FilterPreferencesScreenState extends State<FilterPreferencesScreen> {
  int selectedTab = 0;

  double _minAge = 18;
  double _maxAge = 100;
  double _distance = 50;
  String? _selectedNationality;
  String _cityCountry = '';

  final Set<String> _selectedGenders = {};
  final Set<String> _selectedInterests = {};
  // final Set<String> _selectedEthnicities  = {};
  final Set<String> _selectedBodyTypes = {};
  final Set<String> _selectedHeights = {};
  // final Set<String> _selectedEyeColors    = {};
  // final Set<String> _selectedSmoking      = {};
  final Set<String> _selectedDrinking = {};
  final Set<String> _selectedWorkout = {};
  // final Set<String> _selectedLanguages    = {};
  // final Set<String> _selectedPersonality  = {};
  final Set<String> _selectedRelationship = {};
  //final Set<String> _selectedShowProfile  = {};
  // final Set<String> _selectedProfession = {};
  void _clearAll() {
    setState(() {
      _minAge = 18;
      _maxAge = 100;
      _distance = 50;
      _cityCountry = '';
      _selectedNationality = null;
      _selectedGenders.clear();
      _selectedInterests.clear();
      //_selectedEthnicities.clear();  _selectedBodyTypes.clear();
      _selectedHeights.clear(); // _selectedEyeColors.clear();
      // _selectedSmoking.clear();      _selectedDrinking.clear();
      _selectedWorkout.clear(); // _selectedLanguages.clear();
      // _selectedPersonality.clear();  _selectedRelationship.clear();
      //_selectedShowProfile.clear();
      // _selectedProfession.clear();
    });
  }

  void _applyFilters() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Filters Applied!',
          style: AppTextStyles.body.copyWith(color: AppColors.white),
        ),
        backgroundColor: const Color(0xFFE8335A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _R.hPad(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.white,
            size: 18.sp,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Filter Preferences',
          style: AppTextStyles.subHeading.copyWith(
            fontSize: _R.titleFs(context),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: hPad, vertical: 10.h),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTab = 0;
                      });
                    },
                    child: Container(
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: selectedTab == 0
                            ? Colors.white
                            : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: Text(
                          "Basic Filter",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: selectedTab == 0
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 10.w),

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTab = 1;
                      });
                    },
                    child: Container(
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: selectedTab == 1
                            ? Colors.white
                            : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: Text(
                          "Advanced Filter",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: selectedTab == 1
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: hPad,
                vertical: AppSize.h(8),
              ),
              child: _R.isTablet(context)
                  ? _tabletBody(context)
                  : _phoneBody(context),
            ),
          ),
          _bottomButtons(context),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PHONE BODY
  // ─────────────────────────────────────────────

  Widget _phoneBody(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: _allSections(context),
  );

  // ─────────────────────────────────────────────
  // TABLET BODY — 2 column for chips sections
  // ─────────────────────────────────────────────

  Widget _tabletBody(BuildContext context) {
    final sections = _allSections(context);
    // First 4 sections in left, rest in right for tablet
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sections.sublist(0, sections.length ~/ 2),
          ),
        ),
        SizedBox(width: AppSize.w(20)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sections.sublist(sections.length ~/ 2),
          ),
        ),
      ],
    );
  }

  List<Widget> _allSections(BuildContext context) {
    if (selectedTab == 0) {
      return [
        // Age Range
        _sectionTitle('Age Range', context),
        SizedBox(height: AppSize.h(8)),
        _ageRangePill(context),
        SizedBox(height: AppSize.h(12)),

        _label('Minimum Age: ${_minAge.toInt()}', context),
        _buildSlider(
          _minAge,
          18,
          80,
          (v) => setState(() => _minAge = v.clamp(18, _maxAge - 1)),
        ),

        _label('Maximum Age: ${_maxAge.toInt()}', context),
        _buildSlider(
          _maxAge,
          19,
          100,
          (v) => setState(() => _maxAge = v.clamp(_minAge + 1, 100)),
        ),

        SizedBox(height: AppSize.h(16)),

        // Distance
        _label('Maximum Distance: ${_distance.toInt()} km', context),

        _buildSlider(_distance, 1, 150, (v) => setState(() => _distance = v)),

        SizedBox(height: AppSize.h(16)),

        // Show Me
        _sectionTitle('Show Me', context),
        SizedBox(height: AppSize.h(10)),

        _chipRow(
          ['Men', 'Women', 'Non-Binary', 'Transgender'],
          _selectedGenders,
          context,
        ),

        SizedBox(height: AppSize.h(16)),

        // Relationship
        _sectionTitle('Relationship Type', context),
        SizedBox(height: AppSize.h(10)),

        _chipRow(kRelationship, _selectedRelationship, context),

        SizedBox(height: AppSize.h(16)),

        // Interests
        _sectionTitle('Interests', context),
        SizedBox(height: AppSize.h(10)),

        _interestChips(context),
      ];
    }

    return _advancedSections(context);
  }

  List<Widget> _advancedSections(BuildContext context) => [
    _sectionTitle('Physical & Lifestyle Preferences', context),
    SizedBox(height: AppSize.h(16)),

    _label('Nationality', context),
    SizedBox(height: AppSize.h(6)),
    _nationalityDropdown(context),
    SizedBox(height: AppSize.h(16)),

    _label('City / Country', context),
    SizedBox(height: AppSize.h(6)),
    _textField(
      hint: 'Enter city or country...',
      value: _cityCountry,
      onChanged: (v) => setState(() => _cityCountry = v),
      context: context,
    ),
    SizedBox(height: AppSize.h(16)),

    // _label('Ethnicity', context),
    // SizedBox(height: AppSize.h(8)),
    // _chipRow(kEthnicities, _selectedEthnicities, context),
    // SizedBox(height: AppSize.h(16)),
    _label('Body Type', context),
    SizedBox(height: AppSize.h(8)),
    _chipRow(kBodyTypes, _selectedBodyTypes, context),
    SizedBox(height: AppSize.h(16)),

    _label('Height', context),
    SizedBox(height: AppSize.h(10)),

    Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 0.h),

      decoration: BoxDecoration(
        color: const Color(0xFF0B1020),
        borderRadius: BorderRadius.circular(22.r),

        border: Border.all(
          color: const Color(0xFF9B4DFF).withValues(alpha: 0.7),
          width: 1.2,
        ),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9B4DFF).withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          Text(
            "Height",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 8.h),

          /// VALUES
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// FEET
              Expanded(
                child: Column(
                  children: [
                    Text(
                      "${(_heightCm / 30.48).floor()}’",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4.h),

                    Text(
                      "Feet",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),

              Container(width: 1, height: 25.h, color: Colors.white12),

              /// CM
              Expanded(
                child: Column(
                  children: [
                    Text(
                      "${_heightCm.toInt()}",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFB26BFF),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4.h),

                    Text(
                      "Centimeters",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 5.h),

          /// SLIDER
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6.h,

              activeTrackColor: const Color(0xFF9B4DFF),
              inactiveTrackColor: Colors.white12,

              thumbColor: Colors.white,

              overlayColor: const Color(0xFF9B4DFF).withValues(alpha: 0.2),

              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.r),

              overlayShape: RoundSliderOverlayShape(overlayRadius: 20.r),
            ),

            child: Slider(
              value: _heightCm,
              min: 91,
              max: 244,

              onChanged: (v) {
                setState(() {
                  _heightCm = v;
                });
              },
            ),
          ),

          /// BOTTOM VALUES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "3'0\"",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12.sp,
                    ),
                  ),

                  Text(
                    "91 cm",
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),

              Column(
                children: [
                  Text(
                    "${((_heightCm / 30.48).floor())}'${((((_heightCm / 30.48) - (_heightCm / 30.48).floor()) * 12)).round()}\"",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFB26BFF),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Text(
                    "${_heightCm.toInt()} cm",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFB26BFF),
                      fontSize: 8.sp,
                    ),
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "8'0\"",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10.sp,
                    ),
                  ),

                  Text(
                    "244 cm",
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 8.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),

    SizedBox(height: AppSize.h(16)),

    // _label('Eye Color', context),
    // SizedBox(height: AppSize.h(8)),
    // _chipRow(kEyeColors, _selectedEyeColors, context),
    // SizedBox(height: AppSize.h(16)),
    // _label('Profession / Work', context),
    // SizedBox(height: AppSize.h(8)),
    // // _chipRow(kProfession, _selectedProfession, context),
    // // SizedBox(height: AppSize.h(16)),

    // _label('Language Spoken', context),
    // SizedBox(height: AppSize.h(8)),
    // // _chipRow(kLanguages, _selectedLanguages, context),
    // SizedBox(height: AppSize.h(16)),

    // _label('Personality Type', context),
    // SizedBox(height: AppSize.h(8)),
    // _chipRow(kPersonality, _selectedPersonality, context),
    // SizedBox(height: AppSize.h(16)),

    // _label('Smoking', context),
    // SizedBox(height: AppSize.h(8)),
    // _chipRow(kSmoking, _selectedSmoking, context),
    // SizedBox(height: AppSize.h(16)),
    _label('Drinking', context),
    SizedBox(height: AppSize.h(8)),
    _chipRow(kDrinking, _selectedDrinking, context),
    SizedBox(height: AppSize.h(16)),

    _label('Workout Frequency', context),
    SizedBox(height: AppSize.h(8)),
    _chipRow(kWorkout, _selectedWorkout, context),
    SizedBox(height: AppSize.h(16)),

    // _label('Show Profile To', context),
    // SizedBox(height: AppSize.h(8)),
    // _chipRow(kShowProfile, _selectedShowProfile, context),
    // SizedBox(height: AppSize.h(24)),
  ];

  // ─────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────

  Widget _sectionTitle(String text, BuildContext context) => Text(
    text,
    style: AppTextStyles.body.copyWith(
      color: AppColors.textPrimary,
      fontSize: _R.sectionFs(context),
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _label(String text, BuildContext context) => Text(
    text,
    style: AppTextStyles.body.copyWith(
      color: AppColors.textSecondary,
      fontSize: _R.labelFs(context),
    ),
  );

  Widget _buildSlider(
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => SliderTheme(
    data: SliderTheme.of(context).copyWith(
      activeTrackColor: const Color(0xFFE8335A),
      inactiveTrackColor: AppColors.cardBorder,
      thumbColor: AppColors.white,
      overlayColor: const Color(0x22E8335A),
      trackHeight: 3,
    ),
    child: Slider(value: value, min: min, max: max, onChanged: onChanged),
  );

  Widget _ageRangePill(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(vertical: AppSize.h(16)),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Center(
      child: Text(
        '${_minAge.toInt()} - ${_maxAge.toInt()} years old',
        style: AppTextStyles.body.copyWith(
          color: AppColors.textPrimary,
          fontSize: _R.isTablet(context) ? 19.sp : 17.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  // Widget _activeUsersRow(BuildContext context) => Row(
  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //   children: [
  //     Text('Active Users Only Filter',
  //         style: AppTextStyles.body.copyWith(
  //           color: AppColors.textPrimary,
  //           fontSize: _R.labelFs(context),
  //           fontWeight: FontWeight.w600,
  //         )),
  //     Switch(
  //       value: _activeOnly,
  //       activeColor: const Color(0xFFE8335A),
  //       inactiveTrackColor: AppColors.cardBorder,
  //       onChanged: (v) => setState(() => _activeOnly = v),
  //     ),
  //   ],
  // );

  Widget _chipRow(
    List<String> options,
    Set<String> selected,
    BuildContext context,
  ) {
    return Wrap(
      spacing: AppSize.w(8),
      runSpacing: AppSize.h(8),
      children: options.map((o) {
        final isSelected = selected.contains(o);
        return GestureDetector(
          onTap: () => setState(() {
            if (isSelected) {
              selected.remove(o);
            } else {
              selected.add(o);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: AppSize.w(16),
              vertical: AppSize.h(10),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.r),
              color: isSelected
                  ? const Color(0xFFE8335A) // Interests wala red
                  : Colors.black.withValues(alpha: 0.55),

              border: Border.all(
                color: isSelected
                    ? const Color(0xFFE8335A)
                    : const Color(0xFF2D7DFF),
                width: 1.3,
              ),

              boxShadow: [
                BoxShadow(
                  color:
                      (isSelected
                              ? const Color(0xFFE8335A)
                              : const Color(0xFF2D7DFF))
                          .withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              o,
              style: AppTextStyles.small.copyWith(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: _R.chipFs(context),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _interestChips(BuildContext context) {
    return Wrap(
      spacing: AppSize.w(8),
      runSpacing: AppSize.h(8),
      children: kInterests.map((o) {
        final isSelected = _selectedInterests.contains(o);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedInterests.remove(o);
              } else if (_selectedInterests.length < 10)
                // ignore: curly_braces_in_flow_control_structures
                _selectedInterests.add(o);
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: AppSize.w(14),
              vertical: AppSize.h(10),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.r),
              color: isSelected
                  ? const Color(0xFFE8335A)
                  : Colors.black.withValues(alpha: 0.55),

              border: Border.all(
                color: isSelected
                    ? const Color(0xFFE8335A)
                    : const Color(0xFF2D7DFF),
                width: 1.3,
              ),

              boxShadow: [
                BoxShadow(
                  color:
                      (isSelected
                              ? const Color(0xFFE8335A)
                              : const Color(0xFF2D7DFF))
                          .withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              o,
              style: AppTextStyles.small.copyWith(
                color: Colors.white,
                fontSize: _R.chipFs(context),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _nationalityDropdown(BuildContext context) => GestureDetector(
    onTap: () => _openNationalitySearch(),
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w(16),
        vertical: AppSize.h(16),
      ),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _selectedNationality ?? 'Select nationality',
            style: AppTextStyles.body.copyWith(
              color: _selectedNationality != null
                  ? AppColors.textPrimary
                  : AppColors.grey,
              fontSize: _R.labelFs(context),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
            size: 20.sp,
          ),
        ],
      ),
    ),
  );

  void _openNationalitySearch() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => const _NationalitySearchSheet(),
    );
    if (result != null) setState(() => _selectedNationality = result);
  }

  Widget _textField({
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
    required BuildContext context,
  }) => TextField(
    controller: TextEditingController(text: value)
      ..selection = TextSelection.collapsed(offset: value.length),
    style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.grey),
      filled: true,
      fillColor: AppColors.inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFE8335A)),
      ),
    ),
    onChanged: onChanged,
  );

  // ─────────────────────────────────────────────
  // FIXED BOTTOM BUTTONS
  // ─────────────────────────────────────────────

  Widget _bottomButtons(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      _R.hPad(context),
      AppSize.h(12),
      _R.hPad(context),
      AppSize.h(16),
    ),
    decoration: BoxDecoration(
      color: AppColors.primary,
      border: Border(top: BorderSide(color: AppColors.cardBorder)),
    ),
    child: Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _clearAll,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: AppSize.h(16)),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Center(
                child: Text(
                  'CLEAR ALL',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: _R.btnFs(context),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: AppSize.w(12)),
        Expanded(
          child: GestureDetector(
            onTap: _applyFilters,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: AppSize.h(16)),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Center(
                child: Text(
                  'APPLY FILTERS',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.black,
                    fontSize: _R.btnFs(context),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
// NATIONALITY SEARCH SHEET
// ─────────────────────────────────────────────

class _NationalitySearchSheet extends StatefulWidget {
  const _NationalitySearchSheet();

  @override
  State<_NationalitySearchSheet> createState() =>
      _NationalitySearchSheetState();
}

class _NationalitySearchSheetState extends State<_NationalitySearchSheet> {
  final LocationController _locationController = Get.put(LocationController());

  @override
  void initState() {
    super.initState();
    _locationController.fetchCountries();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSize.w(16),
          AppSize.h(16),
          AppSize.w(16),
          0,
        ),
        child: Column(
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: AppSize.h(16)),
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            Text(
              'Select Nationality',
              style: AppTextStyles.subHeading.copyWith(fontSize: 17.sp),
            ),
            SizedBox(height: AppSize.h(12)),
            TextField(
              autofocus: true,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search nationality...',
                hintStyle: AppTextStyles.body.copyWith(color: AppColors.grey),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.grey,
                  size: 20.sp,
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                _locationController.filterCountries(v);
              },
            ),
            SizedBox(height: AppSize.h(8)),
            Expanded(
              child: Obx(() {
                final list = _locationController.filteredCountries;

                if (list.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE8335A)),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final country = list[i];
                    return ListTile(
                      // ── FLAG IMAGE ──
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: Image.network(
                          country["flag"] ?? '',
                          width: 32.w,
                          height: 22.h,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.flag_outlined,
                            color: AppColors.grey,
                            size: 20.sp,
                          ),
                        ),
                      ),
                      title: Text(
                        country["name"] ?? '',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, country["name"]),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: AppColors.grey,
                        size: 18.sp,
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
