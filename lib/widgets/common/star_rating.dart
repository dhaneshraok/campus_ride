import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final bool interactive;
  final ValueChanged<int>? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 24,
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (i) {
        final starValue = i + 1;
        IconData icon;
        Color color;

        if (rating >= starValue) {
          icon = Icons.star_rounded;
          color = AppColors.rowanGold;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half_rounded;
          color = AppColors.rowanGold;
        } else {
          icon = Icons.star_outline_rounded;
          color = Colors.grey.shade300;
        }

        final star = Icon(icon, size: size, color: color);

        if (!interactive) return star;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onRatingChanged?.call(starValue);
          },
          child: AnimatedScale(
            scale: rating >= starValue ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: star,
            ),
          ),
        );
      }),
    );
  }
}
