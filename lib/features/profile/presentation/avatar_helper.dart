import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

final Map<String, ({IconData icon, Color color, Color bg})> builtInAvatars = {
  'avatar:barbell': (
    icon: Icons.fitness_center_rounded,
    color: AppTheme.voltYellow,
    bg: const Color(0xFF2E3314)
  ),
  'avatar:fire': (
    icon: Icons.local_fire_department_rounded,
    color: const Color(0xFFFF5722),
    bg: const Color(0xFF3B1F17)
  ),
  'avatar:biceps': (
    icon: Icons.bolt_rounded,
    color: const Color(0xFF00E5FF),
    bg: const Color(0xFF0C2B30)
  ),
  'avatar:trophy': (
    icon: Icons.emoji_events_rounded,
    color: const Color(0xFFFFD700),
    bg: const Color(0xFF332E14)
  ),
  'avatar:heart': (
    icon: Icons.favorite_rounded,
    color: const Color(0xFFFF2D55),
    bg: const Color(0xFF38151D)
  ),
  'avatar:star': (
    icon: Icons.star_rounded,
    color: const Color(0xFFBB86FC),
    bg: const Color(0xFF261836)
  ),
};

Widget buildAvatarWidget({
  required String path,
  required double radius,
  required Color fallbackColor,
}) {
  if (path.startsWith('avatar:')) {
    final avatar = builtInAvatars[path];
    if (avatar != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: avatar.bg,
        child: Icon(
          avatar.icon,
          size: radius * 1.1,
          color: avatar.color,
        ),
      );
    }
  }

  if (path.isNotEmpty) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.transparent,
          backgroundImage: FileImage(file),
        );
      }
    } catch (_) {
      // Fallback if file read fails
    }
  }

  return CircleAvatar(
    radius: radius,
    backgroundColor: fallbackColor.withOpacity(0.12),
    child: Icon(
      Icons.person,
      size: radius * 1.1,
      color: fallbackColor,
    ),
  );
}
