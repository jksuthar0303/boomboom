import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'networkscreen.dart';
import 'nointernetcontroller.dart';


class NetworkWrapper extends StatelessWidget {
  final Widget child;

  const NetworkWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NetworkController>();

    return Obx(() {
      if (!controller.isOnline.value) {
        return  NoInternetScreen();
      } else {
        return child;
      }
    });
  }
}