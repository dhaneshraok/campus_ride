import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/vehicle_data.dart';
import '../../models/user_model.dart';
import '../../utils/eco_calculator.dart';
import '../common/avatar_widget.dart';
import '../common/star_rating.dart';

class ProfileHeader extends StatelessWidget {
  final AppUser user;
  final bool showDriverBadge;
  final int rideCount;

  const ProfileHeader({
    super.key,
    required this.user,
    this.showDriverBadge = true,
    this.rideCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final vehicleType = VehicleCollection.getById(
      VehicleCollection.normalize(user.carType),
    );

    return Column(
      children: [
        // Avatar
        AvatarWidget(
          avatarId: user.avatar,
          size: AvatarSize.large,
          showRing: true,
          isDriver: user.isDriver,
        ),
        const SizedBox(height: 16),
        // Name
        Text(
          user.fullName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.darkText,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.subtitleText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),

        // Stats Row
        _buildStatsRow(),

        const SizedBox(height: 12),
        // Rating
        if (user.hasRatings)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.rowanGold.withAlpha(30),
                  AppColors.rowanGold.withAlpha(10),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.rowanGold.withAlpha(40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StarRating(rating: user.averageRating, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${user.averageRating.toStringAsFixed(1)} (${user.ratingCount})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bodyText,
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            'No ratings yet',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.lightText,
              fontWeight: FontWeight.w500,
            ),
          ),
        // Driver badge
        if (showDriverBadge && user.isDriver) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.rowanBrown.withAlpha(25),
                  AppColors.rowanBrown.withAlpha(10),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.rowanBrown.withAlpha(30)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.rowanBrown.withAlpha(38),
                        AppColors.rowanBrown.withAlpha(15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    vehicleType?.icon ?? Icons.directions_car_rounded,
                    size: 16,
                    color: AppColors.rowanBrown,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${vehicleType?.emoji ?? ''} ${user.carColor ?? ''} ${user.carModel ?? vehicleType?.label ?? 'Driver'}'
                      .trim(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.rowanBrown,
                  ),
                ),
                if (user.carPlate != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.rowanBrown.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      user.carPlate!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.rowanBrown.withAlpha(180),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatItem(
          icon: Icons.directions_car_rounded,
          value: '$rideCount',
          label: 'Rides',
        ),
        Container(
          width: 1,
          height: 30,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          color: AppColors.rowanBrown.withAlpha(20),
        ),
        _StatItem(
          icon: Icons.eco_rounded,
          value: EcoCalculator.formatCo2Saved(rideCount),
          label: 'CO\u2082 Saved',
        ),
        if (user.hasRatings) ...[
          Container(
            width: 1,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: AppColors.rowanBrown.withAlpha(20),
          ),
          _StatItem(
            icon: Icons.star_rounded,
            value: user.averageRating.toStringAsFixed(1),
            label: 'Rating',
          ),
        ],
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.rowanBrown.withAlpha(150)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.darkText,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.subtitleText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
