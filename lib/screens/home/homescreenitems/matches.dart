import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constant/appsize.dart';


class ProfileCardList extends StatelessWidget {
  ProfileCardList({super.key});

  final List<Map<String, String>> users = [
    {
      "name": "Indigo",
      "age": "25",
      "image":
      "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e"
    },
    {
      "name": "Natalya",
      "age": "24",
      "image":
      "https://images.unsplash.com/photo-1544005313-94ddf0286df2"
    },
    {
      "name": "Sofia",
      "age": "23",
      "image":
      "https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d"
    },
    {
      "name": "Ava",
      "age": "26",
      "image":
      "https://images.unsplash.com/photo-1494790108377-be9c29b29330"
    },
    {
      "name": "Mia",
      "age": "22",
      "image":
      "https://images.unsplash.com/photo-1517841905240-472988babdf9"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSize.h(200),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: users.length + 1, // 👈 +1 for See All
        padding: EdgeInsets.symmetric(horizontal: AppSize.w(12)),
        itemBuilder: (context, index) {
          /// 🔥 LAST ITEM (SEE ALL)
          if (index == users.length) {
            return Container(
              width: AppSize.w(120),
              margin: EdgeInsets.only(right: AppSize.w(12)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),

                /// 🔥 GOLD BORDER
                border: Border.all(color: Colors.amber, width: 2),

                /// 🔥 NEUMORPHISM SHADOW
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    offset: const Offset(-2, -2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_forward_ios,
                        color: Colors.amber, size: 20.sp),
                    SizedBox(height: AppSize.h(6)),
                    Text(
                      "See All",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          /// 🔥 NORMAL USER CARD
          final user = users[index];

          return Container(
            width: AppSize.w(150),
            margin: EdgeInsets.only(right: AppSize.w(12)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              image: DecorationImage(
                image: NetworkImage(user["image"]!),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: EdgeInsets.all(AppSize.w(10)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// ❤️ FAVORITE ICON
                  Align(
                    alignment: Alignment.topLeft,
                    child: Icon(Icons.favorite_border,
                        color: Colors.white, size: 20.sp),
                  ),

                  /// 🔥 NAME + AGE
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      "${user["name"]}, ${user["age"]}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}