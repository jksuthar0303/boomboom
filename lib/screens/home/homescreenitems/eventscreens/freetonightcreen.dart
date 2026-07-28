// freetonightscreen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';

import 'eventprofile.dart';

class FreeTonightScreen extends StatefulWidget {
  const FreeTonightScreen({super.key});

  @override
  State<FreeTonightScreen> createState() => _FreeTonightScreenState();
}

class _FreeTonightScreenState extends State<FreeTonightScreen> {
  String selectedCategory = "All";
  RangeValues _distanceRange = const RangeValues(0, 20);
  final Set<int> _likedIndexes = {};

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    bool isTablet = size.width > 600;

    final filteredPeople = selectedCategory == "All"
        ? people
        : people.where((e) => e.type == selectedCategory).toList();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 28 : 16,
        vertical: 12,
      ),
      child: Column(
        children: [
          /// CATEGORY CHIPS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                categoryChip(
                  title: "All",
                  selected: selectedCategory == "All",
                  onTap: () => setState(() => selectedCategory = "All"),
                ),
                categoryChip(
                  title: "🍽 Dinner",
                  selected: selectedCategory == "🍽 Dinner",
                  onTap: () => setState(() => selectedCategory = "🍽 Dinner"),
                ),
                categoryChip(
                  title: "🎉 Party",
                  selected: selectedCategory == "🎉 Party",
                  onTap: () => setState(() => selectedCategory = "🎉 Party"),
                ),
                categoryChip(
                  title: "💬 Chat, Meet-up",
                  selected: selectedCategory == "💬 Chat, Meet-up",
                  onTap: () =>
                      setState(() => selectedCategory = "💬 Chat, Meet-up"),
                ),
                categoryChip(
                  title: "Drinks Tonight",
                  selected: selectedCategory == "Drinks Tonight",
                  onTap: () =>
                      setState(() => selectedCategory = "Drinks Tonight"),
                ),
                categoryChip(
                  title: "Party Buddy",
                  selected: selectedCategory == "Party Buddy",
                  onTap: () => setState(() => selectedCategory = "Party Buddy"),
                ),
                categoryChip(
                  title: "Spontaneous Plans",
                  selected: selectedCategory == "Spontaneous Plans",
                  onTap: () =>
                      setState(() => selectedCategory = "Spontaneous Plans"),
                ),
                categoryChip(
                  title: "Night Out",
                  selected: selectedCategory == "Night Out",
                  onTap: () => setState(() => selectedCategory = "Night Out"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          /// DISTANCE RANGE SLIDER
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF11182B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.pink, size: 16),
                        SizedBox(width: 5),
                        Text(
                          "Distance",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${_distanceRange.start.toStringAsFixed(0)} km – ${_distanceRange.end.toStringAsFixed(0)} km",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.pinkAccent,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: Colors.pinkAccent,
                    overlayColor: Colors.pinkAccent.withValues(alpha: 0.2),
                    rangeThumbShape: const RoundRangeSliderThumbShape(
                      enabledThumbRadius: 11,
                    ),
                    showValueIndicator: ShowValueIndicator.onDrag,
                    valueIndicatorColor: Colors.pinkAccent,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                  child: RangeSlider(
                    values: _distanceRange,
                    min: 0,
                    max: 150,
                    labels: RangeLabels(
                      "${_distanceRange.start.toStringAsFixed(0)} km",
                      "${_distanceRange.end.toStringAsFixed(0)} km",
                    ),
                    onChanged: (v) => setState(() => _distanceRange = v),
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "0 km",
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    Text(
                      "150 km",
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          /// GRID
          Expanded(
            child: GridView.builder(
              scrollCacheExtent: ScrollCacheExtent.pixels(1000),
              itemCount: filteredPeople.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 3 : 2,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: isTablet ? 0.78 : 0.68,
              ),
              itemBuilder: (context, index) =>
                  personCard(filteredPeople[index], isTablet, index),
            ),
          ),
        ],
      ),
    );
  }

  Widget categoryChip({
    required String title,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFFF3DA1), Color(0xFFFF007A)],
                )
              : null,
          color: selected ? null : const Color(0xFF101726),
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  IconData getTypeIcon(String type) {
    switch (type) {
      case "🍽 Dinner":
        return Icons.restaurant_menu_rounded;

      case "🎉 Party":
        return Icons.celebration_rounded;

      case "💬 Chat, Meet-up":
        return Icons.forum_rounded;

      default:
        return Icons.local_activity_rounded;
    }
  }

  Widget personCard(PersonModel item, bool isTablet, int index) {
    return GestureDetector(
      onTap: () {
        Get.to(
          const ProfileDetailsScreen(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 350),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            /// IMAGE — optimized fast load
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: "${item.image}?w=800&q=90&fit=crop",
                fit: BoxFit.cover,
                memCacheWidth: 800,
                fadeInDuration: Duration.zero,

                placeholder: (context, url) => Container(
                  color: const Color(0xFF11182B),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.pinkAccent,
                      strokeWidth: 1.5,
                    ),
                  ),
                ),

                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFF1a1a2e),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white24,
                    size: 48,
                  ),
                ),
              ),
            ),

            /// GRADIENT OVERLAY
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.35, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.03),
                    Colors.black.withValues(alpha: 0.90),
                  ],
                ),
              ),
            ),

            /// SUBTLE BORDER
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
            ),

            /// TOP — ACTIVE + HEART
            Positioned(
              top: 6,
              left: 9,
              right: 9,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Container(
                  //   padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  //   decoration: BoxDecoration(
                  //     color: Colors.black.withOpacity(0.50),
                  //     borderRadius: BorderRadius.circular(20),
                  //   ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.r),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2216CA), Color(0xFFD8658F)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Container(
                      margin: EdgeInsets.all(1.5.w), // ✅ border thickness
                      height: 18.h, // ✅ inner height kam
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.type,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 9.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      if (_likedIndexes.contains(index)) {
                        _likedIndexes.remove(index);
                      } else {
                        _likedIndexes.add(index);
                      }
                    }),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        _likedIndexes.contains(index)
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        key: ValueKey(_likedIndexes.contains(index)),
                        color: _likedIndexes.contains(index)
                            ? Colors.red
                            : Colors.white,
                        size: 30,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// BOTTOM INFO
            Positioned(
              bottom: 8.h,
              left: 7.w,
              right: 7.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          "${item.name}, ${item.age}",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 17.sp : 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(Icons.verified, color: Colors.blue, size: 14.sp),
                      SizedBox(width: 2.w),
                      Text(
                        item.flag,
                        style: TextStyle(fontSize: isTablet ? 15.sp : 13.sp),
                      ),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      profileBadge("${item.flag} India", Icons.public),

                      SizedBox(height: 4.h),

                      Row(
                        children: [
                          profileBadge("50 km away", Icons.location_on),
                          SizedBox(width: 4.w),
                          profileBadge(item.lastSeen, Icons.access_time),
                        ],
                      ),
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

  Widget profileBadge(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8.sp, color: Colors.white70),
          SizedBox(width: 2.w),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class PersonModel {
  final String name;
  final int age;
  final String image;
  final String type;
  final String flag;
  final String height;
  final String lastSeen;

  PersonModel({
    required this.name,
    required this.age,
    required this.image,
    required this.type,
    required this.flag,
    required this.height,
    required this.lastSeen,
  });
}

List<PersonModel> people = [
  PersonModel(
    name: "Anaya",
    age: 24,
    flag: "🇮🇳",
    lastSeen: "55 sec ago",
    height: "5'4\"",
    image: "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
    type: "🍽 Dinner",
  ),
  PersonModel(
    name: "Riya",
    age: 23,
    flag: "🇮🇳",
    lastSeen: "55 sec ago",
    height: "5'3\"",
    image: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80",
    type: "💬 Chat, Meet-up",
  ),
  // ✅ Karan ki image fix — working URL
  PersonModel(
    name: "Karan",
    age: 26,
    flag: "🇮🇳",
    lastSeen: "55 sec ago",
    height: "5'11\"",
    image: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d",
    type: "🎉 Party",
  ),
  PersonModel(
    name: "Sneha",
    age: 22,
    flag: "🇮🇳",
    lastSeen: "55 sec ago",
    height: "5'5\"",
    image: "https://images.unsplash.com/photo-1517841905240-472988babdf9",
    type: "🎉 Party",
  ),
  PersonModel(
    name: "Arjun",
    age: 27,
    flag: "🇮🇳",
    lastSeen: "55 sec ago",
    height: "6'0\"",
    image: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d",
    type: "🍽 Dinner",
  ),
  PersonModel(
    name: "Megha",
    age: 25,
    flag: "🇮🇳",
    lastSeen: "55 sec ago",
    height: "5'4\"",
    image: "https://images.unsplash.com/photo-1488426862026-3ee34a7d66df",
    type: "💬 Chat, Meet-up",
  ),
  PersonModel(
    name: "Aarav",
    age: 28,
    flag: "🇮🇳",
    lastSeen: "55 sec ago",
    height: "5'10\"",
    image: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e",
    type: "🎉 Party",
  ),
  PersonModel(
    name: "Kiara",
    age: 21,
    flag: "🇮🇳",
    lastSeen: "55 sec ago",
    height: "5'6\"",
    image: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1",
    type: "🍽 Dinner",
  ),
  PersonModel(
    name: "Vivaan",
    age: 29,
    flag: "🇮🇳",
    lastSeen: "55 sec ago",
    height: "6'1\"",
    image: "https://images.unsplash.com/photo-1463453091185-61582044d556",
    type: "💬 Chat, Meet-up",
  ),
  PersonModel(
    name: "Tanya",
    age: 24,
    flag: "🇮🇳",
    lastSeen: "55 sec ago",
    height: "5'5\"",
    image: "https://images.unsplash.com/photo-1544005313-94ddf0286df2",
    type: "🎉 Party",
  ),
  PersonModel(
    name: "Rahul",
    age: 30,
    flag: "🇮🇳",
    lastSeen: "55 sec ago",
    height: "5'9\"",
    image: "https://images.unsplash.com/photo-1500048993953-d23a436266cf",
    type: "🍽 Dinner",
  ),
  PersonModel(
    name: "Ishita",
    age: 23,
    flag: "🇮🇳",
    lastSeen: "55 sec ago",
    height: "5'3\"",
    image: "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f",
    type: "💬 Chat, Meet-up",
  ),
  PersonModel(
    name: "Kabir",
    age: 27,
    flag: "🇮🇳",
    lastSeen: "55 sec ago",
    height: "5'11\"",
    image: "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7",
    type: "🎉 Party",
  ),
  PersonModel(
    name: "Sara",
    age: 22,
    flag: "🇮🇳",
    lastSeen: "55 sec ago",
    height: "5'4\"",
    image: "https://images.unsplash.com/photo-1520813792240-56fc4a3765a7",
    type: "🍽 Dinner",
  ),
  PersonModel(
    name: "Dev",
    age: 26,
    flag: "🇮🇳",
    lastSeen: "55 sec ago",
    height: "5'10\"",
    image: "https://images.unsplash.com/photo-1480455624313-e29b44bbfde1",
    type: "💬 Chat, Meet-up",
  ),
];
