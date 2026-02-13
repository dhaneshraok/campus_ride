import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../utils/date_helpers.dart';
import '../common/avatar_widget.dart';
import 'ride_status_badge.dart';

class RideCard extends StatefulWidget {
  final Ride ride;
  final VoidCallback? onTap;
  final Widget? trailing;
  final int animationIndex;

  const RideCard({
    super.key,
    required this.ride,
    this.onTap,
    this.trailing,
    this.animationIndex = 0,
  });

  @override
  State<RideCard> createState() => _RideCardState();
}

class _RideCardState extends State<RideCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _entryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    Future.delayed(Duration(milliseconds: 80 * widget.animationIndex), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final isExpired =
        ride.isActive && ride.pickupDatetime.isBefore(DateTime.now());

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap?.call();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeInOut,
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: isExpired
                    ? Border.all(
                        color: AppColors.warning.withAlpha(77),
                        width: 1.5,
                      )
                    : null,
                boxShadow: AppColors.cardShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    // Glassmorphism overlay for expired
                    if (isExpired)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.warning.withAlpha(8),
                                AppColors.warning.withAlpha(15),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(ride, isExpired),
                          const SizedBox(height: 16),
                          _buildRoute(ride),
                          const SizedBox(height: 16),
                          _buildFooter(ride),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Ride ride, bool isExpired) {
    return Row(
      children: [
        RideStatusBadge(status: ride.status),
        const SizedBox(width: 8),
        if (isExpired)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded,
                    size: 10, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  'EXPIRED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        if (ride.isUrgent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.error.withAlpha(30),
                  AppColors.error.withAlpha(15),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 12, color: AppColors.error),
                const SizedBox(width: 2),
                Text(
                  'URGENT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRoute(Ride ride) {
    return Row(
      children: [
        // Animated route line with car icon
        SizedBox(
          width: 20,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B1420), AppColors.rowanBrown],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.rowanBrown.withAlpha(40),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              // Dotted line
              ...List.generate(
                4,
                (i) => Container(
                  width: 2.5,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 1.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Color.lerp(
                      AppColors.rowanBrown.withAlpha(100),
                      AppColors.rowanGold.withAlpha(100),
                      i / 3,
                    ),
                  ),
                ),
              ),
              // Car icon in the middle
              Icon(
                Icons.directions_car_rounded,
                size: 14,
                color: AppColors.rowanBrown.withAlpha(150),
              ),
              // Continue dotted line
              ...List.generate(
                4,
                (i) => Container(
                  width: 2.5,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 1.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Color.lerp(
                      AppColors.rowanGold.withAlpha(100),
                      AppColors.rowanGold.withAlpha(60),
                      i / 3,
                    ),
                  ),
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.rowanGold, Color(0xFFFFE066)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.rowanGold.withAlpha(40),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 8,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ride.pickupArea,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pickup',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.subtitleText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                ride.destination,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Destination',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.subtitleText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(Ride ride) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          AvatarWidget(
            avatarId: ride.riderAvatar,
            size: AvatarSize.small,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.riderName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bodyText,
                  ),
                ),
                if (ride.hasDriver)
                  Row(
                    children: [
                      Icon(Icons.directions_car_rounded,
                          size: 11,
                          color: AppColors.rowanBrown.withAlpha(150)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ride.driverName ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.subtitleText,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.rowanBrown.withAlpha(20),
                  AppColors.rowanBrown.withAlpha(10),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.rowanBrown.withAlpha(25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded,
                    size: 12, color: AppColors.rowanBrown),
                const SizedBox(width: 4),
                Text(
                  DateHelpers.formatPickupLabel(ride.pickupDatetime),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.rowanBrown,
                  ),
                ),
              ],
            ),
          ),
          if (ride.hasDriverPoints || ride.hasRiderPoints) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.rowanGold.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.rowanGold.withAlpha(30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.toll_rounded,
                      size: 12, color: AppColors.rowanGold),
                  const SizedBox(width: 3),
                  Text(
                    '${ride.driverPoints ?? ride.riderPoints} pts',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.rowanBrown,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (ride.hasOffers) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.info.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.info.withAlpha(30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_rounded,
                      size: 12, color: AppColors.info),
                  const SizedBox(width: 3),
                  Text(
                    '${ride.offerCount} offer${ride.offerCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.infoDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (widget.trailing != null) ...[
            const SizedBox(width: 8),
            widget.trailing!,
          ],
        ],
      ),
    );
  }
}
