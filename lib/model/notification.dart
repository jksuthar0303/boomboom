import 'package:flutter/cupertino.dart';

class NotifItem {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLocked;
  bool value;

  NotifItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLocked = false,
    this.value = false,
  });
}