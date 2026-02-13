import 'avatar_data.dart';

class AvatarList {
  AvatarList._();

  /// All rider avatar IDs
  static List<String> get riderIds =>
      AvatarCollection.riderAvatars.map((a) => a.id).toList();

  /// All driver avatar IDs
  static List<String> get driverIds =>
      AvatarCollection.driverAvatars.map((a) => a.id).toList();

  /// All avatar IDs combined
  static List<String> get all => [...riderIds, ...driverIds];

  /// Legacy emoji avatars for backwards compatibility
  static const List<String> legacyEmojis = [
    '🦉', '🎓', '🚗', '👽', '🦊', '🤖', '⚽', '🎵',
    '🚀', '🐶', '🐱', '🦁', '🌟', '🎨', '🏀', '🎮',
  ];

  static const String defaultAvatar = 'campus_owl';
  static const String defaultDriverAvatar = 'car_mcqueen';

  /// Check if a string is a legacy emoji avatar
  static bool isLegacyEmoji(String value) {
    return legacyEmojis.contains(value);
  }
}
