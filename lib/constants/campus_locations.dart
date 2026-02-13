import 'package:flutter/material.dart';

class CampusLocation {
  final String name;
  final IconData icon;
  final int popularity; // 1 = most popular

  const CampusLocation({
    required this.name,
    required this.icon,
    required this.popularity,
  });
}

class CampusLocations {
  CampusLocations._();

  static const List<CampusLocation> locations = [
    CampusLocation(
      name: 'Student Center',
      icon: Icons.groups_rounded,
      popularity: 1,
    ),
    CampusLocation(
      name: 'Rowan Blvd',
      icon: Icons.storefront_rounded,
      popularity: 2,
    ),
    CampusLocation(
      name: 'Holly Pointe',
      icon: Icons.apartment_rounded,
      popularity: 3,
    ),
    CampusLocation(
      name: 'Rec Center',
      icon: Icons.fitness_center_rounded,
      popularity: 5,
    ),
    CampusLocation(
      name: 'Engineering Hall',
      icon: Icons.precision_manufacturing_rounded,
      popularity: 4,
    ),
    CampusLocation(
      name: 'Library',
      icon: Icons.local_library_rounded,
      popularity: 6,
    ),
    CampusLocation(
      name: 'Science Hall',
      icon: Icons.science_rounded,
      popularity: 7,
    ),
    CampusLocation(
      name: 'Business Hall',
      icon: Icons.business_center_rounded,
      popularity: 8,
    ),
    CampusLocation(
      name: 'Rowan Hall',
      icon: Icons.account_balance_rounded,
      popularity: 9,
    ),
    CampusLocation(
      name: 'Mimosa Hall',
      icon: Icons.school_rounded,
      popularity: 10,
    ),
    CampusLocation(
      name: 'Triad Apartments',
      icon: Icons.home_rounded,
      popularity: 11,
    ),
    CampusLocation(
      name: 'Whitney Center',
      icon: Icons.meeting_room_rounded,
      popularity: 12,
    ),
    CampusLocation(
      name: 'Parking Lot A',
      icon: Icons.local_parking_rounded,
      popularity: 13,
    ),
    CampusLocation(
      name: 'Parking Lot B',
      icon: Icons.local_parking_rounded,
      popularity: 14,
    ),
    CampusLocation(
      name: 'Town Square',
      icon: Icons.park_rounded,
      popularity: 15,
    ),
  ];

  /// Location names as simple string list (backwards compatible)
  static List<String> get all => locations.map((l) => l.name).toList();

  /// Top N popular locations
  static List<CampusLocation> topLocations(int n) {
    final sorted = [...locations]
      ..sort((a, b) => a.popularity.compareTo(b.popularity));
    return sorted.take(n).toList();
  }

  /// Get location data by name
  static CampusLocation? getByName(String name) {
    try {
      return locations.firstWhere((l) => l.name == name);
    } catch (_) {
      return null;
    }
  }
}
