// ignore_for_file: unrelated_type_equality_checks

import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkController extends GetxController {
  var isOnline = true.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  void _init() async {
    final result = await Connectivity().checkConnectivity();
    isOnline.value = result != ConnectivityResult.none;

    Connectivity().onConnectivityChanged.listen((result) {
      isOnline.value = result != ConnectivityResult.none;
    });
  }

  // 🔥 YE ADD KARNA THA
  @override
  Future<void> refresh() async {
    final result = await Connectivity().checkConnectivity();
    isOnline.value = result != ConnectivityResult.none;
  }
}
