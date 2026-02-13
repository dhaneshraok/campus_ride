import 'package:flutter/material.dart';

enum AvatarType { rider, driver }

class AvatarData {
  final String id;
  final String label;
  final String emoji;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final AvatarType type;

  const AvatarData({
    required this.id,
    required this.label,
    required this.emoji,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.type,
  });
}

class AvatarCollection {
  AvatarCollection._();

  // ── Driver Avatars (Human Characters) ──
  static const List<AvatarData> driverAvatars = [
    AvatarData(
      id: 'car_mcqueen',
      label: 'Captain Miles',
      emoji: '🧔‍♂️',
      icon: Icons.face_rounded,
      primaryColor: Color(0xFFD32F2F),
      secondaryColor: Color(0xFFFFC107),
      type: AvatarType.driver,
    ),
    AvatarData(
      id: 'car_mater',
      label: 'Driver Nova',
      emoji: '👨‍🦱',
      icon: Icons.emoji_people_rounded,
      primaryColor: Color(0xFF8D6E63),
      secondaryColor: Color(0xFFFF8F00),
      type: AvatarType.driver,
    ),
    AvatarData(
      id: 'car_sally',
      label: 'Road Lily',
      emoji: '👩‍🦰',
      icon: Icons.person_pin_rounded,
      primaryColor: Color(0xFF00897B),
      secondaryColor: Color(0xFF4FC3F7),
      type: AvatarType.driver,
    ),
    AvatarData(
      id: 'car_doc',
      label: 'Coach Hudson',
      emoji: '👨‍🦳',
      icon: Icons.psychology_rounded,
      primaryColor: Color(0xFF283593),
      secondaryColor: Color(0xFF90A4AE),
      type: AvatarType.driver,
    ),
    AvatarData(
      id: 'car_ramone',
      label: 'Chill Ramon',
      emoji: '😎',
      icon: Icons.tag_faces_rounded,
      primaryColor: Color(0xFF7B1FA2),
      secondaryColor: Color(0xFFF48FB1),
      type: AvatarType.driver,
    ),
    AvatarData(
      id: 'car_flo',
      label: 'Smiley Flo',
      emoji: '😊',
      icon: Icons.mood_rounded,
      primaryColor: Color(0xFFE91E63),
      secondaryColor: Color(0xFF80CBC4),
      type: AvatarType.driver,
    ),
    AvatarData(
      id: 'car_luigi',
      label: 'Turbo Leo',
      emoji: '🧑‍🦱',
      icon: Icons.person_rounded,
      primaryColor: Color(0xFF388E3C),
      secondaryColor: Color(0xFFFFFFFF),
      type: AvatarType.driver,
    ),
    AvatarData(
      id: 'car_sheriff',
      label: 'Safe Sam',
      emoji: '🧑‍✈️',
      icon: Icons.verified_user_rounded,
      primaryColor: Color(0xFFF9A825),
      secondaryColor: Color(0xFF5D4037),
      type: AvatarType.driver,
    ),
    AvatarData(
      id: 'car_guido',
      label: 'Buddy Gio',
      emoji: '😁',
      icon: Icons.sentiment_very_satisfied_rounded,
      primaryColor: Color(0xFF1565C0),
      secondaryColor: Color(0xFFEF5350),
      type: AvatarType.driver,
    ),
    AvatarData(
      id: 'car_chick',
      label: 'Ace Ryder',
      emoji: '🤠',
      icon: Icons.emoji_emotions_rounded,
      primaryColor: Color(0xFF558B2F),
      secondaryColor: Color(0xFFCDDC39),
      type: AvatarType.driver,
    ),
  ];

  // ── Rider Avatars (Human Campus Characters) ──
  static const List<AvatarData> riderAvatars = [
    AvatarData(
      id: 'campus_owl',
      label: 'Study Owl',
      emoji: '🧑‍🎓',
      icon: Icons.face_rounded,
      primaryColor: Color(0xFF531017),
      secondaryColor: Color(0xFFFFCC00),
      type: AvatarType.rider,
    ),
    AvatarData(
      id: 'campus_grad',
      label: 'Grad Alex',
      emoji: '👨‍🎓',
      icon: Icons.school_rounded,
      primaryColor: Color(0xFFF9A825),
      secondaryColor: Color(0xFFFFE082),
      type: AvatarType.rider,
    ),
    AvatarData(
      id: 'campus_backpack',
      label: 'Backpack Jamie',
      emoji: '👩‍🎒',
      icon: Icons.emoji_people_rounded,
      primaryColor: Color(0xFF00897B),
      secondaryColor: Color(0xFF80CBC4),
      type: AvatarType.rider,
    ),
    AvatarData(
      id: 'campus_book',
      label: 'Bookworm Riley',
      emoji: '👩‍🏫',
      icon: Icons.menu_book_rounded,
      primaryColor: Color(0xFF3949AB),
      secondaryColor: Color(0xFF9FA8DA),
      type: AvatarType.rider,
    ),
    AvatarData(
      id: 'campus_lab',
      label: 'Lab Hero',
      emoji: '👨‍🔬',
      icon: Icons.science_rounded,
      primaryColor: Color(0xFF2E7D32),
      secondaryColor: Color(0xFFA5D6A7),
      type: AvatarType.rider,
    ),
    AvatarData(
      id: 'campus_artist',
      label: 'Artist Kai',
      emoji: '👩‍🎨',
      icon: Icons.palette_rounded,
      primaryColor: Color(0xFF8E24AA),
      secondaryColor: Color(0xFFCE93D8),
      type: AvatarType.rider,
    ),
    AvatarData(
      id: 'campus_music',
      label: 'Music Nova',
      emoji: '👨‍🎤',
      icon: Icons.music_note_rounded,
      primaryColor: Color(0xFFD81B60),
      secondaryColor: Color(0xFFF48FB1),
      type: AvatarType.rider,
    ),
    AvatarData(
      id: 'campus_athlete',
      label: 'Athlete Max',
      emoji: '🤾',
      icon: Icons.sports_rounded,
      primaryColor: Color(0xFFEF6C00),
      secondaryColor: Color(0xFFFFCC80),
      type: AvatarType.rider,
    ),
    AvatarData(
      id: 'campus_gamer',
      label: 'Gamer Sky',
      emoji: '🧑‍💻',
      icon: Icons.sports_esports_rounded,
      primaryColor: Color(0xFF1565C0),
      secondaryColor: Color(0xFF90CAF9),
      type: AvatarType.rider,
    ),
    AvatarData(
      id: 'campus_rocket',
      label: 'Rocket Jay',
      emoji: '🧑‍🚀',
      icon: Icons.rocket_launch_rounded,
      primaryColor: Color(0xFFD32F2F),
      secondaryColor: Color(0xFFFFCDD2),
      type: AvatarType.rider,
    ),
    AvatarData(
      id: 'campus_explorer',
      label: 'Explorer Zee',
      emoji: '🧗',
      icon: Icons.explore_rounded,
      primaryColor: Color(0xFFFF8F00),
      secondaryColor: Color(0xFFFFE0B2),
      type: AvatarType.rider,
    ),
    AvatarData(
      id: 'campus_nightowl',
      label: 'Night Buddy',
      emoji: '🦸',
      icon: Icons.nightlight_rounded,
      primaryColor: Color(0xFF4527A0),
      secondaryColor: Color(0xFFB39DDB),
      type: AvatarType.rider,
    ),
  ];

  static List<AvatarData> get allAvatars => [...riderAvatars, ...driverAvatars];

  static AvatarData? getById(String id) {
    try {
      return allAvatars.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  static const Map<String, String> _legacyEmojiMap = {
    '🦉': 'campus_owl',
    '🎓': 'campus_grad',
    '🚗': 'car_mcqueen',
    '👽': 'campus_explorer',
    '🦊': 'campus_nightowl',
    '🤖': 'campus_gamer',
    '⚽': 'campus_athlete',
    '🎵': 'campus_music',
    '🚀': 'campus_rocket',
    '🐶': 'campus_backpack',
    '🐱': 'campus_artist',
    '🦁': 'car_sheriff',
    '🌟': 'campus_grad',
    '🎨': 'campus_artist',
    '🏀': 'campus_athlete',
    '🎮': 'campus_gamer',
  };

  static String normalizeAvatarId(String value) {
    final mapped = _legacyEmojiMap[value];
    if (mapped != null) return mapped;
    return getById(value) != null ? value : defaultRiderAvatar;
  }

  static bool isAvatarId(String value) {
    return value.startsWith('car_') || value.startsWith('campus_');
  }

  static const String defaultRiderAvatar = 'campus_owl';
  static const String defaultDriverAvatar = 'car_mcqueen';
}
