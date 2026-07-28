import 'dart:io';
import 'dart:convert';
import 'package:boomboom/authentication/registerscreen/gender.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:boomboom/backend/secure_storage.dart';
import 'package:get/get.dart';
import '../../../controller/user_controller.dart';

import '../../../constant/appsize.dart';
import '../../../constant/apptextstyle.dart';
import '../../../constant/colors.dart';
import '../../../widget/outlinedbutton.dart';

class UpdatePersonInfoUI extends StatefulWidget {
  const UpdatePersonInfoUI({super.key});

  @override
  State<UpdatePersonInfoUI> createState() => _UpdatePersonInfoUIState();
}

class _UpdatePersonInfoUIState extends State<UpdatePersonInfoUI> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final UserController userController = Get.put(UserController());

  @override
  void initState() {
    super.initState();
    _loadProfileData();
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
              nameController.text = data["FullName"] ?? "";
              emailController.text = data["EmailAddress"] ?? "";
              userController.fullName.value = nameController.text;
              userController.emailAddress.value = emailController.text;
              final String dob = data["Dob"] ?? "";
              if (dob.isNotEmpty) {
                userController.dob.value = dob;
                selectedDate = DateTime.tryParse(dob);
                if (selectedDate != null) {
                  final now = DateTime.now();
                  age = now.year - selectedDate!.year;
                  if (now.month < selectedDate!.month || (now.month == selectedDate!.month && now.day < selectedDate!.day)) {
                    age--;
                  }
                }
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading profile in UpdatePersonInfoUI: $e");
    }
  }

  // String selectedGender = "Male";
  // String lookingFor = "Drink";

  DateTime? selectedDate;
  int age = 0;

  File? profileImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> pickFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        profileImage = File(pickedFile.path);
      });
    }
  }

  void openImagePickerSheet() {
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
              Text("Select Image", style: AppTextStyles.subHeading),

              SizedBox(height: AppSize.h(20)),

              _pickerOption(
                icon: Icons.photo_library,
                title: "Gallery",
                onTap: () {
                  Navigator.pop(context);
                  pickFromGallery();
                },
              ),

              SizedBox(height: AppSize.h(10)),

              _pickerOption(
                icon: Icons.camera_alt,
                title: "Camera",
                onTap: () {
                  Navigator.pop(context);
                  pickFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void pickDateBottomSheet() {
    int selectedDay = 1;
    int selectedMonth = 1;
    int selectedYear = 2000;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: EdgeInsets.all(AppSize.w(16)),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Select Date of Birth", style: AppTextStyles.subHeading),

                  SizedBox(height: AppSize.h(20)),

                  Row(
                    children: [
                      Expanded(
                        child: _pickerUI(
                          start: 1,
                          end: 31,
                          selectedValue: selectedDay,
                          onChanged: (v) =>
                              setStateSheet(() => selectedDay = v),
                        ),
                      ),

                      Expanded(
                        child: _pickerUI(
                          start: 1,
                          end: 12,
                          selectedValue: selectedMonth,
                          onChanged: (v) =>
                              setStateSheet(() => selectedMonth = v),
                        ),
                      ),

                      Expanded(
                        child: _pickerUI(
                          start: 1950,
                          end: DateTime.now().year,
                          selectedValue: selectedYear,
                          onChanged: (v) =>
                              setStateSheet(() => selectedYear = v),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppSize.h(20)),

                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedDate = DateTime(
                          selectedYear,
                          selectedMonth,
                          selectedDay,
                        );

                        age = DateTime.now().year - selectedYear;
                        userController.dob.value = selectedDate!.toIso8601String().split('T').first;
                      });

                      Navigator.pop(context);
                    },
                    child: const Text("Confirm"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.primary,

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: EdgeInsets.all(AppSize.w(20)),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              SizedBox(height: AppSize.h(30)),

              /// IMAGE
              Center(
                child: GestureDetector(
                  onTap: openImagePickerSheet,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.secondary,
                    backgroundImage: profileImage != null
                        ? FileImage(profileImage!)
                        : null,
                    child: profileImage == null
                        ? Icon(Icons.person, size: 40.sp)
                        : null,
                  ),
                ),
              ),

              SizedBox(height: AppSize.h(25)),

              /// NAME
              _label("Name"),

              SizedBox(height: 8.h),

              _neuField(
                child: TextField(
                  controller: nameController,
                  onChanged: (v) {
                    userController.fullName.value = v;
                  },
                  style: AppTextStyles.body.copyWith(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Enter your name",
                    border: InputBorder.none,
                  ),
                ),
              ),

              SizedBox(height: AppSize.h(20)),

              /// EMAIL
              _label("Email"),

              SizedBox(height: 8.h),

              _neuField(
                child: TextField(
                  controller: emailController,
                  onChanged: (v) {
                    userController.emailAddress.value = v;
                  },
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.body.copyWith(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Enter your email",
                    border: InputBorder.none,
                  ),
                ),
              ),

              SizedBox(height: AppSize.h(20)),

              // /// GENDER
              // _label("Gender"),
              //
              // SizedBox(height: 8.h),
              //
              // _dropdownField(
              //   value: selectedGender,
              //   items: const [
              //     "Male",
              //     "Female",
              //     "Other",
              //   ],
              //   onChanged: (v) {
              //     setState(() {
              //       selectedGender = v!;
              //     });
              //   },
              // ),
              //
              // SizedBox(height: AppSize.h(20)),
              //
              // /// LOOKING FOR
              // _label("What are you looking for"),
              //
              // SizedBox(height: 8.h),
              //
              // _dropdownField(
              //   value: lookingFor,
              //   items: const [
              //     "Drink",
              //     "Night Party",
              //     "Friendship",
              //     "Relationship",
              //   ],
              //   onChanged: (v) {
              //     setState(() {
              //       lookingFor = v!;
              //     });
              //   },
              // ),
              //
              // SizedBox(height: AppSize.h(20)),

              /// DOB
              _label("Date of Birth"),

              SizedBox(height: 8.h),

              GestureDetector(
                onTap: pickDateBottomSheet,
                child: _neuField(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDate == null
                            ? "Select date"
                            : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                        style: AppTextStyles.body,
                      ),

                      const Icon(Icons.calendar_month, color: Colors.white),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppSize.h(20)),

              if (selectedDate != null)
                Text("$age years old", style: AppTextStyles.small),

              SizedBox(height: AppSize.h(40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: AppTextStyles.body.copyWith(color: Colors.white));
  }

  Widget _neuField({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF9B59B6), Color(0xFF3498DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(1.5),

      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        height: 55.h,
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(11.r),
        ),
        child: Center(child: child),
      ),
    );
  }

  // Widget _dropdownField({
  //   required String value,
  //   required List<String> items,
  //   required Function(String?) onChanged,
  // }) {

  //   return Container(
  //     padding: EdgeInsets.symmetric(horizontal: 15.w),

  //     height: 55.h,

  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(12.r),
  //       color: AppColors.secondary,
  //     ),

  //     child: DropdownButtonHideUnderline(
  //       child: DropdownButton<String>(

  //         value: value,

  //         dropdownColor: AppColors.secondary,

  //         isExpanded: true,

  //         style: const TextStyle(color: Colors.white),

  //         items: items.map((e) {
  //           return DropdownMenuItem(
  //             value: e,
  //             child: Text(
  //               e,
  //               style: const TextStyle(
  //                 color: Colors.white,
  //               ),
  //             ),
  //           );
  //         }).toList(),

  //         onChanged: onChanged,
  //       ),
  //     ),
  //   );
  // }

  Widget _pickerUI({
    required int start,
    required int end,
    required int selectedValue,
    required Function(int) onChanged,
  }) {
    return SizedBox(
      height: 120,

      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,

        onSelectedItemChanged: (i) => onChanged(start + i),

        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            final value = start + index;

            return Center(
              child: Text(
                value.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          },

          childCount: end - start + 1,
        ),
      ),
    );
  }

  Widget _pickerOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),

      title: Text(title, style: const TextStyle(color: Colors.white)),

      onTap: onTap,
    );
  }
}
