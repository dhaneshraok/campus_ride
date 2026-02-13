import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../models/ride_offer_model.dart';
import '../common/avatar_widget.dart';

class OfferCard extends StatelessWidget {
  final RideOffer offer;
  final bool isRider; // true = rider viewing offers, false = driver viewing own offer
  final VoidCallback? onChat;
  final VoidCallback? onSelect;
  final VoidCallback? onConfirm;
  final VoidCallback? onWithdraw;
  final VoidCallback? onViewProfile;

  const OfferCard({
    super.key,
    required this.offer,
    required this.isRider,
    this.onChat,
    this.onSelect,
    this.onConfirm,
    this.onWithdraw,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor,
          width: offer.isRiderConfirmed ? 1.5 : 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // Driver info row
          Row(
            children: [
              GestureDetector(
                onTap: onViewProfile,
                child: AvatarWidget(
                  avatarId: offer.driverAvatar,
                  size: AvatarSize.medium,
                  showRing: true,
                  isDriver: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onViewProfile,
                      child: Text(
                        offer.driverName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    _buildStatusLabel(),
                  ],
                ),
              ),
              _buildOfferBadge(),
            ],
          ),

          // Action buttons
          if (_hasActions) ...[
            const SizedBox(height: 12),
            _buildActions(context),
          ],
        ],
      ),
    );
  }

  Color get _borderColor {
    if (offer.isRiderConfirmed) return AppColors.rowanGold.withAlpha(100);
    if (offer.isConfirmed) return AppColors.success.withAlpha(100);
    if (offer.isDeclined || offer.isWithdrawn) return Colors.grey.withAlpha(60);
    return Colors.grey.withAlpha(30);
  }

  Widget _buildStatusLabel() {
    String text;
    Color color;

    if (offer.isPending) {
      text = isRider ? 'Wants to drive' : 'Offer sent';
      color = AppColors.info;
    } else if (offer.isRiderConfirmed) {
      text = isRider
          ? 'Waiting for driver confirmation'
          : 'Rider selected you!';
      color = AppColors.rowanGold;
    } else if (offer.isConfirmed) {
      text = 'Confirmed';
      color = AppColors.success;
    } else if (offer.isDeclined) {
      text = 'Not selected';
      color = AppColors.lightText;
    } else {
      text = 'Withdrawn';
      color = AppColors.lightText;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _buildOfferBadge() {
    Color color;
    IconData icon;

    if (offer.isPending) {
      color = AppColors.info;
      icon = Icons.access_time_rounded;
    } else if (offer.isRiderConfirmed) {
      color = AppColors.rowanGold;
      icon = Icons.star_rounded;
    } else if (offer.isConfirmed) {
      color = AppColors.success;
      icon = Icons.check_circle_rounded;
    } else if (offer.isDeclined) {
      color = AppColors.lightText;
      icon = Icons.cancel_rounded;
    } else {
      color = AppColors.lightText;
      icon = Icons.undo_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  bool get _hasActions {
    if (isRider) return offer.isPending || offer.isRiderConfirmed;
    return offer.isPending || offer.isRiderConfirmed;
  }

  Widget _buildActions(BuildContext context) {
    if (isRider) {
      // Rider: Chat + Select (pending), or waiting label (rider_confirmed)
      if (offer.isPending) {
        return Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Chat',
                icon: Icons.chat_bubble_outline_rounded,
                color: AppColors.rowanBrown,
                outlined: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onChat?.call();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: 'Select',
                icon: Icons.check_rounded,
                color: AppColors.success,
                outlined: false,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onSelect?.call();
                },
              ),
            ),
          ],
        );
      }
      // rider_confirmed: just chat
      return _ActionButton(
        label: 'Chat',
        icon: Icons.chat_bubble_outline_rounded,
        color: AppColors.rowanBrown,
        outlined: true,
        onTap: () {
          HapticFeedback.lightImpact();
          onChat?.call();
        },
      );
    } else {
      // Driver: Withdraw (pending), or Confirm (rider_confirmed)
      if (offer.isPending) {
        return _ActionButton(
          label: 'Withdraw Offer',
          icon: Icons.undo_rounded,
          color: AppColors.error,
          outlined: true,
          onTap: () {
            HapticFeedback.mediumImpact();
            onWithdraw?.call();
          },
        );
      }
      if (offer.isRiderConfirmed) {
        return _ActionButton(
          label: 'Confirm Ride',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          outlined: false,
          onTap: () {
            HapticFeedback.mediumImpact();
            onConfirm?.call();
          },
        );
      }
      return const SizedBox.shrink();
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.outlined,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: outlined ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: outlined ? Border.all(color: color.withAlpha(80)) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: outlined ? color : Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: outlined ? color : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
