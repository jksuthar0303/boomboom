import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:boomboom/backend/registerservice.dart';
import 'package:boomboom/backend/home_service.dart';
import 'package:boomboom/backend/secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:xml/xml.dart' as xml;
import '../constant/appsize.dart';
import '../constant/apptextstyle.dart';
import '../constant/colors.dart';
import 'messagedetail.dart';

// ────────────────────────────────────────
//  Helpers
// ────────────────────────────────────────
String countryFlag(String isoCode) => isoCode
    .toUpperCase()
    .characters
    .map((c) => String.fromCharCode(c.codeUnitAt(0) + 127397))
    .join();

const Map<String, String> _cityCountryCode = {
  'New Delhi': 'IN',
  'Mumbai': 'IN',
  'Bangalore': 'IN',
  'Hyderabad': 'IN',
  'Chennai': 'IN',
  'Kolkata': 'IN',
  'London': 'GB',
  'New York': 'US',
  'Paris': 'FR',
  'Dubai': 'AE',
  'Singapore': 'SG',
  'Tokyo': 'JP',
  'Sydney': 'AU',
  'Toronto': 'CA',
};

String flagForCity(String city) {
  for (final e in _cityCountryCode.entries) {
    if (city.contains(e.key)) return countryFlag(e.value);
  }
  return '🌍';
}

// ────────────────────────────────────────
//  Models
// ────────────────────────────────────────
enum MediaType { image, video }

class MediaItem {
  final MediaType type;
  final String url;
  final File? localFile;
  final Uint8List? bytes;

  const MediaItem({
    required this.type,
    this.url = '',
    this.localFile,
    this.bytes,
  });

  bool get isLocal => localFile != null;
  bool get isBytes => bytes != null;
}

class ProfileModel {
  final String name,
      age,
      job,
      city,
      distance,
      height,
      lookingFor,
      gender,
      nature,
      about,
      seenAgo;
  final List<String> interests, lifestyle;
  final List<MediaItem> media;
  final int completionPercent;
  final String? telegramUsername;

  const ProfileModel({
    required this.name,
    required this.age,
    required this.job,
    required this.city,
    required this.distance,
    required this.height,
    required this.lookingFor,
    required this.gender,
    required this.nature,
    required this.about,
    required this.interests,
    required this.lifestyle,
    required this.media,
    this.completionPercent = 72,
    this.seenAgo = '5 min ago',
    this.telegramUsername,
  });
}

final List<ProfileModel> sampleProfiles = [
  ProfileModel(
    name: 'Taniya Agarwal',
    age: '24',
    job: 'Fashion Designer',
    city: 'New Delhi, India',
    distance: '3.2 km',
    height: '1.67 m',
    lookingFor: 'Long Term',
    gender: 'Female',
    nature: 'Extrovert',
    seenAgo: '5 min ago',
    telegramUsername: 'taniya_boom',
    about:
        'Passionate about creating meaningful connections and exploring new places. '
        'Love deep conversations, good coffee, and spontaneous adventures.',
    interests: [
      '✈️ Travel',
      '☕ Coffee',
      '🎵 Music',
      '📚 Reading',
      '📸 Photography',
      '💪 Fitness',
    ],
    lifestyle: ['🍸 Social Drinker', '🚭 Non Smoker', '🏋️ Gym Freak'],
    completionPercent: 85,
    media: [
      MediaItem(
        type: MediaType.image,
        url:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800',
      ),
      MediaItem(
        type: MediaType.image,
        url:
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800',
      ),
      MediaItem(
        type: MediaType.image,
        url:
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800',
      ),
    ],
  ),
  ProfileModel(
    name: 'Kiara Sharma',
    age: '22',
    job: 'UX Designer at Zomato',
    city: 'Mumbai, India',
    distance: '2.4 km',
    height: '1.63 m',
    lookingFor: 'Coffee Date',
    gender: 'Female',
    nature: 'Extrovert',
    seenAgo: '2 min ago',
    telegramUsername: 'kiara_zomato',
    about:
        'Coffee lover & travel addict. Always looking for the next adventure. '
        'Big fan of indie music and rooftop sunsets.',
    interests: [
      '☕ Coffee',
      '✈️ Travel',
      '🎨 Design',
      '🎵 Music',
      '📸 Photography',
    ],
    lifestyle: ['🚭 Non Smoker', '🌅 Morning Person', '🧘 Yoga'],
    completionPercent: 90,
    media: [
      MediaItem(
        type: MediaType.image,
        url:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800',
      ),
      MediaItem(
        type: MediaType.image,
        url:
            'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800',
      ),
      MediaItem(
        type: MediaType.image,
        url:
            'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=800',
      ),
    ],
  ),
];

// ════════════════════════════════════════════════════
//  FULLSCREEN GALLERY
// ════════════════════════════════════════════════════
class FullscreenGallery extends StatefulWidget {
  final List<MediaItem> media;
  final int initialIndex;

  const FullscreenGallery({
    super.key,
    required this.media,
    required this.initialIndex,
  });

  @override
  State<FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<FullscreenGallery> {
  late final PageController _pageCtrl;
  late int _current;
  final Map<int, VideoPlayerController> _videoCtrl = {};
  final Map<int, TransformationController> _transformCtrl = {};

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
    _initVideoAt(_current);
  }

  TransformationController _getTC(int idx) =>
      _transformCtrl.putIfAbsent(idx, () => TransformationController());

  void _initVideoAt(int idx) {
    final m = widget.media[idx];
    if (m.type != MediaType.video || _videoCtrl.containsKey(idx)) return;
    final ctrl = m.isLocal
        ? VideoPlayerController.file(m.localFile!)
        : VideoPlayerController.networkUrl(Uri.parse(m.url));
    _videoCtrl[idx] = ctrl;
    ctrl.initialize().then((_) {
      if (mounted) {
        setState(() {});
        ctrl.play();
        ctrl.setLooping(true);
      }
    });
  }

  void _pauseAll() {
    for (final c in _videoCtrl.values) {
      if (c.value.isPlaying) c.pause();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in _videoCtrl.values) {
      c.dispose();
    }
    for (final c in _transformCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isZoomed(int idx) {
    if (!_transformCtrl.containsKey(idx)) return false;
    return _transformCtrl[idx]!.value.getMaxScaleOnAxis() > 1.05;
  }

  void _onDoubleTap(int idx, Offset pos) {
    final tc = _getTC(idx);
    if (tc.value.getMaxScaleOnAxis() > 1.05) {
      tc.value = Matrix4.identity();
    } else {
      tc.value = Matrix4.identity()
        ..translate(-pos.dx * 1.5, -pos.dy * 1.5)
        ..scale(2.5);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.media.length,
            physics: _isZoomed(_current)
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            onPageChanged: (i) {
              _pauseAll();
              setState(() => _current = i);
              _initVideoAt(i);
              if (widget.media[i].type == MediaType.video) {
                _videoCtrl[i]?.play();
              }
            },
            itemBuilder: (_, i) {
              final m = widget.media[i];
              if (m.type == MediaType.video) {
                return _VideoPage(ctrl: _videoCtrl[i]);
              }
              return GestureDetector(
                onDoubleTapDown: (d) => _onDoubleTap(i, d.localPosition),
                onDoubleTap: () {},
                child: InteractiveViewer(
                  transformationController: _getTC(i),
                  minScale: 0.8,
                  maxScale: 5.0,
                  panEnabled: true,
                  clipBehavior: Clip.none,
                  onInteractionUpdate: (_) => setState(() {}),
                  child: Center(
                    child: m.isBytes
                        ? Image.memory(m.bytes!, fit: BoxFit.contain)
                        : (m.isLocal
                              ? Image.file(m.localFile!, fit: BoxFit.contain)
                              : CachedNetworkImage(
                                  imageUrl: m.url,
                                  fit: BoxFit.contain,
                                  placeholder: (_, _) => const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                  errorWidget: (_, _, _) => const Icon(
                                    Icons.broken_image,
                                    color: Colors.white54,
                                    size: 60,
                                  ),
                                )),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 28,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.media.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _current ? 18 : 6,
                      height: 4,
                      decoration: BoxDecoration(
                        color: i == _current
                            ? AppColors.accent
                            : Colors.white38,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_current + 1} / ${widget.media.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          if (_isZoomed(_current))
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  _getTC(_current).value = Matrix4.identity();
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.zoom_out_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          if (widget.media[_current].type == MediaType.video &&
              _videoCtrl[_current] != null)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    final c = _videoCtrl[_current]!;
                    setState(() {
                      c.value.isPlaying ? c.pause() : c.play();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _videoCtrl[_current]!.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VideoPage extends StatelessWidget {
  final VideoPlayerController? ctrl;

  const _VideoPage({this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl == null || !ctrl!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: ctrl!.value.aspectRatio,
        child: VideoPlayer(ctrl!),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
//  BOOM PROFILE SCREEN
// ════════════════════════════════════════════════════
class BoomProfileScreen extends StatefulWidget {
  final bool showStar;
  final bool showMore;
  final bool showTelegram;
  final bool isOwnProfile;
  final String? userEmail;
  final Map<String, dynamic>? initialUserData;

  const BoomProfileScreen({
    super.key,
    this.showStar = true,
    this.showMore = true,
    this.showTelegram = true,
    this.isOwnProfile = false,
    this.userEmail,
    this.initialUserData,
  });

  @override
  State<BoomProfileScreen> createState() => _BoomProfileScreenState();
}

class _BoomProfileScreenState extends State<BoomProfileScreen>
    with SingleTickerProviderStateMixin {
  double _dragX = 0, _dragY = 0;
  bool _isSwiping = false;
  int _currentIndex = 0;
  int _mediaIndex = 0;
  late bool showStar;
  late bool showMore;
  late bool showTelegram;
  final Set<int> _favourites = {};

  late AnimationController _snapCtrl;
  late Animation<Offset> _snapAnim;
  final Map<int, VideoPlayerController> _videoControllers = {};

  final ScrollController _scrollCtrl = ScrollController();

  ProfileModel? ownProfile;
  ProfileModel? otherProfile;
  List<ProfileModel> _liveProfiles = [];
  List<String?> _liveProfileEmails = [];
  bool _isLoadingOtherProfile = false;
  bool _isLoadingLiveFeed = true;
  bool _profileNotFound = false;

  ProfileModel get _profile {
    if (widget.isOwnProfile && ownProfile != null) {
      return ownProfile!;
    }
    if (otherProfile != null) {
      return otherProfile!;
    }
    if (_liveProfiles.isNotEmpty) {
      return _liveProfiles[_currentIndex % _liveProfiles.length];
    }
    return sampleProfiles[_currentIndex % sampleProfiles.length];
  }

  bool get _isFavourited {
    final int len = _liveProfiles.isNotEmpty
        ? _liveProfiles.length
        : sampleProfiles.length;
    return _favourites.contains(_currentIndex % len);
  }

  int _calculateAge(String dobStr) {
    try {
      DateTime dob = DateTime.parse(dobStr);
      DateTime now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 25; // fallback
    }
  }

  Future<void> _loadLiveFeedProfiles() async {
    if (!mounted) return;
    setState(() => _isLoadingLiveFeed = true);

    try {
      final String myEmail = await SecureStorage().getUserEmail() ?? "";
      final response = await HomeService().showAllExceptMe(
        myEmail: myEmail.trim(),
      );

      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        final res = doc.findAllElements('ShowAllExceptMeResult');
        if (res.isNotEmpty) {
          final Map<String, dynamic> jsonResult = jsonDecode(
            res.first.innerText,
          );
          if (jsonResult["Status"] == 1 && jsonResult["Data"] is List) {
            final List rawList = jsonResult["Data"];
            final List<ProfileModel> parsedList = [];
            final List<String?> profileEmails = [];

            for (var item in rawList) {
              if (item is Map) {
                final p = _buildProfileFromMap(Map<String, dynamic>.from(item));
                if (p != null) {
                  parsedList.add(p);
                  profileEmails.add(
                    (item["EmailAddress"] ?? item["email"] ??
                            item["ActionEmail"])
                        ?.toString(),
                  );
                }
              }
            }

            if (mounted && parsedList.isNotEmpty) {
              setState(() {
                _liveProfiles = parsedList;
                _liveProfileEmails = profileEmails;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("[BoomProfileScreen] Error fetching ShowAllExceptMe: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingLiveFeed = false);
      }
    }
  }

  Future<void> _loadOtherUserProfile(String email) async {
    if (email.isEmpty) return;
    _profileNotFound = false;
    if (!widget.isOwnProfile) {
      _recordProfileView(email);
    }
    setState(() => _isLoadingOtherProfile = true);

    try {
      final response = await RegisterService().showCompleteProfile(
        email: email.trim(),
      );
      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        final res = doc.findAllElements('ShowCompleteProfileResult');
        if (res.isNotEmpty) {
          final Map<String, dynamic> jsonResult = jsonDecode(
            res.first.innerText,
          );
          if (jsonResult["Status"] != 1) {
            if (mounted) {
              setState(() {
                _profileNotFound = true;
                _isLoadingOtherProfile = false;
                otherProfile = null;
              });
            }
            return;
          }
          if (jsonResult["Status"] == 1) {
            Map<String, dynamic>? profileData;
            List<dynamic>? rawInterests;
            List<dynamic>? rawMedia;
            List<dynamic>? rawLifestyle;

            if (jsonResult["ResultSets"] is List &&
                (jsonResult["ResultSets"] as List).isNotEmpty) {
              final resultSets = jsonResult["ResultSets"] as List;
              for (var rs in resultSets) {
                if (rs is List && rs.isNotEmpty) {
                  final firstItem = rs.first;
                  if (firstItem is Map) {
                    if (firstItem.containsKey("FullName") ||
                        firstItem.containsKey("Dob") ||
                        firstItem.containsKey("BIO")) {
                      profileData = Map<String, dynamic>.from(firstItem);
                    } else if (firstItem.containsKey("Interest") ||
                        firstItem.containsKey("InterestName")) {
                      rawInterests = rs;
                    } else if (firstItem.containsKey("Media") ||
                        firstItem.containsKey("Type")) {
                      rawMedia = rs;
                    } else if (firstItem.containsKey("LifeStyle") ||
                        firstItem.containsKey("Lifestyle")) {
                      rawLifestyle = rs;
                    }
                  }
                }
              }
            } else if (jsonResult["Data"] is List &&
                (jsonResult["Data"] as List).isNotEmpty) {
              profileData = Map<String, dynamic>.from(jsonResult["Data"].first);
            }

            profileData ??= widget.initialUserData;

            if (profileData != null) {
              _parseAndSetOtherProfile(
                profileData,
                rawInterests,
                rawMedia,
                rawLifestyle,
              );
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("[BoomProfileScreen] Error fetching ShowCompleteProfile: $e");
    } finally {
      if (mounted) {
        if (!_profileNotFound &&
            otherProfile == null &&
            widget.initialUserData != null) {
          _parseAndSetOtherProfile(widget.initialUserData!, null, null, null);
        }
        setState(() => _isLoadingOtherProfile = false);
      }
    }
  }

  Future<void> _recordProfileView(String actionEmail) async {
    try {
      final myEmail = await SecureStorage().getUserEmail() ?? '';
      if (myEmail.trim().isEmpty || actionEmail.trim().isEmpty) return;
      await HomeService().favoriteLikeViewInsert(
        myEmail: myEmail.trim(),
        actionEmail: actionEmail.trim(),
        action: 'view',
      );
    } catch (e) {
      debugPrint('[BoomProfileScreen] Error recording profile view: $e');
    }
  }

  ProfileModel? _buildProfileFromMap(
    Map<String, dynamic> data, [
    List<dynamic>? rawInterests,
    List<dynamic>? rawMedia,
    List<dynamic>? rawLifestyle,
  ]) {
    try {
      final String name = (data["FullName"] ?? data["name"] ?? "User")
          .toString();
      final String dob = (data["Dob"] ?? data["dob"] ?? "").toString();
      final String calculatedAge = dob.isNotEmpty
          ? _calculateAge(dob).toString()
          : (data["age"] ?? "24").toString();
      final String bio = (data["BIO"] ?? data["bio"] ?? data["Bio"] ?? "")
          .toString()
          .trim();
      final String job =
          (data["Occupation"] ?? data["occupation"] ?? "Not specified")
              .toString();
      final String height = (data["Height"] ?? data["height"] ?? "165 cm")
          .toString();
      final String lookingFor =
          (data["Lookingfor"] ?? data["lookingFor"] ?? "Serious Love")
              .toString();
      final String gender = (data["Gender"] ?? data["gender"] ?? "").toString();
      final String orientation =
          (data["Orientation"] ?? data["orientation"] ?? "").toString();
      final String city =
          (data["City"] ?? data["city"] ?? data["Country"] ?? "India")
              .toString();
      final String distance = (data["Distance"] ?? data["distance"] ?? "1.2 km")
          .toString();

      final List<MediaItem> mediaItems = [];
      void addMediaItem(dynamic val) {
        if (val == null) return;
        final String str = val.toString().trim();
        if (str.isEmpty ||
            str.toLowerCase() == "null" ||
            str.toLowerCase() == "image" ||
            str.toLowerCase() == "video") {
          return;
        }

        if (str.startsWith("http://") || str.startsWith("https://")) {
          mediaItems.add(MediaItem(type: MediaType.image, url: str));
        } else if (str.startsWith("/") &&
            !str.startsWith("/9j/") &&
            str.length < 200) {
          mediaItems.add(
            MediaItem(
              type: MediaType.image,
              url: "https://boomboomdate.com$str",
            ),
          );
        } else if (str.length > 50) {
          try {
            final String cleanB64 = str.contains(",")
                ? str.split(",").last.trim()
                : str.trim();
            final bytes = base64Decode(cleanB64);
            mediaItems.add(MediaItem(type: MediaType.image, bytes: bytes));
          } catch (_) {}
        }
      }

      dynamic mediaSource =
          rawMedia ??
          data["Media"] ??
          data["Photos"] ??
          data["Photo"] ??
          data["img"];
      if (mediaSource != null) {
        if (mediaSource is List) {
          for (var m in mediaSource) {
            if (m is String) {
              addMediaItem(m);
            } else if (m is Map) {
              final val = m["Media"] ?? m["Url"] ?? m["url"] ?? m["media"];
              addMediaItem(val);
            }
          }
        } else if (mediaSource is String) {
          addMediaItem(mediaSource);
        }
      }

      // ── DEDUPLICATE & SANITIZE LIFESTYLE ──
      String cleanTag(String input) {
        return input.replaceAll(RegExp(r'\?+'), '').trim();
      }

      final Map<String, String> lifestyleMap = {};
      if (rawLifestyle != null) {
        for (var l in rawLifestyle) {
          String str = "";
          if (l is Map) {
            str = (l["LifeStyle"] ?? l["Lifestyle"] ?? "").toString().trim();
          } else if (l is String) {
            str = l.trim();
          }
          if (str.isNotEmpty) {
            str = cleanTag(str);
            if (str.isNotEmpty) {
              final key = str.contains(":")
                  ? str.split(":").first.trim().toLowerCase()
                  : str.toLowerCase();
              lifestyleMap[key] = str;
            }
          }
        }
      }

      if (data["Height"] != null &&
          data["Height"].toString().trim().isNotEmpty) {
        lifestyleMap["height"] =
            "Height: ${cleanTag(data["Height"].toString())}";
      }
      if (data["BodyType"] != null &&
          data["BodyType"].toString().trim().isNotEmpty) {
        lifestyleMap["bodytype"] =
            "BodyType: ${cleanTag(data["BodyType"].toString())}";
      }
      if (data["Workout"] != null &&
          data["Workout"].toString().trim().isNotEmpty) {
        lifestyleMap["workout"] =
            "Workout: ${cleanTag(data["Workout"].toString())}";
      }
      if (data["DrinkingHabits"] != null &&
          data["DrinkingHabits"].toString().trim().isNotEmpty) {
        lifestyleMap["drinking"] =
            "Drinking: ${cleanTag(data["DrinkingHabits"].toString())}";
      }

      final List<String> lifestyleList = lifestyleMap.values
          .map((s) => cleanTag(s))
          .where((s) => s.isNotEmpty)
          .toList();

      // ── DEDUPLICATE & SANITIZE INTERESTS ──
      final Set<String> interestsSet = {};
      if (rawInterests != null) {
        for (var i in rawInterests) {
          if (i is Map) {
            final iname = i["Interest"] ?? i["InterestName"] ?? i["Name"];
            if (iname != null && iname.toString().trim().isNotEmpty) {
              final c = cleanTag(iname.toString());
              if (c.isNotEmpty) interestsSet.add(c);
            }
          } else if (i is String && i.trim().isNotEmpty) {
            final c = cleanTag(i);
            if (c.isNotEmpty) interestsSet.add(c);
          }
        }
      } else if (data["Interests"] is List) {
        for (var i in data["Interests"]) {
          if (i != null && i.toString().trim().isNotEmpty) {
            final c = cleanTag(i.toString());
            if (c.isNotEmpty) interestsSet.add(c);
          }
        }
      }
      final List<String> interestsList = interestsSet.toList();

      return ProfileModel(
        name: name,
        age: calculatedAge,
        job: job,
        city: city,
        distance: distance,
        height: height,
        lookingFor: lookingFor,
        gender: gender,
        nature: orientation,
        about: bio.isNotEmpty ? bio : "No bio added yet.",
        interests: interestsList,
        lifestyle: lifestyleList,
        media: mediaItems,
      );
    } catch (e) {
      debugPrint("[BoomProfileScreen] Error building profile model: $e");
      return null;
    }
  }

  void _parseAndSetOtherProfile(
    Map<String, dynamic> data, [
    List<dynamic>? rawInterests,
    List<dynamic>? rawMedia,
    List<dynamic>? rawLifestyle,
  ]) {
    final p = _buildProfileFromMap(data, rawInterests, rawMedia, rawLifestyle);
    if (p != null && mounted) {
      setState(() {
        otherProfile = p;
        if (widget.isOwnProfile) {
          ownProfile = p;
        }
      });
    }
  }

  Future<void> _loadOwnProfile() async {
    if (!mounted) return;

    try {
      final email = await SecureStorage().getUserEmail();
      if (email != null && email.isNotEmpty) {
        await _loadOtherUserProfile(email);
        return;
      }
    } catch (e) {
      debugPrint("Error loading own profile via ShowCompleteProfile: $e");
    }

    try {
      final jsonStr = await SecureStorage().getProfileJson();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        _parseProfileJson(jsonStr);
      }
    } catch (e) {
      debugPrint("Error loading profile cache: $e");
    }
  }

  void _parseProfileJson(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      final List? dataList = decoded["Data"];
      if (dataList != null && dataList.isNotEmpty) {
        final data = dataList.first;

        final String name = data["FullName"] ?? "Unknown";
        final String dob = data["Dob"] ?? "";
        final String calculatedAge = dob.isNotEmpty
            ? _calculateAge(dob).toString()
            : "25";
        final String bio = data["BIO"] ?? "";
        final String job = data["Occupation"] ?? "Not specified";
        final String height = data["Height"] ?? "";
        final String lookingFor = data["Lookingfor"] ?? "";
        final String gender = data["Gender"] ?? "";
        final String orientation = data["Orientation"] ?? "";
        final String location = (data["Lat"] != null && data["Lon"] != null)
            ? "Active Position"
            : "Unknown";

        final List<MediaItem> mediaItems = [];
        dynamic rawMedia =
            data["Media"] ??
            data["Photos"] ??
            data["Photo"] ??
            data["ProfilePic"] ??
            data["Images"];
        if (rawMedia != null) {
          if (rawMedia is List) {
            for (var m in rawMedia) {
              if (m is String && m.isNotEmpty) {
                mediaItems.add(MediaItem(type: MediaType.image, url: m));
              } else if (m is Map) {
                final url = m["Url"] ?? m["url"] ?? m["Media"] ?? m["media"];
                if (url != null && url.isNotEmpty) {
                  mediaItems.add(MediaItem(type: MediaType.image, url: url));
                }
              }
            }
          } else if (rawMedia is String && rawMedia.isNotEmpty) {
            final urls = rawMedia.split(",");
            for (var u in urls) {
              if (u.trim().isNotEmpty) {
                mediaItems.add(MediaItem(type: MediaType.image, url: u.trim()));
              }
            }
          }
        }

        final List<String> lifestyleList = [];
        if (data["DrinkingHabits"] != null &&
            data["DrinkingHabits"].toString().trim().isNotEmpty) {
          lifestyleList.add("Drinking: ${data["DrinkingHabits"]}");
        }
        if (data["Workout"] != null &&
            data["Workout"].toString().trim().isNotEmpty) {
          lifestyleList.add("Workout: ${data["Workout"]}");
        }
        if (data["BodyType"] != null &&
            data["BodyType"].toString().trim().isNotEmpty) {
          lifestyleList.add("Body Type: ${data["BodyType"]}");
        }

        if (mounted) {
          setState(() {
            ownProfile = ProfileModel(
              name: name,
              age: calculatedAge,
              job: job,
              city: location,
              distance: "0 km",
              height: height,
              lookingFor: lookingFor,
              gender: gender,
              nature: orientation,
              about: bio,
              interests: (data["Interests"] is List)
                  ? List<String>.from(data["Interests"])
                  : [],
              lifestyle: lifestyleList,
              media: mediaItems,
            );
          });
        }
      }
    } catch (e) {
      debugPrint("Error parsing profile JSON: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    showStar = widget.showStar;
    showMore = widget.showMore;
    showTelegram = widget.showTelegram;
    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.isOwnProfile) {
      _loadOwnProfile();
    } else if (widget.userEmail != null || widget.initialUserData != null) {
      final email =
          widget.userEmail ??
          widget.initialUserData?["EmailAddress"]?.toString() ??
          widget.initialUserData?["email"]?.toString() ??
          "";
      if (email.isNotEmpty) {
        _loadOtherUserProfile(email);
      } else if (widget.initialUserData != null) {
        _parseAndSetOtherProfile(widget.initialUserData!);
      }
    } else {
      // ── Load live profiles from ShowAllExceptMe for swipe feed ──
      _loadLiveFeedProfiles();
    }
  }

  @override
  void didUpdateWidget(covariant BoomProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOwnProfile && ownProfile == null) {
      _loadOwnProfile();
    }
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    _scrollCtrl.dispose();
    _disposeAllVideoControllers();
    super.dispose();
  }

  void _disposeAllVideoControllers() {
    for (final c in _videoControllers.values) {
      c.dispose();
    }
    _videoControllers.clear();
  }

  // Future<void> _pickVideo() async {
  //   final picker = ImagePicker();
  //   final picked = await picker.pickVideo(
  //     source: ImageSource.gallery,
  //     maxDuration: const Duration(seconds: _kMaxVideoSeconds),
  //   );
  //   if (picked == null || !mounted) return;
  //   final file = File(picked.path);
  //   final tempCtrl = VideoPlayerController.file(file);
  //   await tempCtrl.initialize();
  //   final dur = tempCtrl.value.duration;
  //   await tempCtrl.dispose();
  //   if (dur.inSeconds > _kMaxVideoSeconds) {
  //     if (mounted) {
  //       _showSnack(
  //         '⚠️ Video must be ≤ $_kMaxVideoSeconds seconds',
  //         AppColors.error,
  //       );
  //     }
  //     return;
  //   }
  //   final newItem = MediaItem(type: MediaType.video, localFile: file);
  //   final p = _profile;
  //   final updatedMedia = [...p.media, newItem];
  //   setState(() {
  //     sampleProfiles[_currentIndex % sampleProfiles.length] = ProfileModel(
  //       name: p.name,
  //       age: p.age,
  //       job: p.job,
  //       city: p.city,
  //       distance: p.distance,
  //       height: p.height,
  //       lookingFor: p.lookingFor,
  //       gender: p.gender,
  //       nature: p.nature,
  //       about: p.about,
  //       interests: p.interests,
  //       lifestyle: p.lifestyle,
  //       completionPercent: p.completionPercent,
  //       seenAgo: p.seenAgo,
  //       telegramUsername: p.telegramUsername,
  //       media: updatedMedia,
  //     );
  //     _mediaIndex = updatedMedia.length - 1;
  //   });
  //   _showSnack('Video added ✅', AppColors.green);
  // }

  void _snapBack() {
    final savedX = _dragX, savedY = _dragY;
    _snapAnim =
        Tween<Offset>(begin: Offset(savedX, savedY), end: Offset.zero).animate(
          CurvedAnimation(parent: _snapCtrl, curve: Curves.easeOut),
        )..addListener(() {
          if (mounted) {
            setState(() {
              _dragX = _snapAnim.value.dx;
              _dragY = _snapAnim.value.dy;
            });
          }
        });
    _snapCtrl.forward(from: 0);
  }

  Future<void> _swipeOut({required bool toLike}) async {
    if (_isSwiping) return;
    final int profileCount = _liveProfiles.isNotEmpty
        ? _liveProfiles.length
        : sampleProfiles.length;
    final int currentProfileIndex = _currentIndex % profileCount;
    final String? actionEmail = _liveProfiles.isNotEmpty &&
            currentProfileIndex < _liveProfileEmails.length
        ? _liveProfileEmails[currentProfileIndex]
        : null;

    if (toLike && actionEmail != null && actionEmail.trim().isNotEmpty) {
      try {
        final myEmail = await SecureStorage().getUserEmail() ?? '';
        await HomeService().favoriteLikeViewInsert(
          myEmail: myEmail.trim(),
          actionEmail: actionEmail.trim(),
          action: 'like',
        );
      } catch (e) {
        debugPrint('[BoomProfileScreen] Error saving swipe like: $e');
      }
    }

    setState(() => _isSwiping = true);
    final sw = MediaQuery.of(context).size.width;
    setState(() {
      _dragX = toLike ? sw * 1.8 : -sw * 1.8;
      _dragY = 0;
    });
    await Future.delayed(const Duration(milliseconds: 330));
    if (!mounted) return;
    _disposeAllVideoControllers();
    setState(() {
      _currentIndex++;
      _dragX = 0;
      _dragY = 0;
      _mediaIndex = 0;
      _isSwiping = false;
    });
    if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
    _showSnack(
      toLike ? 'Liked ❤️' : 'Nope 👋',
      toLike ? AppColors.green : AppColors.error,
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTextStyles.button.copyWith(fontSize: 14.sp),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  double get _likeOp => (_dragX / 100).clamp(0.0, 1.0);

  double get _nopeOp => (-_dragX / 100).clamp(0.0, 1.0);

  // ── Toggle favourite ──
  // ignore: unused_element
  void _toggleFavourite() {
    final idx = _currentIndex % sampleProfiles.length;
    setState(() {
      if (_favourites.contains(idx)) {
        _favourites.remove(idx);
        _showSnack('Removed from Favourites', AppColors.grey);
      } else {
        _favourites.add(idx);
        _showSnack('Added to Favourites ⭐', AppColors.green);
      }
    });
  }

  // ── Open custom Telegram page ──
  void _openTelegramPage(String? username) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.58,
          minChildSize: 0.58,
          maxChildSize: 1.0,
          snap: true,
          snapSizes: const [0.58, 1.0],
          expand: false,
          builder: (ctx, sheetScrollController) {
            return ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
              child: MessageDetailPage(
                index: 0,
                messageData: const {
                  "name": "Taniya Agarwal",
                  "image":
                      "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
                  "age": "32",
                  "gender": "F",
                  "city": "New Delhi",
                  "flag": "🇮🇳",
                },
                sheetScrollController: sheetScrollController,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSwipeFeed =
        !widget.isOwnProfile &&
        widget.userEmail == null &&
        widget.initialUserData == null;

    if (_profileNotFound) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Text(
            'No data found',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    if ((widget.isOwnProfile && ownProfile == null) ||
        _isLoadingOtherProfile ||
        (isSwipeFeed && _isLoadingLiveFeed && _liveProfiles.isEmpty)) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF9B59B6),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final isTablet = MediaQuery.of(context).size.width > 600;
    final p = _profile;

    final heroH = isTablet ? AppSize.h(520) : AppSize.h(460);
    final stripH = isTablet ? AppSize.h(200) : AppSize.h(250);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: GestureDetector(
        onPanUpdate: (d) {
          if (_isSwiping ||
              !showStar ||
              widget.userEmail != null ||
              widget.initialUserData != null ||
              widget.isOwnProfile) {
            return;
          }
          setState(() {
            _dragX += d.delta.dx;
            _dragY += d.delta.dy;
          });
        },
        onPanEnd: (_) async {
          if (_isSwiping ||
              widget.userEmail != null ||
              widget.initialUserData != null ||
              widget.isOwnProfile) {
            return;
          }
          if (!showStar) {
            _snapBack(); // ❌ swipe disabled
            return;
          }
          if (_dragX > 110) {
            await _swipeOut(toLike: true);
          } else if (_dragX < -110)
            // ignore: curly_braces_in_flow_control_structures
            await _swipeOut(toLike: false);
          else
            // ignore: curly_braces_in_flow_control_structures
            _snapBack();
        },
        child: AnimatedContainer(
          duration: _isSwiping
              ? const Duration(milliseconds: 330)
              : const Duration(milliseconds: 50),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..translate(_dragX, _dragY)
            ..rotateZ(_dragX * 0.0006),
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── 1. SliverAppBar = collapsible hero image ──
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: heroH,
                pinned: false,
                floating: false,
                backgroundColor: AppColors.bg,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: _heroImage(p, isTablet),
                ),
              ),

              // ── 2. Pinned photo strip ──
              if (p.media.isNotEmpty)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PhotoStripDelegate(
                    height: stripH,
                    child: _photoStrip(p, isTablet, stripH),
                  ),
                ),

              // ── 3. Scrollable content ──
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? AppSize.w(24) : AppSize.w(16),
                  AppSize.h(14),
                  isTablet ? AppSize.w(24) : AppSize.w(16),
                  AppSize.h(30),
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _aboutCard(p, isTablet),
                    SizedBox(height: AppSize.h(12)),
                    _lifestyle(p, isTablet),
                    SizedBox(height: AppSize.h(22)),
                    _bottomActionRow(p, isTablet),
                    SizedBox(height: AppSize.h(20)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoHeroImage(String name, bool isTablet) {
    final String initial = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : "U";

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF28133E), Color(0xFF1B1B2F), Color(0xFF110E1D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Container(
          width: isTablet ? 120.w : 90.w,
          height: isTablet ? 120.w : 90.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF9B59B6), Color(0xFF3498DB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9B59B6).withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                fontSize: isTablet ? 48.sp : 36.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  //  HERO IMAGE
  //  ✅ v7: Star bubble border -> yellow | Telegram circle color matched to reference (shape unchanged)
  // ════════════════════════════════════════
  Widget _heroImage(ProfileModel p, bool isTablet) {
    // 🔥 SAFE HERO MEDIA (always image)
    final heroMedia = p.media.isEmpty
        ? null
        : p.media.firstWhere(
            (m) => m.type == MediaType.image,
            orElse: () => p.media.first,
          );

    return Stack(
      children: [
        Positioned.fill(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── HERO IMAGE OR INITIAL AVATAR ──
              heroMedia == null
                  ? _buildNoHeroImage(p.name, isTablet)
                  : (heroMedia.type == MediaType.image
                        ? (heroMedia.isBytes
                              ? Image.memory(
                                  heroMedia.bytes!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _buildNoHeroImage(p.name, isTablet),
                                )
                              : CachedNetworkImage(
                                  imageUrl: heroMedia.url,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) =>
                                      _buildNoHeroImage(p.name, isTablet),
                                  errorWidget: (_, _, _) =>
                                      _buildNoHeroImage(p.name, isTablet),
                                ))
                        : Container(
                            color: AppColors.cardBg,
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                color: Colors.white54,
                                size: 60,
                              ),
                            ),
                          )),

              // ── DARK GRADIENT OVERLAY ──
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.30),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.25, 0.50, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── BACK BUTTON (only on detail view, not on main bottom tab) ──
        if (widget.userEmail != null || widget.initialUserData != null)
          Positioned(
            top: isTablet ? AppSize.h(32) : AppSize.h(28),
            left: isTablet ? AppSize.w(22) : AppSize.w(16),
            child: _circleBtn(
              Icons.arrow_back_ios_new_rounded,
              isTablet,
              onTap: () => Navigator.maybePop(context),
            ),
          ),

        // ── MORE BUTTON ──
        if (showMore)
          Positioned(
            top: isTablet ? AppSize.h(32) : AppSize.h(28),
            right: isTablet ? AppSize.w(22) : AppSize.w(16),
            child: _circleBtn(
              Icons.more_vert_rounded,
              isTablet,
              onTap: _reportSheet,
            ),
          ),

        // ── NAME + BADGES + ACTIONS ──
        Positioned(
          bottom: AppSize.h(16),
          left: isTablet ? AppSize.w(22) : AppSize.w(16),
          right: isTablet ? AppSize.w(22) : AppSize.w(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // NAME
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${p.name}, ${p.age}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet
                                      ? AppSize.sp(28)
                                      : AppSize.sp(24),
                                  fontWeight: FontWeight.w800,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: AppSize.w(6)),
                            Icon(
                              Icons.verified_rounded,
                              color: Colors.blue,
                              size: isTablet ? AppSize.sp(22) : AppSize.sp(18),
                            ),
                          ],
                        ),

                        SizedBox(height: AppSize.h(3)),

                        // JOB
                        Row(
                          children: [
                            Icon(
                              Icons.work_outline_rounded,
                              color: Colors.white60,
                              size: AppSize.sp(12),
                            ),
                            SizedBox(width: AppSize.w(4)),
                            Flexible(
                              child: Text(
                                p.job,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.small.copyWith(
                                  color: Colors.white60,
                                  fontSize: isTablet
                                      ? AppSize.sp(12)
                                      : AppSize.sp(11),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: AppSize.w(10)),

                  // ── ACTIONS (HEART LIKE + TELEGRAM) ──
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!widget.isOwnProfile)
                        GestureDetector(
                          onTap: () async {
                          final profileCount = _liveProfiles.isNotEmpty
                              ? _liveProfiles.length
                              : sampleProfiles.length;
                          final idx = _currentIndex % profileCount;
                          final bool nextLiked = !_favourites.contains(idx);
                          setState(() {
                            if (!nextLiked) {
                              _favourites.remove(idx);
                              _showSnack('Unliked 🤍', AppColors.grey);
                            } else {
                              _favourites.add(idx);
                              _showSnack('Liked ❤️', const Color(0xFFFF5E62));
                            }
                          });

                          final actionEmail =
                              widget.userEmail ??
                              widget.initialUserData?['EmailAddress']
                                  ?.toString() ??
                              widget.initialUserData?['email']?.toString();
                          if (actionEmail == null ||
                              actionEmail.trim().isEmpty) {
                            return;
                          }
                          try {
                            final myEmail =
                                await SecureStorage().getUserEmail() ?? '';
                            final response = await HomeService()
                                .favoriteLikeViewInsert(
                                  myEmail: myEmail.trim(),
                                  actionEmail: actionEmail.trim(),
                                  action: nextLiked ? 'like' : 'unlike',
                                );
                            if (response.statusCode < 200 ||
                                response.statusCode >= 300) {
                              throw Exception('HTTP ${response.statusCode}');
                            }
                          } catch (_) {
                            if (mounted) {
                              setState(() {
                                if (nextLiked) {
                                  _favourites.remove(idx);
                                } else {
                                  _favourites.add(idx);
                                }
                              });
                              _showSnack(
                                'Like save nahi ho saka.',
                                AppColors.error,
                              );
                            }
                          }
                          },
                          child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: isTablet ? AppSize.w(48) : AppSize.w(44),
                          height: isTablet ? AppSize.h(48) : AppSize.h(44),
                          decoration: BoxDecoration(
                            color: _isFavourited
                                ? const Color(
                                    0xFFFF5E62,
                                  ).withValues(alpha: 0.35)
                                : Colors.black.withValues(alpha: 0.42),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isFavourited
                                  ? const Color(0xFFFF5E62)
                                  : Colors.white70,
                              width: 1.5,
                            ),
                            boxShadow: _isFavourited
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF5E62,
                                      ).withValues(alpha: 0.50),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Icon(
                              _isFavourited
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: _isFavourited
                                  ? const Color(0xFFFF5E62)
                                  : Colors.white,
                              size: isTablet ? 24.sp : 20.sp,
                            ),
                          ),
                          ),
                        ),

                      SizedBox(height: AppSize.h(8)),

                      if (showTelegram)
                        GestureDetector(
                          onTap: () => _openTelegramPage(p.telegramUsername),
                          child: ClipOval(
                            child: Image.asset(
                              "assets/arroriconimage.png",
                              width: isTablet ? AppSize.w(48) : AppSize.w(44),
                              height: isTablet ? AppSize.h(48) : AppSize.h(44),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: AppSize.h(10)),

              _heroBadgeRow(p, isTablet),
            ],
          ),
        ),

        // LIKE / NOPE OVERLAY
        if (_likeOp > 0.05)
          Positioned(
            top: AppSize.h(100),
            left: AppSize.w(20),
            child: Opacity(
              opacity: _likeOp,
              child: _swipeBadge('LIKE', AppColors.green, isTablet),
            ),
          ),

        if (_nopeOp > 0.05)
          Positioned(
            top: AppSize.h(100),
            right: AppSize.w(20),
            child: Opacity(
              opacity: _nopeOp,
              child: _swipeBadge('NOPE', AppColors.error, isTablet),
            ),
          ),
      ],
    );
  }

  Widget _heroBadgeRow(ProfileModel p, bool isTablet) {
    final badges = [
      '🕐 ${p.seenAgo}',
      '📍 ${p.distance}',
      '${flagForCity(p.city)}  ${p.city}',
      '🎯 ${p.lookingFor}',
      '📏 ${p.height}',
    ];
    return SizedBox(
      height: AppSize.h(32), // ✅ 35 → 32, thoda zyada room
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
        separatorBuilder: (_, _) => SizedBox(width: AppSize.w(6)),
        itemBuilder: (_, i) => Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.w(8),
            vertical: AppSize.h(6),
          ),
          // ✅ vertical padding kam kiya
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          alignment: Alignment.center,
          // ✅ yeh add karo — text vertically center rahega
          child: Text(
            badges[i],
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? AppSize.sp(12) : AppSize.sp(11),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _swipeBadge(String lbl, Color color, bool isTablet) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: AppSize.w(16),
      vertical: AppSize.h(8),
    ),
    decoration: BoxDecoration(
      border: Border.all(color: color, width: 3),
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: Text(
      lbl,
      style: AppTextStyles.heading.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        fontSize: isTablet ? AppSize.sp(30) : AppSize.sp(26),
      ),
    ),
  );

  // ════════════════════════════════════════
  //  PHOTO STRIP
  // ════════════════════════════════════════
  Widget _photoStrip(ProfileModel p, bool isTablet, double totalHeight) {
    const dotsH = 22.0;
    final thumbH = totalHeight - dotsH - 16;
    final thumbW = isTablet ? AppSize.w(180) : AppSize.w(125);

    return Container(
      color: AppColors.cardBg,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? AppSize.w(18) : AppSize.w(14),
        vertical: AppSize.h(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: thumbH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: p.media.length,
              separatorBuilder: (_, _) => SizedBox(width: AppSize.w(12)),
              itemBuilder: (_, i) {
                // ✅ Video button wala if block bilkul hata diya
                final m = p.media[i];
                final isActive = i == _mediaIndex;

                return GestureDetector(
                  onTap: () {
                    setState(() => _mediaIndex = i);
                    _openFullscreenGallery(p, i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: thumbW,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isActive ? AppColors.accent : Colors.transparent,
                        width: isActive ? 2.5 : 0,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.35),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: m.type == MediaType.image
                          ? (m.isLocal
                                ? Image.file(m.localFile!, fit: BoxFit.cover)
                                : m.isBytes
                                ? Image.memory(
                                    m.bytes!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => _thumbShimmer(),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: m.url,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) => _thumbShimmer(),
                                    errorWidget: (_, _, _) => _thumbShimmer(),
                                  ))
                          : _VideoThumbPreview(
                              media: m,
                            ), // ✅ yaha change kiya — black box fix
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: AppSize.h(6)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              p.media.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.symmetric(horizontal: AppSize.w(3)),
                width: i == _mediaIndex ? AppSize.w(18) : AppSize.w(6),
                height: AppSize.h(6),
                decoration: BoxDecoration(
                  color: i == _mediaIndex ? AppColors.accent : AppColors.grey,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbShimmer() => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.3, end: 0.7),
    duration: const Duration(milliseconds: 700),
    builder: (_, val, _) =>
        Container(color: AppColors.surface.withValues(alpha: val + 0.3)),
    onEnd: () {},
  );

  // Widget _videoThumb(bool isTablet) => Container(
  //   color: AppColors.surface,
  //   // child: Center(child: Container(
  //   //   padding: EdgeInsets.all(AppSize.w(6)),
  //   //   decoration: BoxDecoration(
  //   //       color: AppColors.accent.withOpacity(0.85), shape: BoxShape.circle),
  //   //   child: Icon(Icons.play_arrow_rounded, color: AppColors.black,
  //   //       size: isTablet ? AppSize.sp(22) : AppSize.sp(18)),
  //   // )),
  // );

  void _openFullscreenGallery(ProfileModel p, int idx) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) =>
            FullscreenGallery(media: p.media, initialIndex: idx),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ════════════════════════════════════════
  //  CONTENT CARDS
  // ════════════════════════════════════════
  Widget _aboutCard(ProfileModel p, bool isTablet) => Container(
    padding: EdgeInsets.all(isTablet ? AppSize.w(18) : AppSize.w(16)),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      border: Border.all(color: AppColors.cardBorder),
      borderRadius: BorderRadius.circular(18.r),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '"',
              style: AppTextStyles.heading.copyWith(
                color: AppColors.accent,
                fontSize: AppSize.sp(22),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: AppSize.w(6)),
            Text(
              'About Me',
              style: AppTextStyles.subHeading.copyWith(
                fontSize: isTablet ? AppSize.sp(16) : AppSize.sp(18),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSize.h(10)),
        Text(
          p.about,
          style: AppTextStyles.body.copyWith(
            fontSize: isTablet ? AppSize.sp(13) : AppSize.sp(15),
            height: 1.7,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSize.h(14)),
        Row(
          children: [
            Text('✨  ', style: TextStyle(fontSize: AppSize.sp(14))),
            Text(
              'Interests',
              style: AppTextStyles.cardName.copyWith(
                fontSize: isTablet ? AppSize.sp(14) : AppSize.sp(18),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSize.h(10)),
        p.interests.isEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: AppSize.h(4)),
                child: Text(
                  "Not Selected",
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isTablet ? AppSize.sp(12) : AppSize.sp(14),
                  ),
                ),
              )
            : Wrap(
                spacing: AppSize.w(8),
                runSpacing: AppSize.h(8),
                children: p.interests
                    .map(
                      (t) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSize.w(12),
                          vertical: AppSize.h(6),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.cardBorder),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          t,
                          style: AppTextStyles.small.copyWith(
                            fontSize: isTablet
                                ? AppSize.sp(12)
                                : AppSize.sp(11),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
      ],
    ),
  );

  // Widget _locationCard(ProfileModel p, bool isTablet) => Container(
  //   padding: EdgeInsets.all(isTablet ? AppSize.w(18) : AppSize.w(16)),
  //   decoration: BoxDecoration(
  //     color: AppColors.cardBg,
  //     border: Border.all(color: AppColors.cardBorder),
  //     borderRadius: BorderRadius.circular(16.r),
  //   ),
  //   child: Row(
  //     children: [
  //       Text(
  //         '${flagForCity(p.city)} 📍',
  //         style: TextStyle(fontSize: AppSize.sp(20)),
  //       ),
  //       SizedBox(width: AppSize.w(10)),
  //       Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'My Location',
  //             style: AppTextStyles.cardName.copyWith(
  //               fontSize: isTablet ? AppSize.sp(14) : AppSize.sp(13),
  //             ),
  //           ),
  //           SizedBox(height: AppSize.h(2)),
  //           Text(
  //             '${p.city}\n${p.distance} away',
  //             style: AppTextStyles.small.copyWith(
  //               fontSize: isTablet ? AppSize.sp(13) : AppSize.sp(12),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   ),
  // );

  Widget _lifestyle(ProfileModel p, bool isTablet) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Lifestyle',
        style: AppTextStyles.cardName.copyWith(
          fontSize: isTablet ? AppSize.sp(15) : AppSize.sp(14),
        ),
      ),
      SizedBox(height: AppSize.h(10)),
      p.lifestyle.isEmpty
          ? Text(
              "Not Selected",
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
                fontSize: isTablet ? AppSize.sp(12) : AppSize.sp(11),
              ),
            )
          : Wrap(
              spacing: AppSize.w(8),
              runSpacing: AppSize.h(8),
              children: p.lifestyle
                  .map(
                    (t) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSize.w(14),
                        vertical: AppSize.h(8),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.cardBorder),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        t,
                        style: AppTextStyles.small.copyWith(
                          fontSize: isTablet ? AppSize.sp(12) : AppSize.sp(11),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    ],
  );

  // ════════════════════════════════════════
  //  BOTTOM ACTION ROW
  //  ✅ v6: Share Profile — white text+icon, safe bottom padding for BottomNav
  // ════════════════════════════════════════
  Widget _bottomActionRow(ProfileModel p, bool isTablet) {
    final btnH = isTablet ? AppSize.h(64) : AppSize.h(56);
    final iconSz = isTablet ? AppSize.sp(22) : AppSize.sp(19);
    final lblSz = isTablet ? AppSize.sp(13) : AppSize.sp(12);
    // ✅ bottom nav ke upar dikhne ke liye extra bottom padding
    final bottomPad = MediaQuery.of(context).padding.bottom + AppSize.h(70);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: GestureDetector(
        onTap: () {
          _showSnack('Profile link copied 🔗', Colors.blueAccent);
        },
        child: Container(
          height: btnH,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blueAccent.withValues(alpha: 0.18),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.blueAccent.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.link_rounded, color: Colors.white, size: iconSz),
              SizedBox(height: AppSize.h(4)),
              Text(
                'Share Profile',
                style: AppTextStyles.small.copyWith(
                  color: Colors.white,
                  fontSize: lblSz,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _actionBtn({
  //   required IconData icon,
  //   required String label,
  //   required Color color,
  //   required double height,
  //   required double iconSz,
  //   required double lblSz,
  //   required Gradient gradient,
  // }) => Container(
  //   height: height,
  //   decoration: BoxDecoration(
  //     gradient: gradient,
  //     borderRadius: BorderRadius.circular(16.r),
  //     border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
  //   ),
  //   child: Column(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       Icon(icon, color: color, size: iconSz),
  //       SizedBox(height: AppSize.h(4)),
  //       Text(
  //         label,
  //         style: AppTextStyles.small.copyWith(
  //           color: color,
  //           fontSize: lblSz,
  //           fontWeight: FontWeight.w600,
  //         ),
  //       ),
  //     ],
  //   ),
  // );

  // ════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════
  Widget _circleBtn(IconData icon, bool isTablet, {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: isTablet ? AppSize.h(48) : AppSize.h(42),
          width: isTablet ? AppSize.w(48) : AppSize.w(42),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(
            icon,
            color: AppColors.white,
            size: isTablet ? AppSize.sp(20) : AppSize.sp(17),
          ),
        ),
      );

  void _reportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.60),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.10),
              width: 0.5,
            ),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + AppSize.h(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle + label ──
            Padding(
              padding: EdgeInsets.fromLTRB(0, AppSize.h(14), 0, AppSize.h(18)),
              child: Column(
                children: [
                  Container(
                    width: AppSize.w(38),
                    height: AppSize.h(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: AppSize.h(12)),
                  Text(
                    'MORE OPTIONS',
                    style: TextStyle(
                      fontSize: AppSize.sp(10),
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.30),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // ── Profile strip ──
            Container(
              margin: EdgeInsets.fromLTRB(
                AppSize.w(20),
                0,
                AppSize.w(20),
                AppSize.h(20),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: AppSize.w(16),
                vertical: AppSize.h(14),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: AppSize.w(46),
                    height: AppSize.h(46),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF4B4FD9), Color(0xFFA06CF5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _profile.name
                            .split(' ')
                            .map((e) => e[0])
                            .take(2)
                            .join(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSize.w(14)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_profile.name}, ${_profile.age}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSize.h(2)),
                      Text(
                        '${_profile.job.split(' at ').first} · ${_profile.distance}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.40),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              height: 0.5,
              color: Colors.white.withValues(alpha: 0.07),
              margin: EdgeInsets.fromLTRB(
                AppSize.w(20),
                0,
                AppSize.w(20),
                AppSize.h(14),
              ),
            ),

            // ── Section label ──
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSize.w(20),
                  bottom: AppSize.h(10),
                ),
                child: Text(
                  'ACTIONS',
                  style: TextStyle(
                    fontSize: AppSize.sp(10),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),

            // ── Options ──
            ...[
              (
                '🚫',
                'Block user',
                'They won\'t see your profile anymore',
                const Color(0xFFFF5F5F),
                const Color(0x22DC3232),
              ),
              (
                '⚑',
                'Fake profile',
                'Report suspicious or impersonated account',
                Colors.orange,
                const Color(0x1FFF8C00),
              ),
              (
                '⚑',
                'Inappropriate content',
                'Report offensive photos or bio',
                Colors.orange,
                const Color(0x1FFF8C00),
              ),
              (
                '⚑',
                'Spam',
                'Promotional messages or bots',
                const Color(0xFFA06CF5),
                const Color(0x22821BE6),
              ),
            ].map(
              (opt) => GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showSnack('${opt.$2} reported ✓', AppColors.purple);
                },
                child: Container(
                  margin: EdgeInsets.fromLTRB(
                    AppSize.w(20),
                    0,
                    AppSize.w(20),
                    AppSize.h(8),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSize.w(16),
                    vertical: AppSize.h(14),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: AppSize.w(36),
                        height: AppSize.h(36),
                        decoration: BoxDecoration(
                          color: opt.$5,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Center(
                          child: Text(
                            opt.$1,
                            style: TextStyle(fontSize: AppSize.sp(16)),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSize.w(14)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.$2,
                              style: TextStyle(
                                color: opt.$2 == 'Block user'
                                    ? const Color(0xFFFF5F5F)
                                    : Colors.white,
                                fontSize: AppSize.sp(14),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: AppSize.h(2)),
                            Text(
                              opt.$3,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: AppSize.sp(11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.18),
                        size: AppSize.sp(18),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Cancel ──
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  AppSize.w(20),
                  AppSize.h(4),
                  AppSize.w(20),
                  0,
                ),
                padding: EdgeInsets.symmetric(vertical: AppSize.h(15)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.09),
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Center(
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: AppSize.sp(14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
//  SLIVER PERSISTENT HEADER DELEGATE
// ════════════════════════════════════════════════════
class _PhotoStripDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  const _PhotoStripDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_PhotoStripDelegate old) =>
      old.height != height || old.child != child;
}

// ════════════════════════════════════════════════════
//  TELEGRAM CONNECT PAGE
// ════════════════════════════════════════════════════
class TelegramConnectPage extends StatelessWidget {
  final String? username;
  final String profileName;
  final String profileImage;

  const TelegramConnectPage({
    super.key,
    this.username,
    required this.profileName,
    required this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.white,
            size: AppSize.sp(18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Connect on Telegram',
          style: AppTextStyles.subHeading.copyWith(
            fontSize: isTablet ? AppSize.sp(18) : AppSize.sp(16),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.w(24),
            vertical: AppSize.h(32),
          ),
          child: Column(
            children: [
              Container(
                width: AppSize.w(104),
                height: AppSize.w(104),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2AABEE), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2AABEE).withValues(alpha: 0.30),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: profileImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: profileImage,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              Container(color: AppColors.cardBg),
                          errorWidget: (_, _, _) => Container(
                            color: AppColors.cardBg,
                            child: Icon(
                              Icons.person_rounded,
                              color: AppColors.textSecondary,
                              size: AppSize.sp(40),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.cardBg,
                          child: Icon(
                            Icons.person_rounded,
                            color: AppColors.textSecondary,
                            size: AppSize.sp(40),
                          ),
                        ),
                ),
              ),

              SizedBox(height: AppSize.h(16)),

              Text(
                profileName,
                style: AppTextStyles.heading.copyWith(
                  fontSize: isTablet ? AppSize.sp(24) : AppSize.sp(20),
                  fontWeight: FontWeight.w800,
                ),
              ),

              SizedBox(height: AppSize.h(6)),

              if (username != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSize.w(14),
                    vertical: AppSize.h(6),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2AABEE).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: const Color(0xFF2AABEE).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '@$username',
                    style: TextStyle(
                      color: const Color(0xFF2AABEE),
                      fontSize: isTablet ? AppSize.sp(14) : AppSize.sp(13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Text(
                  'Telegram not linked yet',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: AppSize.sp(13),
                  ),
                ),

              SizedBox(height: AppSize.h(36)),

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSize.w(22)),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Container(
                      width: AppSize.w(56),
                      height: AppSize.w(56),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2AABEE).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: const Color(0xFF2AABEE),
                        size: isTablet ? AppSize.sp(28) : AppSize.sp(24),
                      ),
                    ),
                    SizedBox(height: AppSize.h(14)),
                    Text(
                      username != null
                          ? 'Message ${profileName.split(' ').first} on Telegram'
                          : 'Telegram Not Available',
                      style: AppTextStyles.cardName.copyWith(
                        fontSize: isTablet ? AppSize.sp(16) : AppSize.sp(15),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSize.h(8)),
                    Text(
                      username != null
                          ? 'Tap the button below to open a chat with '
                                '${profileName.split(' ').first} directly in Telegram.'
                          : '${profileName.split(' ').first} has not linked their '
                                'Telegram account yet. Try another way to connect.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        fontSize: isTablet ? AppSize.sp(13) : AppSize.sp(12),
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSize.h(28)),

              if (username != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: AppSize.h(54),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse('https://t.me/$username');
                      if (await canLaunchUrl(url)) {
                        launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Telegram not installed',
                                style: AppTextStyles.button.copyWith(
                                  fontSize: 14.sp,
                                ),
                              ),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Open Telegram App',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? AppSize.sp(15) : AppSize.sp(14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2AABEE),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: AppSize.h(12)),

                SizedBox(
                  width: double.infinity,
                  height: AppSize.h(54),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Username copied! 📋',
                            style: AppTextStyles.button.copyWith(
                              fontSize: 14.sp,
                            ),
                          ),
                          backgroundColor: AppColors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.copy_rounded,
                      color: AppColors.white,
                      size: isTablet ? AppSize.sp(18) : AppSize.sp(16),
                    ),
                    label: Text(
                      'Copy @$username',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: isTablet ? AppSize.sp(14) : AppSize.sp(13),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.cardBorder, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: AppSize.h(54),
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.cardBorder, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      'Go Back',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: isTablet ? AppSize.sp(14) : AppSize.sp(13),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(height: AppSize.h(20)),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoThumbPreview extends StatefulWidget {
  final MediaItem media;

  const _VideoThumbPreview({required this.media});

  @override
  State<_VideoThumbPreview> createState() => _VideoThumbPreviewState();
}

class _VideoThumbPreviewState extends State<_VideoThumbPreview> {
  VideoPlayerController? _ctrl;

  @override
  void initState() {
    super.initState();
    final m = widget.media;
    _ctrl = m.isLocal
        ? VideoPlayerController.file(m.localFile!)
        : VideoPlayerController.networkUrl(Uri.parse(m.url));
    _ctrl!.initialize().then((_) {
      if (!mounted) return;
      _ctrl!.setVolume(0);
      _ctrl!.setLooping(true);
      _ctrl!.play();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ctrl == null || !_ctrl!.value.isInitialized) {
      return Container(
        color: AppColors.surface,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white54,
            ),
          ),
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _ctrl!.value.size.width,
        height: _ctrl!.value.size.height,
        child: VideoPlayer(_ctrl!),
      ),
    );
  }
}
