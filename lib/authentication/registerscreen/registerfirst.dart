import 'dart:io';
import 'package:boomboom/backend/secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:boomboom/authentication/registerscreen/gender.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../constant/appsize.dart';
import '../../constant/apptextstyle.dart';
import '../../constant/colors.dart';
import '../../widget/outlinedbutton.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String email;
  const CompleteProfileScreen({super.key, this.email = ""});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  String name = "";
  DateTime? selectedDate;
  int age = 0;

  // 🔑 Password fields
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController bioController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  // 📸 Photos: max 6, min 1
  List<File> photos = [];
  static const int maxPhotos = 6;
  static const int minPhotos = 3;

  // 🎥 Videos: max 2, max 7 seconds each
  List<File> videos = [];
  static const int maxVideos = 2;
  static const int maxVideoSeconds = 6;

  final Map<String, double> uploadProgress = {};

  final ImagePicker _picker = ImagePicker();

  String emailAddress = "";

  @override
  void initState() {
    super.initState();
    emailAddress = widget.email;
    if (emailAddress.isEmpty) {
      _loadEmailFromStorage();
    }
  }

  Future<void> _loadEmailFromStorage() async {
    final storedEmail = await SecureStorage().getUserEmail();
    if (storedEmail != null && storedEmail.isNotEmpty) {
      if (mounted) {
        setState(() {
          emailAddress = storedEmail;
        });
      }
    }
  }

  Future<bool> _checkAndRequestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    final result = await Permission.camera.request();
    if (result.isGranted) return true;
    if (result.isPermanentlyDenied) {
      _showToast(
        "Camera permission is permanently denied. Please enable it in Settings.",
      );
      openAppSettings();
    } else {
      _showToast("Camera permission was denied.");
    }
    return false;
  }

  Future<bool> _checkAndRequestGalleryPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.photos.status;
      if (status.isGranted) return true;

      final result = await Permission.photos.request();
      if (result.isGranted) return true;

      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) return true;

      final storageResult = await Permission.storage.request();
      if (storageResult.isGranted) return true;

      if (storageResult.isPermanentlyDenied || result.isPermanentlyDenied) {
        _showToast(
          "Gallery permission is permanently denied. Please enable it in Settings.",
        );
        openAppSettings();
      } else {
        _showToast("Gallery permission was denied.");
      }
      return false;
    } else {
      final status = await Permission.photos.status;
      if (status.isGranted) return true;
      final result = await Permission.photos.request();
      if (result.isGranted) return true;
      if (result.isPermanentlyDenied) {
        _showToast(
          "Gallery permission is permanently denied. Please enable it in Settings.",
        );
        openAppSettings();
      } else {
        _showToast("Gallery permission was denied.");
      }
      return false;
    }
  }

  Future<void> pickPhoto(ImageSource source) async {
    if (source == ImageSource.gallery) {
      final granted = await _checkAndRequestGalleryPermission();
      if (!granted) return;

      final pickedFiles = await _picker.pickMultiImage(imageQuality: 50);

      if (!mounted) return;

      if (pickedFiles.isNotEmpty) {
        final remaining = maxPhotos - photos.length;

        if (remaining <= 0) {
          _showToast("Maximum $maxPhotos photos allowed");
          return;
        }

        final toAdd = pickedFiles.take(remaining).toList();
        setState(() {
          photos.addAll(toAdd.map((p) => File(p.path)));
        });
      }
    } else {
      final granted = await _checkAndRequestCameraPermission();
      if (!granted) return;

      if (photos.length >= maxPhotos) {
        _showToast("Maximum $maxPhotos photos allowed");
        return;
      }

      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50,
      );

      if (!mounted) return;

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        setState(() {
          photos.add(file);
        });
      }
    }
  }

  // ─────────────────────────────────────────
  // VIDEO LOGIC (yahi hai video upload ka asli function)
  // ─────────────────────────────────────────

  /// Video pick karne ka function.
  /// - Pehle max video count check hota hai
  /// - Phir picker khulta hai (gallery ya camera)
  /// - File milne ke baad duration check hota hai (best-effort)
  /// - Agar duration limit se zyada hai to video reject ho jata hai
  /// - Try-catch se wrap kiya gaya hai taaki koi bhi crash na ho
  Future<void> pickVideo(ImageSource source) async {
    if (videos.length >= maxVideos) {
      _showToast("Maximum $maxVideos videos allowed");
      return;
    }

    if (source == ImageSource.gallery) {
      final granted = await _checkAndRequestGalleryPermission();
      if (!granted) return;
    } else {
      final granted = await _checkAndRequestCameraPermission();
      if (!granted) return;
    }

    try {
      final pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: maxVideoSeconds),
      );

      if (!mounted) return;

      if (pickedFile == null) {
        // User ne picker cancel kar diya — kuch karne ki zaroorat nahi.
        return;
      }

      final file = File(pickedFile.path);

      // Duration validate karna (VideoPlayerController se, best-effort).
      VideoPlayerController? controller;
      bool isTooLong = false;

      try {
        controller = VideoPlayerController.file(file);
        await controller.initialize();
        final duration = controller.value.duration;

        // 500ms ka buffer rounding/encoding errors avoid karne ke liye.
        if (duration.inMilliseconds > (maxVideoSeconds * 1000) + 500) {
          isTooLong = true;
        }
      } catch (e) {
        // Duration read nahi ho payi to user ko block nahi karna —
        // picker already maxDuration enforce karta hai zyada platforms pe.
        debugPrint("Video duration check failed: $e");
      } finally {
        await controller?.dispose();
      }

      if (!mounted) return;

      if (isTooLong) {
        _showToast("Video must be $maxVideoSeconds seconds or less");
        return;
      }

      setState(() {
        videos.add(file);
      });
    } catch (e) {
      debugPrint("pickVideo error: $e");
      if (mounted) {
        _showToast("Could not load video. Please try again.");
      }
    }
  }

  void removeVideo(int index) {
    if (index >= 0 && index < videos.length) {
      setState(() {
        videos.removeAt(index);
      });
    }
  }

  void removePhoto(int index) {
    if (index >= 0 && index < photos.length) {
      setState(() {
        photos.removeAt(index);
      });
    }
  }

  // ─────────────────────────────────────────
  // HELPER: TOAST
  // ─────────────────────────────────────────

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─────────────────────────────────────────
  // BOTTOM SHEET: MEDIA PICKER
  // ─────────────────────────────────────────

  void openPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: EdgeInsets.all(AppSize.w(16)),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add Photo",
                style: AppTextStyles.subHeading.copyWith(
                  fontSize: AppSize.sp(16),
                ),
              ),
              SizedBox(height: AppSize.h(8)),
              Text(
                "${photos.length}/$maxPhotos photos • minimum $minPhotos required",
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: AppSize.h(16)),
              _pickerOption(
                icon: Icons.photo_library,
                title: "Choose from Gallery",
                onTap: () {
                  Navigator.pop(context);
                  pickPhoto(ImageSource.gallery);
                },
              ),
              SizedBox(height: AppSize.h(10)),
              _pickerOption(
                icon: Icons.camera_alt,
                title: "Take a Photo",
                onTap: () {
                  Navigator.pop(context);
                  pickPhoto(ImageSource.camera);
                },
              ),
              SizedBox(height: AppSize.h(10)),
            ],
          ),
        );
      },
    );
  }

  void openVideoPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: EdgeInsets.all(AppSize.w(16)),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add Video",
                style: AppTextStyles.subHeading.copyWith(
                  fontSize: AppSize.sp(16),
                ),
              ),
              SizedBox(height: AppSize.h(8)),
              Text(
                "${videos.length}/$maxVideos videos • max ${maxVideoSeconds}s each",
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: AppSize.h(16)),
              _pickerOption(
                icon: Icons.video_library,
                title: "Choose from Gallery",
                onTap: () {
                  Navigator.pop(context);
                  pickVideo(ImageSource.gallery);
                },
              ),
              SizedBox(height: AppSize.h(10)),
              _pickerOption(
                icon: Icons.videocam,
                title: "Record a Video",
                onTap: () {
                  Navigator.pop(context);
                  pickVideo(ImageSource.camera);
                },
              ),
              SizedBox(height: AppSize.h(10)),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // BOTTOM SHEET: DATE PICKER
  // ─────────────────────────────────────────

  void pickDateBottomSheet() {
    int selectedDay = 1;
    int selectedMonth = 4;
    int selectedYear = 2000;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final dayController = FixedExtentScrollController(
              initialItem: selectedDay - 1,
            );
            final monthController = FixedExtentScrollController(
              initialItem: selectedMonth - 1,
            );
            final yearController = FixedExtentScrollController(
              initialItem: selectedYear - 1950,
            );

            return Container(
              padding: EdgeInsets.all(AppSize.w(16)),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Select Date of Birth",
                        style: AppTextStyles.subHeading.copyWith(
                          fontSize: AppSize.sp(16),
                          color: AppColors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close, color: AppColors.white),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSize.h(15)),
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            "Day",
                            style: AppTextStyles.subHeading.copyWith(
                              fontSize: AppSize.sp(14),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            "Month",
                            style: AppTextStyles.subHeading.copyWith(
                              fontSize: AppSize.sp(14),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            "Year",
                            style: AppTextStyles.subHeading.copyWith(
                              fontSize: AppSize.sp(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSize.h(10)),
                  Row(
                    children: [
                      Expanded(
                        child: _pickerUI(
                          controller: dayController,
                          start: 1,
                          end: 31,
                          selectedValue: selectedDay,
                          onChanged: (val) =>
                              setStateSheet(() => selectedDay = val),
                        ),
                      ),
                      Expanded(
                        child: _pickerUI(
                          controller: monthController,
                          start: 1,
                          end: 12,
                          selectedValue: selectedMonth,
                          onChanged: (val) =>
                              setStateSheet(() => selectedMonth = val),
                          isMonth: true,
                        ),
                      ),
                      Expanded(
                        child: _pickerUI(
                          controller: yearController,
                          start: 1950,
                          end: DateTime.now().year,
                          selectedValue: selectedYear,
                          onChanged: (val) =>
                              setStateSheet(() => selectedYear = val),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSize.h(20)),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDate = DateTime(
                          selectedYear,
                          selectedMonth,
                          selectedDay,
                        );
                        age = DateTime.now().year - selectedYear;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: AppSize.h(50),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Text(
                          "Confirm",
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // VALIDATION
  // ─────────────────────────────────────────

  bool get isMediaDone => photos.length >= minPhotos;
  bool get isNameDone => name.isNotEmpty;
  bool get isDobDone => selectedDate != null;
  bool get isPasswordDone => passwordController.text.length >= 6;
  bool get isConfirmPasswordDone =>
      confirmPasswordController.text.isNotEmpty &&
      confirmPasswordController.text == passwordController.text;
  bool get canProceed =>
      isMediaDone &&
      isNameDone &&
      isDobDone &&
      isPasswordDone &&
      isConfirmPasswordDone;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    bioController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.primary,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.all(AppSize.w(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSize.h(16)),

              // ── HEADER ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create Your Account",
                          style: AppTextStyles.heading.copyWith(
                            fontSize: AppSize.sp(26),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: AppSize.h(4)),
                        Text(
                          "Sign up & get started",
                          style: AppTextStyles.subHeading.copyWith(
                            fontSize: AppSize.sp(16),
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: AppSize.h(4)),
                        Container(
                          height: 3,
                          width: AppSize.w(50),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFFFF6C9E)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sparkle decoration
                  Column(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: const Color(0xFF8B7FFF),
                        size: 22.sp,
                      ),
                      SizedBox(height: AppSize.h(4)),
                      Icon(
                        Icons.add,
                        color: const Color(0xFF8B7FFF),
                        size: 14.sp,
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: AppSize.h(14)),

              // ── AVATAR + MEDIA BUTTONS ──
              // NOTE: outer SizedBox gives the Stack extra width so the
              // pill (positioned to the right of the avatar) stays
              // INSIDE the Stack's bounds. With Clip.none + a negative
              // `right` that exceeds the Stack's own width, the pill can
              // render outside the parent's hit-test area, which makes
              // it look tappable but actually swallows no taps.
              Center(
                child: SizedBox(
                  width:
                      AppSize.w(100) + AppSize.w(70), // avatar + room for pill
                  height: AppSize.w(100) + AppSize.h(10),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Gradient ring avatar
                      Positioned(
                        left: 0,
                        top: 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: openPhotoPickerSheet,
                          child: Container(
                            height: AppSize.w(100),
                            width: AppSize.w(100),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFFFF6C9E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(3.w),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.secondary,
                                ),
                                child: photos.isNotEmpty
                                    ? ClipOval(
                                        child: Image.file(
                                          photos.first,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        color: AppColors.textSecondary,
                                        size: 40.sp,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Photo count badge
                      if (photos.isNotEmpty)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: IgnorePointer(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 5.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                "${photos.length}",
                                style: AppTextStyles.small.copyWith(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Camera + Video pill buttons — now positioned
                      // WITHIN the SizedBox's own width, so taps land
                      // correctly instead of falling outside the
                      // hit-test region.
                      Positioned(
                        bottom: 0,
                        left: AppSize.w(72),
                        child: _mediaPill(),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppSize.h(12)),

              Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Add your ",
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextSpan(
                        text: "photo and video!",
                        style: AppTextStyles.small.copyWith(
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFFFF6C9E)],
                            ).createShader(const Rect.fromLTWH(0, 0, 160, 20)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── MEDIA THUMBNAILS ROW (photos + videos) ──
              if (photos.isNotEmpty || videos.isNotEmpty) ...[
                SizedBox(height: AppSize.h(12)),
                _mediaThumbnailsRow(),
              ],

              SizedBox(height: AppSize.h(12)),

              // ── FULL NAME ──
              _labelWithIcon("Full Name", Icons.person),
              SizedBox(height: AppSize.h(8)),
              _neuField(
                child: Row(
                  children: [
                    Icon(Icons.person, color: AppColors.textSecondary),
                    SizedBox(width: AppSize.w(10)),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => name = v),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: "Boom boom",
                          hintStyle: AppTextStyles.body,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    isNameDone
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : Icon(Icons.close, color: AppColors.textSecondary),
                  ],
                ),
              ),

              SizedBox(height: AppSize.h(10)),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.textSecondary,
                    size: 16.sp,
                  ),
                  SizedBox(width: AppSize.w(6)),
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: AppSize.sp(13),
                      ),
                      children: [
                        const TextSpan(
                          text: "Please enter your age min age is ",
                        ),
                        TextSpan(
                          text: "18",
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.top,
                              child: Transform.translate(
                                offset: Offset(0, -3.h),
                                child: Icon(
                                  Icons.star,
                                  color: Colors.pink,
                                  size: 10.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const TextSpan(text: " Yrs"),
                      ],
                    ),
                  ),
                ],
              ),
              // ── DATE OF BIRTH ──
              //   _labelWithIcon("Date of Birth  min 18 Yrs", Icons.calendar_today),
              SizedBox(height: AppSize.h(8)),
              GestureDetector(
                onTap: pickDateBottomSheet,
                child: _neuField(
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.textSecondary,
                        size: 18.sp,
                      ),
                      SizedBox(width: AppSize.w(10)),
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? "Select date"
                              : "${selectedDate!.day} ${_monthName(selectedDate!.month)}, ${selectedDate!.year}",
                          style: selectedDate == null
                              ? AppTextStyles.body
                              : AppTextStyles.body.copyWith(
                                  color: AppColors.white,
                                ),
                        ),
                      ),
                      if (isDobDone) ...[
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                        SizedBox(width: AppSize.w(6)),
                      ],
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              if (selectedDate != null)
                Padding(
                  padding: EdgeInsets.only(top: AppSize.h(6)),
                  child: Text("$age years old", style: AppTextStyles.small),
                ),

              SizedBox(height: AppSize.h(10)),

              // ── BIO ──
              _labelWithIcon("Bio", Icons.notes),
              SizedBox(height: AppSize.h(8)),
              _neuField(
                child: Row(
                  children: [
                    Icon(
                      Icons.notes,
                      color: AppColors.textSecondary,
                      size: 18.sp,
                    ),
                    SizedBox(width: AppSize.w(10)),
                    Expanded(
                      child: TextField(
                        controller: bioController,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.white,
                        ),
                        onChanged: (v) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: "Enter a short bio",
                          hintStyle: AppTextStyles.body,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (bioController.text.trim().isNotEmpty) ...[
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                      SizedBox(width: AppSize.w(6)),
                    ],
                  ],
                ),
              ),
              SizedBox(height: AppSize.h(10)),

              // ── CREATE PASSWORD ──
              _labelWithIcon("Create Password", Icons.lock),
              SizedBox(height: AppSize.h(8)),
              _neuField(
                child: Row(
                  children: [
                    Icon(
                      Icons.lock,
                      color: AppColors.textSecondary,
                      size: 18.sp,
                    ),
                    SizedBox(width: AppSize.w(10)),
                    Expanded(
                      child: TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        onChanged: (v) => setState(() {}),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter password",
                          hintStyle: AppTextStyles.body,
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    if (isPasswordDone)
                      const Icon(Icons.check_circle, color: Colors.green)
                    else
                      GestureDetector(
                        onTap: () =>
                            setState(() => obscurePassword = !obscurePassword),
                        child: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textSecondary,
                          size: 18.sp,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: AppSize.h(10)),

              // ── CONFIRM PASSWORD ──
              _labelWithIcon("Confirm Password", Icons.lock_outline),
              SizedBox(height: AppSize.h(8)),
              _neuField(
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: AppColors.textSecondary,
                      size: 18.sp,
                    ),
                    SizedBox(width: AppSize.w(10)),
                    Expanded(
                      child: TextField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        onChanged: (v) => setState(() {}),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: "Re-enter password",
                          hintStyle: AppTextStyles.body,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (isConfirmPasswordDone)
                      const Icon(Icons.check_circle, color: Colors.green)
                    else
                      GestureDetector(
                        onTap: () => setState(
                          () =>
                              obscureConfirmPassword = !obscureConfirmPassword,
                        ),
                        child: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textSecondary,
                          size: 18.sp,
                        ),
                      ),
                  ],
                ),
              ),

              // const Spacer(),
              SizedBox(height: 18.sp),

              // ── NEXT BUTTON ──
              SizedBox(
                width: double.infinity,
                child: GradientBorderButton(
                  title: "Next",
                  isTablet: isTablet,
                  width: double.infinity,
                  height: 55,
                  onTap: () {
                    if (!isMediaDone) {
                      _showToast("Please add at least $minPhotos photos");
                      return;
                    }
                    if (!isNameDone) {
                      _showToast("Please enter your full name");
                      return;
                    }
                    if (!isDobDone) {
                      _showToast("Please select your date of birth");
                      return;
                    }
                    if (bioController.text.trim().isEmpty) {
                      _showToast("Please enter a short bio");
                      return;
                    }
                    if (!isPasswordDone) {
                      _showToast("Password must be at least 6 characters");
                      return;
                    }
                    if (!isConfirmPasswordDone) {
                      _showToast("Passwords do not match");
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GenderScreen(
                          isRegister: true,
                          email: emailAddress,
                          fullName: name,
                          dob: selectedDate != null
                              ? "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}"
                              : "",
                          password: passwordController.text,
                          bio: bioController.text,
                          photos: photos,
                          videos: videos,
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: AppSize.h(8)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────

  /// Camera + Video pill (matching screenshot design)
  Widget _mediaPill() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w(8),
        vertical: AppSize.h(6),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFFFF6C9E)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo button — opaque hit test + extra padding so the
          // tappable area is bigger than just the icon glyph.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: openPhotoPickerSheet,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              child: Row(
                children: [
                  Icon(Icons.camera_alt, color: Colors.white, size: 18.sp),
                  if (photos.isNotEmpty) ...[
                    SizedBox(width: 3.w),
                    Text(
                      "${photos.length}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            height: 18.h,
            width: 1,
            color: Colors.white38,
            margin: EdgeInsets.symmetric(horizontal: 8.w),
          ),
          // 🎥 Video button — yahi tap karne pe video upload sheet khulta hai
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: openVideoPickerSheet,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              child: Row(
                children: [
                  Icon(Icons.videocam, color: Colors.white, size: 18.sp),
                  if (videos.isNotEmpty) ...[
                    SizedBox(width: 3.w),
                    Text(
                      "${videos.length}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Horizontal scroll of photo + video thumbnails
  Widget _mediaThumbnailsRow() {
    final allMedia = [
      ...photos.map((f) => _MediaItem(file: f, isVideo: false)),
      ...videos.map((f) => _MediaItem(file: f, isVideo: true)),
    ];

    return SizedBox(
      height: AppSize.h(70),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: allMedia.length,
        separatorBuilder: (_, _) => SizedBox(width: AppSize.w(8)),
        itemBuilder: (_, i) {
          final item = allMedia[i];
          final isPhoto = !item.isVideo;
          final photoIdx = isPhoto ? photos.indexOf(item.file) : -1;
          final videoIdx = item.isVideo ? videos.indexOf(item.file) : -1;

          return Stack(
            children: [
              Container(
                width: AppSize.w(70),
                height: AppSize.h(70),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  color: AppColors.secondary,
                  border: Border.all(
                    color: isPhoto
                        ? const Color(0xFF6C63FF)
                        : const Color(0xFFFF6C9E),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9.r),
                  child: isPhoto
                      ? Image.file(item.file, fit: BoxFit.cover)
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(color: AppColors.secondary),
                            Icon(
                              Icons.play_circle_filled,
                              color: const Color(0xFFFF6C9E),
                              size: 32.sp,
                            ),
                          ],
                        ),
                ),
              ),
              // Uploading overlay or Success green tick
              Builder(
                builder: (context) {
                  final progress = uploadProgress[item.file.path] ?? 1.0;
                  if (progress < 1.0) {
                    return Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              "${(progress * 100).toInt()}%",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Positioned(
                    top: 3,
                    right: 3,
                    child: IgnorePointer(
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
              // ❌ Left side: tap to remove this photo/video
              Positioned(
                top: 3,
                left: 3,
                child: GestureDetector(
                  onTap: () {
                    if (isPhoto) {
                      removePhoto(photoIdx);
                    } else {
                      removeVideo(videoIdx);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 12.sp),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _labelWithIcon(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16.sp),
        SizedBox(width: AppSize.w(6)),
        Text(
          text,
          style: AppTextStyles.body.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: AppSize.sp(13),
          ),
        ),
      ],
    );
  }

  Widget _neuField({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFFFF6C9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(1.3),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSize.w(15)),
        height: AppSize.h(55),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.05),
              offset: const Offset(-4, -4),
              blurRadius: 6,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.9),
              offset: const Offset(4, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _pickerOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppSize.h(55),
        padding: EdgeInsets.symmetric(horizontal: AppSize.w(15)),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.05),
              offset: const Offset(-3, -3),
              blurRadius: 6,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.9),
              offset: const Offset(3, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.white),
            SizedBox(width: AppSize.w(12)),
            Text(
              title,
              style: AppTextStyles.body.copyWith(
                color: AppColors.white,
                fontSize: AppSize.sp(15),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerUI({
    required FixedExtentScrollController controller,
    required int start,
    required int end,
    required int selectedValue,
    required Function(int) onChanged,
    bool isMonth = false,
  }) {
    return Container(
      height: AppSize.h(160),
      margin: EdgeInsets.symmetric(horizontal: AppSize.w(5)),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            child: Container(
              height: AppSize.h(40),
              margin: EdgeInsets.symmetric(horizontal: AppSize.w(10)),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 40,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) => onChanged(start + index),
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final value = start + index;
                final isSelected = value == selectedValue;
                return GestureDetector(
                  onTap: () {
                    onChanged(value);
                    controller.animateToItem(
                      index,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Center(
                    child: Text(
                      isMonth ? _monthName(value) : value.toString(),
                      style: AppTextStyles.body.copyWith(
                        fontSize: isSelected ? AppSize.sp(16) : AppSize.sp(14),
                        color: isSelected
                            ? AppColors.black
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
              childCount: end - start + 1,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[m];
  }
}

/// Simple model to track media items
class _MediaItem {
  final File file;
  final bool isVideo;
  _MediaItem({required this.file, required this.isVideo});
}
