import 'package:flutter/material.dart';

enum TabType {
  home,
  ranking,
  cart,
  profile
}

class TabItem {
  final String title;
  final IconData icon;
  final IconData activeIcon;

  TabItem({
    required this.title,
    required this.icon,
    required this.activeIcon,
  });
}