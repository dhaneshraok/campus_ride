import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../constants/campus_locations.dart';

class LocationChipRow extends StatefulWidget {
  final ValueChanged<String> onLocationSelected;
  final String? selectedLocation;

  const LocationChipRow({
    super.key,
    required this.onLocationSelected,
    this.selectedLocation,
  });

  @override
  State<LocationChipRow> createState() => _LocationChipRowState();
}

class _LocationChipRowState extends State<LocationChipRow> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedLocation;
  }

  @override
  void didUpdateWidget(LocationChipRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLocation != oldWidget.selectedLocation) {
      _selected = widget.selectedLocation;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topLocations = CampusLocations.topLocations(3);
    final topNames = topLocations.map((l) => l.name).toSet();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: CampusLocations.locations.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final location = CampusLocations.locations[index];
          final isSelected = _selected == location.name;
          final isPopular = topNames.contains(location.name);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selected = location.name);
              widget.onLocationSelected(location.name);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF6B1420), AppColors.rowanBrown],
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: isSelected
                    ? null
                    : Border.all(
                        color: AppColors.rowanBrown.withAlpha(38),
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.rowanBrown.withAlpha(40),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : AppColors.cardShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    location.icon,
                    size: 14,
                    color: isSelected
                        ? Colors.white
                        : AppColors.rowanBrown.withAlpha(180),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    location.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.rowanBrown,
                    ),
                  ),
                  if (isPopular && !isSelected) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.rowanGold.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Popular',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.rowanGoldDark,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
