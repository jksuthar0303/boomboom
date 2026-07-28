import 'package:boomboom/screens/profile/updateprofile/updatepersona.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controller/user_controller.dart';
import '../bottombar.dart';

import '../../authentication/registerscreen/Sexsualorentation.dart';
import '../../authentication/registerscreen/gender.dart';
import '../../authentication/registerscreen/imagesselection.dart';
import '../../authentication/registerscreen/intrest.dart';
import '../../authentication/registerscreen/whatyourarelookingfor.dart';
import '../../constant/appsize.dart';
import '../../constant/apptextstyle.dart';
import '../../constant/colors.dart';

class UpdateProfileTabsScreen extends StatefulWidget {
  const UpdateProfileTabsScreen({super.key});

  @override
  State<UpdateProfileTabsScreen> createState() =>
      _UpdateProfileTabsScreenState();
}

class _UpdateProfileTabsScreenState extends State<UpdateProfileTabsScreen> {
  int selectedTab = 0;
  final UserController userController = Get.put(UserController());

  @override
  void initState() {
    super.initState();
    userController.initializeProfileFields();
  }

  /// ✅ TABS TEXT
  final List<String> tabs = [
    "Personal Info",
    "Lifestyle",
    "Looking For",
    "Orientation",
    "Photos",
    //"Location",
    "Gender",
  ];

  /// ✅ SCREENS
  final List<Widget> screens = [
    UpdatePersonInfoUI(),
    LifestyleScreen(),
    LookingForScreen(),
    SexualOrientationScreen(),
    UploadPhotosScreen(),
    // LocationEnabledScreen(),
    GenderScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            /// 🔥 HEADER
            Container(
              margin: EdgeInsets.all(AppSize.w(16)),
              padding: EdgeInsets.symmetric(
                horizontal: AppSize.w(12),
                vertical: AppSize.h(12),
              ),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(4, 4),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.05),
                    offset: Offset(-4, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  /// 🔙 BACK BUTTON
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(3, 3),
                            blurRadius: 6,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.05),
                            offset: Offset(-3, -3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textPrimary,
                        size: 16.sp,
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  /// ✏️ TITLE
                  Icon(Icons.edit, color: AppColors.accent, size: 20.sp),
                  SizedBox(width: 8.w),

                  Expanded(
                    child: Text(
                      "Update Your Profile",
                      style: AppTextStyles.heading.copyWith(
                        fontSize: isTablet ? 24.sp : 20.sp,
                      ),
                    ),
                  ),

                  /// 💾 SAVE BUTTON
                  GestureDetector(
                    onTap: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );

                      final success = await userController.saveProfile();
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context); // close loader
                        if (success) {
                          Get.offAll(() => const MainScreen());
                        }
                      }
                    },
                    child: Obx(() {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accent, Colors.orange],
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black,
                              offset: const Offset(3, 3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          userController.isLoading.value ? "Saving..." : "Save",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            /// 🔥 TABS
            SizedBox(
              height: isTablet ? 40.h : 30.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: AppSize.w(12)),
                itemCount: tabs.length,
                itemBuilder: (context, index) {
                  final active = selectedTab == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTab = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 6.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20.w : 14.w,
                        vertical: isTablet ? 10.h : 5.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),

                        gradient: active
                            ? LinearGradient(
                                colors: [AppColors.accent, Colors.orange],
                              )
                            : null,

                        color: active ? null : AppColors.secondary,

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(3, 3),
                            blurRadius: 6,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.05),
                            offset: Offset(-3, -3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          tabs[index],
                          style: AppTextStyles.small.copyWith(
                            color: active
                                ? Colors.black
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 12.h),

            /// 🔥 TAB CONTENT (NO SCROLL BUG)
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: screens[selectedTab],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
