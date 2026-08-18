import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:xml/xml.dart' as xml;

import '../../constant/apptextstyle.dart';
import '../../constant/colors.dart';
import '../../backend/secure_storage.dart';
import 'package:get/get.dart';
import '../../backend/registerservice.dart';
import '../../controller/auth_controller.dart';

class UploadPhotosScreen extends StatefulWidget {
  final bool isRegister;
  const UploadPhotosScreen({super.key, this.isRegister = false});

  static List<File> getNewSelectedImages() {
    return _UploadPhotosScreenState.activeState?.images
            .whereType<File>()
            .toList() ??
        [];
  }

  static List<File> getNewSelectedVideos() {
    return _UploadPhotosScreenState.activeState?.videos ?? [];
  }

  @override
  State<UploadPhotosScreen> createState() => _UploadPhotosScreenState();
}

class _UploadPhotosScreenState extends State<UploadPhotosScreen> {
  static _UploadPhotosScreenState? activeState;
  final ImagePicker _picker = ImagePicker();

  List<File?> images = List.generate(6, (_) => null);
  List<String?> imageUrls = List.generate(6, (_) => null);
  List<String?> imageIds = List.generate(6, (_) => null);

  /// 🔥 LIVE VIDEOS
  List<File> videos = [];
  List<VideoPlayerController> videoControllers = [];
  List<String> videoUrls = [];
  List<String> videoIds = [];
  List<VideoPlayerController> networkVideoControllers = [];

  int get selectedCount {
    int count = 0;
    for (int i = 0; i < 6; i++) {
      if (images[i] != null || imageUrls[i] != null) {
        count++;
      }
    }
    return count;
  }

  bool get isValid => selectedCount >= 3;

  @override
  void initState() {
    super.initState();
    activeState = this;
    _loadExistingPhotos();
  }

  Future<void> _loadExistingPhotos() async {
    try {
      final jsonStr = await SecureStorage().getProfileJson();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        final List? dataList = decoded["Data"];
        if (dataList != null && dataList.isNotEmpty) {
          final data = dataList.first;
          dynamic rawMedia = data["Media"] ?? data["Photos"] ?? data["Photo"];
          if (rawMedia is List) {
            int imgIndex = 0;
            for (var m in rawMedia) {
              String? url;
              String? type = "image";
              String? id;
              if (m is Map) {
                url = m["Url"] ?? m["Media"];
                type = m["Type"] ?? "image";
                id =
                    m["Id"]?.toString() ??
                    m["id"]?.toString() ??
                    m["MediaId"]?.toString() ??
                    m["mediaId"]?.toString() ??
                    m["PhotoId"]?.toString();
              } else if (m is String) {
                url = m;
              }
              if (url != null && url.isNotEmpty) {
                if (!url.startsWith("http")) {
                  url = "https://boomboomdate.com/$url";
                }
                if (type == "image") {
                  if (imgIndex < 6) {
                    imageUrls[imgIndex] = url;
                    imageIds[imgIndex] = id;
                    imgIndex++;
                  }
                } else if (type == "video") {
                  videoUrls.add(url);
                  videoIds.add(id ?? "");
                  final controller = VideoPlayerController.networkUrl(
                    Uri.parse(url),
                  );
                  controller.initialize().then((_) {
                    setState(() {});
                  });
                  controller.setLooping(true);
                  controller.play();
                  networkVideoControllers.add(controller);
                }
              }
            }
            setState(() {});
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading existing photos: $e");
    }
  }

  /// 🔥 PICK MULTIPLE IMAGES (AUTO FILL WITH COMPRESSION)
  Future<void> pickImages() async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (picked.isEmpty) return;

    int index = 0;
    for (var img in picked) {
      while (index < 6 && (images[index] != null || imageUrls[index] != null)) {
        index++;
      }

      if (index < 6) {
        images[index] = File(img.path);
        imageUrls[index] = null; // replace existing URL if any
        imageIds[index] = null; // reset server ID
      } else {
        break;
      }
    }
    setState(() {});
  }

  /// ❌ REMOVE IMAGE WITH CONFIRMATION DIALOG
  Future<void> removeImage(int i) async {
    // 1. Show Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161626),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Colors.white12),
        ),
        title: Text(
          "Delete Photo",
          style: AppTextStyles.body.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this photo from your profile?",
          style: AppTextStyles.small.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Delete",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    String? id = imageIds[i];
    final String? currentUrl = imageUrls[i];

    // 2. If it's a server image, delete it via MediaDelete SOAP API
    if (id != null || currentUrl != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

      try {
        final email = await SecureStorage().getUserEmail() ?? "";
        if (email.isNotEmpty) {
          // If ID is missing, refresh profile to fetch fresh Media IDs
          if (id == null && currentUrl != null) {
            final freshRes = await RegisterService().showCompleteProfile(
              email: email,
            );
            if (freshRes.statusCode == 200) {
              final doc = xml.XmlDocument.parse(freshRes.body);
              final res = doc.findAllElements('ShowCompleteProfileResult');
              if (res.isNotEmpty) {
                final jsonProfile = jsonDecode(res.first.innerText);
                if (jsonProfile["ResultSets"] is List &&
                    jsonProfile["ResultSets"].length > 2) {
                  final List mediaList = jsonProfile["ResultSets"][2];
                  for (var m in mediaList) {
                    final mUrl = m["Media"] ?? m["MediaName"];
                    if (mUrl != null && currentUrl.contains(mUrl.toString())) {
                      id = m["Id"]?.toString() ?? m["id"]?.toString();
                      break;
                    }
                  }
                }
              }
            }
          }

          if (id != null && id.isNotEmpty) {
            debugPrint(
              "🔥 [MediaDelete] Calling API for ID: $id, Email: $email",
            );
            final res = await RegisterService().mediaDelete(
              id: int.parse(id),
              email: email,
            );
            debugPrint(
              "🔥 [MediaDelete Response]: ${res.statusCode} - ${res.body}",
            );
          }

          // Re-fetch and sync complete profile
          await Get.put(
            AuthController(),
          ).fetchAndStoreFullProfile(email: email);
        }
      } catch (e) {
        debugPrint("Error deleting image: $e");
      }

      if (mounted) {
        Navigator.pop(context); // close loader
      }
    }

    images[i] = null;
    imageUrls[i] = null;
    imageIds[i] = null;
    setState(() {});
  }

  /// 🔥 RECORD LIVE VIDEO
  Future<void> recordVideo() async {
    final totalVideoCount = videos.length + videoUrls.length;
    if (totalVideoCount >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Only 2 videos allowed"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 7),
    );

    if (video != null) {
      final file = File(video.path);
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      controller.setLooping(true);
      controller.play();

      setState(() {
        videos.add(file);
        videoControllers.add(controller);
      });
    }
  }

  /// ❌ REMOVE VIDEO
  void removeVideo(int i) {
    videoControllers[i].dispose();
    videoControllers.removeAt(i);
    videos.removeAt(i);
    setState(() {});
  }

  @override
  void dispose() {
    for (var controller in videoControllers) {
      controller.dispose();
    }
    for (var controller in networkVideoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.black,

      appBar: AppBar(
        backgroundColor: AppColors.black,

        title: Text(
          "Upload Photos",

          style: AppTextStyles.subHeading.copyWith(
            color: Colors.white,
            fontSize: 30.h,
          ),
        ),

        leading: Icon(Icons.arrow_back),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),

          child: Column(
            children: [
              /// INFO TEXT
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Add up to 6 photos to your profile. ",
                      style: AppTextStyles.small,
                    ),

                    TextSpan(
                      text: "At least 3 photos are required. ",
                      style: AppTextStyles.small.copyWith(color: Colors.red),
                    ),

                    TextSpan(
                      text: "Choose clear, recent photos that show your face.",
                      style: AppTextStyles.small,
                    ),
                  ],
                ),

                textAlign: TextAlign.center,
              ),

              SizedBox(height: 15.h),

              /// COUNT
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),

                decoration: BoxDecoration(
                  color: AppColors.secondary,

                  borderRadius: BorderRadius.circular(10.r),
                ),

                child: Text(
                  "$selectedCount / 3 required photos uploaded",

                  style: AppTextStyles.small,
                ),
              ),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, i) {
                  final hasLocalImage = images[i] != null;
                  final hasNetworkImage =
                      imageUrls[i] != null && imageUrls[i]!.isNotEmpty;

                  return GestureDetector(
                    onTap: pickImages,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: (hasLocalImage || hasNetworkImage)
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16.r),
                                  child: hasLocalImage
                                      ? Image.file(
                                          images[i]!,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          imageUrls[i]!,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.white30,
                                                  ),
                                        ),
                                ),

                                /// REMOVE BUTTON
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () => removeImage(i),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add, color: Colors.white38),
                                const SizedBox(height: 5),
                                Text("Add Photo", style: AppTextStyles.small),
                                if (i < 3)
                                  Text(
                                    "Required",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  );
                },
              ),

              /// 🔥 LIVE VIDEOS TITLE
              Align(
                alignment: Alignment.centerLeft,

                child: Text(
                  "Live Videos",

                  style: AppTextStyles.subHeading.copyWith(color: Colors.white),
                ),
              ),

              SizedBox(height: 15.h),

              /// 🔥 LIVE VIDEO UI
              SizedBox(
                height: 160.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: (videos.length + videoUrls.length) < 2
                      ? (videos.length + videoUrls.length) + 1
                      : (videos.length + videoUrls.length),
                  separatorBuilder: (_, _) => SizedBox(width: 12.w),
                  itemBuilder: (context, i) {
                    final totalCount = videos.length + videoUrls.length;

                    /// 🔥 ADD VIDEO BUTTON
                    if (i == totalCount && totalCount < 2) {
                      return GestureDetector(
                        onTap: recordVideo,
                        child: Container(
                          width: 150.w,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam,
                                color: Colors.white38,
                                size: 38.sp,
                              ),
                              SizedBox(height: 10.h),
                              Text("Record Video", style: AppTextStyles.small),
                              SizedBox(height: 4.h),
                              const Text(
                                "Max 7 sec",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                "$totalCount/2",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    /// 🔥 VIDEO CARD
                    final isNetworkVideo = i < videoUrls.length;
                    final VideoPlayerController controller = isNetworkVideo
                        ? networkVideoControllers[i]
                        : videoControllers[i - videoUrls.length];

                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: SizedBox(
                            width: 150.w,
                            child: controller.value.isInitialized
                                ? AspectRatio(
                                    aspectRatio: controller.value.aspectRatio,
                                    child: VideoPlayer(controller),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        /// ❌ REMOVE VIDEO
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF161626),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.r),
                                    side: const BorderSide(
                                      color: Colors.white12,
                                    ),
                                  ),
                                  title: Text(
                                    "Delete Video",
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    "Are you sure you want to delete this video from your profile?",
                                    style: AppTextStyles.small.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(color: Colors.white60),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text(
                                        "Delete",
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm != true || !mounted) return;

                              if (isNetworkVideo) {
                                final id = videoIds[i];
                                if (id.isNotEmpty) {
                                  // Server video delete
                                  showDialog(
                                    // ignore: use_build_context_synchronously
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                  try {
                                    final email =
                                        await SecureStorage().getUserEmail() ??
                                        "";
                                    if (email.isNotEmpty) {
                                      final res = await RegisterService()
                                          .mediaDelete(
                                            id: int.parse(id),
                                            email: email,
                                          );
                                      if (res.statusCode == 200) {
                                        // Re-fetch complete profile
                                        await Get.put(
                                          AuthController(),
                                        ).fetchAndStoreFullProfile(
                                          email: email,
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    debugPrint("Error deleting video: $e");
                                  }
                                  if (mounted) {
                                    // ignore: use_build_context_synchronously
                                    Navigator.pop(context); // close loader
                                  }
                                }
                                videoUrls.removeAt(i);
                                if (i < videoIds.length) {
                                  videoIds.removeAt(i);
                                }
                                networkVideoControllers[i].dispose();
                                networkVideoControllers.removeAt(i);
                              } else {
                                removeVideo(i - videoUrls.length);
                              }
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              SizedBox(height: 20.h),

              /// NEXT BUTTON
              if (widget.isRegister) ...[
                Container(
                  width: double.infinity,

                  height: 55.h,

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.r),

                    gradient: LinearGradient(
                      colors: isValid
                          ? [Colors.blue, Colors.purple]
                          : [Colors.grey, Colors.grey],
                    ),
                  ),

                  padding: EdgeInsets.all(2),

                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.black,

                      borderRadius: BorderRadius.circular(30.r),
                    ),

                    child: Center(
                      child: Text("Next", style: AppTextStyles.button),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
