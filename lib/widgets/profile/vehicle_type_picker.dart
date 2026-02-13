import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/vehicle_data.dart';

class VehicleTypePicker extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onSelected;

  const VehicleTypePicker({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: VehicleCollection.types.map((vehicle) {
        final isSelected = selectedType == vehicle.id;
        return GestureDetector(
          onTap: () => onSelected(vehicle.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.rowanBrown.withValues(alpha: 0.08)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.rowanBrown.withValues(alpha: 0.35)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(vehicle.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Icon(
                  vehicle.icon,
                  size: 16,
                  color: isSelected
                      ? AppColors.rowanBrown
                      : AppColors.lightText,
                ),
                const SizedBox(width: 6),
                Text(
                  vehicle.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? AppColors.rowanBrown
                        : AppColors.subtitleText,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
