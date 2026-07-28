import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:boomboom/backend/secure_storage.dart';
import 'package:boomboom/backend/registerservice.dart';
import 'package:boomboom/controller/auth_controller.dart';
import 'package:boomboom/widget/snakbar.dart';
import 'package:boomboom/constant/appconstants.dart';

class LifestyleScreen extends StatefulWidget {
  final bool isRegister;

  // Registration parameters
  final String? email;
  final String? fullName;
  final String? dob;
  final String? password;
  final String? bio;
  final String? gender;
  final String? lookingFor;
  final String? orientation;
  final List<File>? photos;
  final List<File>? videos;

  const LifestyleScreen({
    super.key,
    this.isRegister = false,
    this.email,
    this.fullName,
    this.dob,
    this.password,
    this.bio,
    this.gender,
    this.lookingFor,
    this.orientation,
    this.photos,
    this.videos,
  });

  @override
  State<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen> {
  static const Color bg = Color(0xFF111116);
  static const Color accent = Color(0xFFa78bfa);
  static const Color shadowDark = Color(0xFF060607);
  static const Color shadowLight = Color(0xFF1c1c26);

  final AuthController _authController = Get.put(AuthController());
  final RegisterService _registerService = RegisterService();

  // Multi-select
  List<String> selectedInterests = [];

  // Single-select
  String? selectedBodyType;
  String? selectedwork;
  String? selectedEthnicity; // Personality Type
  String? selectedEyeColor; // Language Spoken
  String? selectedSmoking;
  String? selectedDrinking;
  String? selectedWorkout;

  double _heightCm = 175;
  bool _isSavingEdit = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  String? _findMatchingOption(String? val, List<String> options) {
    if (val == null || val.trim().isEmpty) return null;
    final cleanVal = val
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z]'), '')
        .trim();
    if (cleanVal.isEmpty) return null;
    for (var opt in options) {
      final cleanOpt = opt
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-zA-Z]'), '')
          .trim();
      if (cleanOpt == cleanVal ||
          cleanOpt.contains(cleanVal) ||
          cleanVal.contains(cleanOpt)) {
        return opt;
      }
    }
    return null;
  }

  Future<void> _loadProfileData() async {
    try {
      final jsonStr = await SecureStorage().getProfileJson();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        final List? dataList = decoded["Data"];
        if (dataList != null && dataList.isNotEmpty) {
          final data = dataList.first;
          if (mounted) {
            setState(() {
              // Option lists for mapping
              final bodyTypeOpts = [
                "Slim 🏃",
                "Athletic 🤸",
                "Average 🧍",
                "Curvy 🌊",
                "Muscular 💪",
                "Plus Size ✨",
              ];
              final workOpts = [
                "Business Owner",
                "Software Engineer",
                "Doctor",
                "Teacher",
                "Lawyer",
                "CA",
                "Goverment Jobs",
                "Private Jobs",
                "Students",
                "Enterpreneur",
                "Designer",
                "Influencer",
                "Marketing",
              ];
              final personalityOpts = [
                "Introvert",
                "Extrovert",
                "Funny",
                "Romantic",
                "Chilli",
                "Ambitious",
              ];
              final languageOpts = [
                "English",
                "Hindi",
                "Spanish",
                "French",
                "Arabic",
                "Mandrian",
                "Portuguese",
                "Russian",
                "Japanese",
                "Korean",
                "German",
                "Italian",
                "Turkish",
                "Bengali",
                "Chinese",
                "other",
              ];
              final smokingOpts = [
                "Non-smoker 🚭",
                "Occasional 🌿",
                "Social 👥",
                "Regular 🚬",
              ];
              final drinkingOpts = [
                "Non-drinker 🚫",
                "Social 🍺",
                "Occasionally 🥂",
                "Regular 🍷",
              ];
              final workoutOpts = [
                "Never 🛋️",
                "Sometimes 🚶",
                "Regular 🏋️",
                "Fitness Enthusiast 🔥",
              ];
              final interestOpts = AppConstants.interestOptions;

              selectedBodyType = _findMatchingOption(
                data["BodyType"],
                bodyTypeOpts,
              );
              selectedDrinking = _findMatchingOption(
                data["DrinkingHabits"],
                drinkingOpts,
              );
              selectedWorkout = _findMatchingOption(
                data["Workout"],
                workoutOpts,
              );
              selectedwork = _findMatchingOption(data["Occupation"], workOpts);

              if (data["Height"] != null) {
                final cleanedHeight = data["Height"].toString().replaceAll(
                  RegExp(r'[^0-9]'),
                  '',
                );
                final parsedHeight = double.tryParse(cleanedHeight);
                if (parsedHeight != null &&
                    parsedHeight >= 91 &&
                    parsedHeight <= 244) {
                  _heightCm = parsedHeight;
                }
              }

              if (data["Interests"] is List) {
                final List rawInts = data["Interests"];
                selectedInterests = [];
                for (var r in rawInts) {
                  final m = _findMatchingOption(r.toString(), interestOpts);
                  if (m != null) selectedInterests.add(m);
                }
              }

              if (data["Lifestyle"] is List) {
                final List<String> lst = List<String>.from(data["Lifestyle"]);
                for (var s in lst) {
                  final parts = s.split(":");
                  if (parts.length >= 2) {
                    final key = parts[0].trim();
                    final val = parts.sublist(1).join(":").trim();
                    if (key == "PersonalityType") {
                      selectedEthnicity = _findMatchingOption(
                        val,
                        personalityOpts,
                      );
                    }
                    if (key == "LanguageSpoken") {
                      selectedEyeColor = _findMatchingOption(val, languageOpts);
                    }
                    if (key == "Smoking") {
                      selectedSmoking = _findMatchingOption(val, smokingOpts);
                    }
                  }
                }
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading profile in LifestyleScreen: $e");
    }
  }

  bool get allFilled {
    if (widget.isRegister) {
      return selectedInterests.length >= 3 &&
          selectedBodyType != null &&
          selectedDrinking != null &&
          selectedWorkout != null;
    } else {
      return true;
    }
  }

  // ── MULTI SELECT (Interests) ──────────────────────────
  Widget _buildMultiSection(
    String title,
    List<String> options,
    List<String> selected,
    void Function(String) onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFe8e8f0),
                ),
              ),
              TextSpan(
                text: "  (Select at least 3)",
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF555555),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((item) {
            final bool isSel = selected.contains(item);
            return GestureDetector(
              onTap: () => setState(() => onToggle(item)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  color: isSel ? accent.withValues(alpha: 0.15) : bg,
                  border: Border.all(
                    color: isSel ? accent : const Color(0xFF1a1a22),
                    width: 1.5,
                  ),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSel ? accent : const Color(0xFF999999),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(
          selected.isEmpty
              ? "Pick at least 3"
              : selected.length < 3
              ? "${selected.length} picked — ${3 - selected.length} more needed"
              : "${selected.length} selected",
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: selected.length >= 3 ? accent : const Color(0xFF555555),
          ),
        ),
      ],
    );
  }

  // ── SINGLE SELECT ─────────────────────────────────────
  Widget _buildSection(
    String title,
    List<String> options,
    String? selected,
    void Function(String) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFe8e8f0),
                ),
              ),
              TextSpan(
                text: "  (Select one)",
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF555555),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((item) {
            final bool isSel = selected == item;
            return GestureDetector(
              onTap: () => setState(() => onSelect(item)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  color: isSel ? accent.withValues(alpha: 0.15) : bg,
                  border: Border.all(
                    color: isSel ? accent : const Color(0xFF1a1a22),
                    width: 1.5,
                  ),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSel ? accent : const Color(0xFF999999),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _divider() => Container(
    margin: const EdgeInsets.symmetric(vertical: 20),
    height: 1,
    color: Colors.white.withValues(alpha: 0.05),
  );

  Future<void> _handleSubmit() async {
    if (widget.isRegister) {
      // Execute registration API flow
      await _authController.register(
        email: widget.email!,
        fullName: widget.fullName!,
        dob: widget.dob!,
        password: widget.password!,
        bio: widget.bio!,
        gender: widget.gender!,
        lookingFor: widget.lookingFor!,
        orientation: widget.orientation!,
        occupation: selectedwork ?? "Not specified",
        height: "${_heightCm.toInt()} cm",
        bodyType: selectedBodyType ?? "Average",
        drinkingHabits: selectedDrinking ?? "Social",
        workout: selectedWorkout ?? "Sometimes",
        interests: selectedInterests,
        photos: widget.photos ?? [],
        videos: widget.videos ?? [],
      );
    } else {
      // Profile Edit Save mode
      setState(() => _isSavingEdit = true);
      try {
        final email = await SecureStorage().getUserEmail();
        if (email == null || email.isEmpty) {
          NeuSnackbar.error("Session expired. Please log in again.");
          return;
        }

        // 1. Load original interests from cache (normalized with emojis)
        List<String> originalInterests = [];
        final profileJsonStr = await SecureStorage().getProfileJson();
        if (profileJsonStr != null && profileJsonStr.isNotEmpty) {
          final decoded = jsonDecode(profileJsonStr);
          final List? dataList = decoded["Data"];
          if (dataList != null && dataList.isNotEmpty) {
            final data = dataList.first;
            if (data["Interests"] is List) {
              final List raw = data["Interests"];
              for (var r in raw) {
                final String rawName = r.toString().trim();
                final String matchedName =
                    AppConstants.findMatchingInterest(rawName) ?? rawName;
                if (matchedName.isNotEmpty) {
                  originalInterests.add(matchedName);
                }
              }
            }
          }
        }

        // 2. Load interest ID map
        Map<String, int> interestMap = {};
        final mapStr = await SecureStorage().getInterestMap();
        if (mapStr != null && mapStr.isNotEmpty) {
          try {
            final Map decodedMap = jsonDecode(mapStr);
            interestMap = decodedMap.map(
              (k, v) => MapEntry(k.toString(), int.parse(v.toString())),
            );
          } catch (e) {
            debugPrint("Error parsing interest map: $e");
          }
        }

        debugPrint("[SyncDebug] Original: $originalInterests");
        debugPrint("[SyncDebug] Selected: $selectedInterests");
        debugPrint("[SyncDebug] InterestMap: $interestMap");

        // 3. Handle deletions (in original but not in selected)
        for (var interest in originalInterests) {
          if (!selectedInterests.contains(interest)) {
            final id = interestMap[interest];
            if (id != null) {
              try {
                await _registerService.interestDelete(id: id, email: email);
                debugPrint("[InterestDelete] Deleted: $interest (ID: $id)");
              } catch (e) {
                debugPrint("[InterestDelete Error]: $e");
              }
            }
          }
        }

        // 4. Handle insertions (in selected but not in original)
        for (var interest in selectedInterests) {
          if (!originalInterests.contains(interest)) {
            try {
              await _registerService.interestInsert(
                email: email,
                interest: interest,
              );
              debugPrint("[InterestInsert] Inserted: $interest");
            } catch (e) {
              debugPrint("[InterestInsert Error]: $e");
            }
          }
        }

        // 2. Save selected lifestyles
        final List<String> lifestyleItems = [];
        if (selectedDrinking != null) {
          lifestyleItems.add("Drinking: $selectedDrinking");
        }
        if (selectedWorkout != null) {
          lifestyleItems.add("Workout: $selectedWorkout");
        }
        if (selectedBodyType != null) {
          lifestyleItems.add("BodyType: $selectedBodyType");
        }
        lifestyleItems.add("Height: ${_heightCm.toInt()} cm");
        if (selectedEthnicity != null) {
          lifestyleItems.add("PersonalityType: $selectedEthnicity");
        }
        if (selectedEyeColor != null) {
          lifestyleItems.add("LanguageSpoken: $selectedEyeColor");
        }
        if (selectedSmoking != null) {
          lifestyleItems.add("Smoking: $selectedSmoking");
        }

        for (var lifestyle in lifestyleItems) {
          await _registerService.lifestyleInsert(
            email: email,
            lifestyle: lifestyle,
          );
        }

        // 3. Sync full profile cache
        await _authController.fetchAndStoreFullProfile(email: email);

        NeuSnackbar.success("Profile parameters updated successfully!");

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint("[Save Edit Error]: $e");
        NeuSnackbar.error("Failed to save changes: $e");
      } finally {
        if (mounted) {
          setState(() => _isSavingEdit = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: widget.isRegister
          ? AppBar(
              backgroundColor: bg,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                "Final Steps",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isRegister
                              ? "Setup your vibe!"
                              : "Do they vibe with your lifestyle?",
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFe8e8f0),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Start sharing yours.",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Help others understand you better by sharing your preferences.",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF555555),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Interests Section (Always required)
                        _buildMultiSection(
                          "Interests",
                          AppConstants.interestOptions,
                          selectedInterests,
                          (v) {
                            selectedInterests.contains(v)
                                ? selectedInterests.remove(v)
                                : selectedInterests.add(v);
                          },
                        ),
                        _divider(),

                        // Body Type (Always required)
                        _buildSection(
                          "Body Type",
                          [
                            "Slim 🏃",
                            "Athletic 🤸",
                            "Average 🧍",
                            "Curvy 🌊",
                            "Muscular 💪",
                            "Plus Size ✨",
                          ],
                          selectedBodyType,
                          (v) => selectedBodyType = v,
                        ),
                        _divider(),

                        // Work / Occupation (Show in edit mode only)
                        if (!widget.isRegister) ...[
                          _buildSection(
                            "Work",
                            [
                              "Business Owner",
                              "Software Engineer",
                              "Doctor",
                              "Teacher",
                              "Lawyer",
                              "CA",
                              "Goverment Jobs",
                              "Private Jobs",
                              "Students",
                              "Enterpreneur",
                              "Designer",
                              "Influencer",
                              "Marketing",
                            ],
                            selectedwork,
                            (v) => selectedwork = v,
                          ),
                          _divider(),
                        ],

                        // Height (Always required)
                        Text(
                          "Height",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFe8e8f0),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1020),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.7),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          "${(_heightCm / 30.48).floor()}’",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Feet",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: Colors.white12,
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          "${_heightCm.toInt()}",
                                          style: GoogleFonts.poppins(
                                            color: accent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Centimeters",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 6,
                                  activeTrackColor: accent,
                                  inactiveTrackColor: Colors.white12,
                                  thumbColor: Colors.white,
                                  overlayColor: accent.withValues(alpha: .2),
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "91 cm",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    "${_heightCm.toInt()} cm",
                                    style: GoogleFonts.poppins(
                                      color: accent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    "244 cm",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _divider(),

                        // Personality Type (Edit mode only)
                        if (!widget.isRegister) ...[
                          _buildSection(
                            "Personality Type",
                            [
                              "Introvert",
                              "Extrovert",
                              "Funny",
                              "Romantic",
                              "Chilli",
                              "Ambitious",
                            ],
                            selectedEthnicity,
                            (v) => selectedEthnicity = v,
                          ),
                          _divider(),
                        ],

                        // Language Spoken (Edit mode only)
                        if (!widget.isRegister) ...[
                          _buildSection(
                            "Language Spoken",
                            [
                              "English",
                              "Hindi",
                              "Spanish",
                              "French",
                              "Arabic",
                              "Mandrian",
                              "Portuguese",
                              "Russian",
                              "Japanese",
                              "Korean",
                              "German",
                              "Italian",
                              "Turkish",
                              "Bengali",
                              "Chinese",
                              "other",
                            ],
                            selectedEyeColor,
                            (v) => selectedEyeColor = v,
                          ),
                          _divider(),
                        ],

                        // Smoking (Edit mode only)
                        if (!widget.isRegister) ...[
                          _buildSection(
                            "Smoking",
                            [
                              "Non-smoker 🚭",
                              "Occasional 🌿",
                              "Social 👥",
                              "Regular 🚬",
                            ],
                            selectedSmoking,
                            (v) => selectedSmoking = v,
                          ),
                          _divider(),
                        ],

                        // Drinking (Always required)
                        _buildSection(
                          "Drinking",
                          [
                            "Non-drinker 🚫",
                            "Social 🍺",
                            "Occasionally 🥂",
                            "Regular 🍷",
                          ],
                          selectedDrinking,
                          (v) => selectedDrinking = v,
                        ),
                        _divider(),

                        // Workout Frequency (Always required)
                        _buildSection(
                          "Workout Frequency",
                          [
                            "Never 🛋️",
                            "Sometimes 🚶",
                            "Regular 🏋️",
                            "Fitness Enthusiast 🔥",
                          ],
                          selectedWorkout,
                          (v) => selectedWorkout = v,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Fixed bottom button
                Container(
                  color: bg,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        allFilled
                            ? "All done — you're good to go!"
                            : "Fill all sections to continue",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: allFilled ? accent : const Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: allFilled ? _handleSubmit : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: allFilled
                                  ? accent
                                  : const Color(0xFF1a1a22),
                              width: 1.5,
                            ),
                            boxShadow: allFilled
                                ? [
                                    BoxShadow(
                                      color: shadowDark,
                                      offset: const Offset(3, 3),
                                      blurRadius: 7,
                                    ),
                                    BoxShadow(
                                      color: shadowLight,
                                      offset: const Offset(-3, -3),
                                      blurRadius: 7,
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: shadowDark,
                                      offset: const Offset(4, 4),
                                      blurRadius: 10,
                                    ),
                                    BoxShadow(
                                      color: shadowLight,
                                      offset: const Offset(-4, -4),
                                      blurRadius: 10,
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: Text(
                              widget.isRegister ? "Next" : "Save Profile",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: allFilled
                                    ? accent
                                    : const Color(0xFF333333),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading HUD for registration flow
          Obx(() {
            if (_authController.isLoading.value) {
              return Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1015),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: accent),
                        const SizedBox(height: 20),
                        Text(
                          _authController.loadingMessage.value,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_authController.uploadProgress.value > 0.0) ...[
                          LinearProgressIndicator(
                            value: _authController.uploadProgress.value,
                            backgroundColor: Colors.white10,
                            color: accent,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${(_authController.uploadProgress.value * 100).toInt()}% uploaded",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Local loading indicator for profile saving
          if (_isSavingEdit)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: accent),
              ),
            ),
        ],
      ),
    );
  }
}
