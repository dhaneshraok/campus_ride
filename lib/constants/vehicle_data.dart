import 'package:flutter/material.dart';

class VehicleTypeData {
  final String id;
  final String label;
  final String emoji;
  final IconData icon;

  const VehicleTypeData({
    required this.id,
    required this.label,
    required this.emoji,
    required this.icon,
  });
}

class VehicleCollection {
  VehicleCollection._();

  static const List<VehicleTypeData> types = [
    VehicleTypeData(
      id: 'sedan',
      label: 'Sedan',
      emoji: '🚗',
      icon: Icons.directions_car_rounded,
    ),
    VehicleTypeData(
      id: 'hatchback',
      label: 'Hatchback',
      emoji: '🚙',
      icon: Icons.commute_rounded,
    ),
    VehicleTypeData(
      id: 'suv',
      label: 'SUV',
      emoji: '🚘',
      icon: Icons.airport_shuttle_rounded,
    ),
    VehicleTypeData(
      id: 'pickup',
      label: 'Pickup',
      emoji: '🛻',
      icon: Icons.fire_truck_rounded,
    ),
    VehicleTypeData(
      id: 'van',
      label: 'Van',
      emoji: '🚐',
      icon: Icons.directions_bus_filled_rounded,
    ),
    VehicleTypeData(
      id: 'ev',
      label: 'EV',
      emoji: '⚡',
      icon: Icons.electric_car_rounded,
    ),
  ];

  static const String defaultVehicleType = 'sedan';

  static VehicleTypeData? getById(String id) {
    try {
      return types.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  static String normalize(String? id) {
    final value = id?.trim() ?? '';
    if (value.isEmpty) return defaultVehicleType;
    return getById(value) != null ? value : defaultVehicleType;
  }
}
