import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  double _searchRadius = 5;
  // int _selectedNavIndex = 1;
  int _selectedCategory = 0;

  LatLng currentLocation = const LatLng(28.6139, 77.2090);
  List<Marker> markers = [];

  final List<Map<String, dynamic>> categories = [
    {"label": "All", "icon": Icons.grid_view_rounded},
    {"label": "Crosspath", "icon": Icons.compare_arrows_rounded},
    {"label": "Free Tonight", "icon": Icons.nights_stay_rounded},
    {"label": "Nearby", "icon": Icons.near_me_rounded},
  ];

  final List<Map<String, dynamic>> dummyProfiles = [
    {
      "name": "Chirag",
      "distance": "0.0 km",
      "image": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
      "category": 3,
    },
    {
      "name": "Kapoor",
      "distance": "0.0 km",
      "image": "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d",
      "category": 1,
    },
    {
      "name": "Sajan",
      "distance": "0.3 km",
      "image": "https://images.unsplash.com/photo-1504593811423-6dd665756598",
      "category": 3,
    },
    {
      "name": "Riya",
      "distance": "1.2 km",
      "image": "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
      "category": 2,
    },
    {
      "name": "Aarav",
      "distance": "2.5 km",
      "image": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
      "category": 1,
    },
    {
      "name": "Ananya",
      "distance": "3.1 km",
      "image": "https://images.unsplash.com/photo-1544005313-94ddf0286df2",
      "category": 2,
    },
  ];

  List<Map<String, dynamic>> get filteredProfiles {
    if (_selectedCategory == 0) return dummyProfiles;
    return dummyProfiles
        .where((p) => p["category"] == _selectedCategory)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _sheetController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
      _updateMarker(currentLocation);
    });
    _mapController.move(currentLocation, 13);
  }

  void _updateMarker(LatLng point) {
    markers = [
      Marker(
        point: point,
        width: 60,
        height: 60,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ),
    ];
  }

  Future<void> _searchLocation() async {
    final address = _searchController.text.trim();

    if (address.isEmpty) return;

    try {
      final geocoder = geo.Geocoding();

      final List<geo.Location> locations = await geocoder.locationFromAddress(
        address,
      );

      if (locations.isEmpty) return;

      final loc = locations.first;

      final searched = LatLng(loc.latitude, loc.longitude);

      if (!mounted) return;

      setState(() {
        currentLocation = searched;
        _updateMarker(searched);
      });

      _mapController.move(searched, 13);
    } catch (e) {
      debugPrint('Location search error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ── MAP ──────────────────────────────────────────
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: currentLocation,
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.yourapp.nearby',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),

            // ── SEARCH BAR ───────────────────────────────────
            Positioned(
              top: 16,
              left: 14,
              right: 14,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (_) => _searchLocation(),
                        decoration: const InputDecoration(
                          hintText: "Search for places...",
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _getCurrentLocation,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.my_location, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),

            // ── BOTTOM SHEET ─────────────────────────────────
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.53, // ✅ half page
              minChildSize: 0.53, // ✅ half page se kam nahi jayega
              maxChildSize: 1.0,
              snap: true,
              snapSizes: const [0.60, 1.0], // ✅ half → full
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF555555),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                      // ── CATEGORY ROW ──────────────────────
                      _CategoryRow(
                        categories: categories,
                        selected: _selectedCategory,
                        sheetSize: _sheetController.isAttached
                            ? _sheetController.size
                            : 0.5,
                        onSelect: (i) => setState(() => _selectedCategory = i),
                      ),

                      const SizedBox(height: 8),

                      // ── SCROLLABLE CONTENT ────────────────
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              // Search Radius
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Search Radius",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white10,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            "${_searchRadius.toInt()} km",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 4,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 10,
                                        ),
                                      ),
                                      child: Slider(
                                        value: _searchRadius,
                                        min: 1,
                                        max: 150,
                                        activeColor: Colors.red,
                                        inactiveColor: Colors.white12,
                                        onChanged: (v) =>
                                            setState(() => _searchRadius = v),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Grid
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                itemCount: filteredProfiles.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 0.70,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                itemBuilder: (context, index) {
                                  final user = filteredProfiles[index];
                                  return Column(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                user["image"],
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                  width: 14,
                                                  height: 14,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color:
                                                            Colors.greenAccent,
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        user["name"],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            color: Colors.red,
                                            size: 13,
                                          ),
                                          Text(
                                            user["distance"],
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── BOTTOM NAV ───────────────────────────────────
            // Align(
            //   alignment: Alignment.bottomCenter,
            //   child: Container(
            //     margin: const EdgeInsets.only(bottom: 14),
            //     height: 70,
            //     width: MediaQuery.of(context).size.width * 0.88,
            //     decoration: BoxDecoration(
            //       color: const Color(0xFF111111),
            //       borderRadius: BorderRadius.circular(40),
            //       boxShadow: [
            //         BoxShadow(
            //           color: Colors.black.withOpacity(0.35),
            //           blurRadius: 15,
            //         )
            //       ],
            //     ),
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceAround,
            //       children: [
            //         _navIcon(Icons.home_rounded, 0),
            //         _navIcon(Icons.location_on_rounded, 1),
            //         _navIcon(Icons.person_rounded, 2),
            //         _navIcon(Icons.favorite_rounded, 3),
            //         _navIcon(Icons.work_rounded, 4),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // Widget _navIcon(IconData icon, int index) {
  //   final selected = _selectedNavIndex == index;
  //   return GestureDetector(
  //     onTap: () => setState(() => _selectedNavIndex = index),
  //     child: Container(
  //       width: 52,
  //       height: 52,
  //       decoration: BoxDecoration(
  //         color: selected ? Colors.amber : Colors.transparent,
  //         shape: BoxShape.circle,
  //         boxShadow: selected
  //             ? [
  //                 BoxShadow(
  //                   color: Colors.amber.withOpacity(0.5),
  //                   blurRadius: 15,
  //                 ),
  //               ]
  //             : [],
  //       ),
  //       child: Icon(
  //         icon,
  //         color: selected ? Colors.black : Colors.white70,
  //         size: 26,
  //       ),
  //     ),
  //   );
  // }
}

// ════════════════════════════════════════════════════════════════
// Category Row — sheetSize se turant labels dikhta hai
// ════════════════════════════════════════════════════════════════
class _CategoryRow extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final int selected;
  final double sheetSize;
  final ValueChanged<int> onSelect;

  const _CategoryRow({
    required this.categories,
    required this.selected,
    required this.sheetSize,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // 0.5 = collapsed (half), 0.52 se upar = user ne drag kiya
    final bool showLabels = sheetSize > 0.90; // ✅ updated threshold

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(), // 🔥 smooth drag fix
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          final bool isSelected = selected == i;

          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,

              // 🔥 FIX GAP (controlled spacing)
              margin: const EdgeInsets.only(right: 8),

              padding: EdgeInsets.symmetric(horizontal: 30.h, vertical: 10),

              decoration: BoxDecoration(
                color: isSelected ? Colors.red : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(30),
              ),

              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat["icon"] as IconData,
                    color: isSelected ? Colors.white : Colors.white60,
                    size: 20,
                  ),

                  const SizedBox(width: 6),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: showLabels
                        ? Text(
                            cat["label"] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white60,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          )
                        : const SizedBox.shrink(),
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
