class EcoCalculator {
  EcoCalculator._();

  /// Average CO2 saved per shared ride in kg.
  /// Based on: avg campus trip ~3 miles, ~2.3 kg CO2 solo, ~1.15 kg saved when shared.
  static const double co2PerSharedRide = 1.15;

  /// Calculate total CO2 saved in kg.
  static double co2SavedKg(int completedRides) {
    return completedRides * co2PerSharedRide;
  }

  /// Format CO2 saved as a string.
  static String formatCo2Saved(int completedRides) {
    final saved = co2SavedKg(completedRides);
    if (saved < 1) return '${(saved * 1000).round()}g';
    if (saved < 10) return '${saved.toStringAsFixed(1)} kg';
    return '${saved.round()} kg';
  }

  /// Equivalent trees planted (1 tree absorbs ~22 kg CO2/year).
  static String treesEquivalent(int completedRides) {
    final trees = co2SavedKg(completedRides) / 22;
    if (trees < 0.1) return '0.1';
    if (trees < 1) return trees.toStringAsFixed(1);
    return trees.round().toString();
  }
}
