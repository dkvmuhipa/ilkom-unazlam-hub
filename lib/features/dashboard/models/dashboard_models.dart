import 'package:flutter/material.dart';

class ServiceItem {
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final int tabIndex;
  final bool isMore;
  final bool showBadge;

  ServiceItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.tabIndex = 0,
    this.isMore = false,
    this.showBadge = false,
  });
}

class HeroBannerData {
  final String badge;
  final Color badgeBg;
  final Color badgeTextColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final List<Color> gradientColors;
  final IconData icon;
  final int tabIndex;

  const HeroBannerData({
    required this.badge,
    required this.badgeBg,
    required this.badgeTextColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.gradientColors,
    required this.icon,
    required this.tabIndex,
  });
}
