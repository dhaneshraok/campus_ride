import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/ride_status.dart';
import '../../models/ride_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../../utils/date_helpers.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../models/ride_offer_model.dart';
import '../../widgets/ride/offer_card.dart';
import '../../widgets/ride/points_input_sheet.dart';
import '../../widgets/ride/ride_status_badge.dart';
import '../chat/chat_screen.dart';
import '../rating/rate_ride_screen.dart';
import '../profile/public_profile_screen.dart';
import 'create_ride_screen.dart';
import 'edit_ride_screen.dart';

class RideDetailScreen extends StatelessWidget {
  final String rideId;

  const RideDetailScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {
    final rideProvider = context.read<RideProvider>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(
          'Ride Details',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      body: StreamBuilder<Ride>(
        stream: rideProvider.rideStream(rideId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: List.generate(
                  3,
                  (_) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Ride not found'));
          }

          final ride = snapshot.data!;
          return _RideDetailContent(ride: ride);
        },
      ),
    );
  }
}

class _RideDetailContent extends StatefulWidget {
  final Ride ride;

  const _RideDetailContent({required this.ride});

  @override
  State<_RideDetailContent> createState() => _RideDetailContentState();
}

class _RideDetailContentState extends State<_RideDetailContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant _RideDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldStatus = oldWidget.ride.status;
    final newStatus = widget.ride.status;

    if (oldStatus != RideStatus.completed &&
        newStatus == RideStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showPointsInputIfNeeded(widget.ride);
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showPointsInputIfNeeded(Ride ride) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final isDriver = ride.isDriver(user.uid);
    final isRider = ride.isRider(user.uid);

    if (isDriver && ride.hasDriverPoints) return;
    if (isRider && ride.hasRiderPoints) return;
    if (!isDriver && !isRider) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PointsInputSheet(
        isDriver: isDriver,
        onSubmit: (points) async {
          final rideProvider = context.read<RideProvider>();
          await rideProvider.logPoints(
            rideId: ride.id,
            points: points,
            isDriver: isDriver,
          );
          if (mounted) {
            SnackbarHelper.showSuccess(context, 'Points logged!');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final isRider = ride.isRider(user.uid);
    final isDriver = ride.isDriver(user.uid);

    return Column(
      children: [
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status header
                    Center(
                        child:
                            RideStatusBadge(status: ride.status, large: true)),
                    const SizedBox(height: 24),

                    // Route card
                    _buildRouteCard(ride),
                    const SizedBox(height: 16),

                    // Details card
                    _buildDetailsCard(ride),

                    // Points card (completed rides)
                    if (ride.status == RideStatus.completed &&
                        (ride.hasDriverPoints || ride.hasRiderPoints)) ...[
                      const SizedBox(height: 12),
                      _buildPointsCard(ride),
                    ],
                    const SizedBox(height: 16),

                    // Rider info
                    _buildPersonCard(
                      context,
                      label: 'Rider',
                      name: ride.riderName,
                      avatar: ride.riderAvatar,
                      uid: ride.riderUid,
                      isCurrentUser: isRider,
                    ),

                    // Driver info (only shown after confirmation)
                    if (ride.hasDriver) ...[
                      const SizedBox(height: 12),
                      _buildPersonCard(
                        context,
                        label: 'Driver',
                        name: ride.driverName!,
                        avatar: ride.driverAvatar!,
                        uid: ride.driverUid!,
                        isCurrentUser: isDriver,
                      ),
                    ],

                    // Offers section (rider viewing OPEN ride with offers)
                    if (isRider && ride.status == RideStatus.open) ...[
                      const SizedBox(height: 16),
                      _buildOffersSection(context, ride),
                    ],

                    // Driver's own offer status (driver viewing OPEN ride)
                    if (!isRider && ride.status == RideStatus.open) ...[
                      const SizedBox(height: 16),
                      _buildMyOfferSection(context, ride, user.uid),
                    ],

                    // Cancel info
                    if (ride.status == RideStatus.cancelled &&
                        ride.cancelReason != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.error.withValues(alpha: 0.08),
                              AppColors.error.withValues(alpha: 0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.info_outline,
                                  color: AppColors.error, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Cancellation Reason',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.error,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ride.cancelReason!,
                                    style: TextStyle(
                                      color: AppColors.error
                                          .withValues(alpha: 0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // Action buttons
        _buildActionBar(context, ride, user.uid, isRider, isDriver),
      ],
    );
  }

  Widget _buildRouteCard(Ride ride) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6B1420), AppColors.rowanBrown],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.rowanBrown.withValues(alpha: 0.4),
                      AppColors.rowanGold.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
              Icon(Icons.location_on_rounded,
                  size: 18, color: AppColors.rowanGold),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PICKUP',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.rowanBrown.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ride.pickupArea,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
                if (ride.pickupAddress != null) ...[
                  Text(
                    ride.pickupAddress!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.subtitleText,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'DESTINATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.rowanGold.withValues(alpha: 0.8),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ride.destination,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Ride ride) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _detailItem(
            Icons.schedule_rounded,
            'Time',
            DateHelpers.formatPickupLabel(ride.pickupDatetime),
            AppColors.rowanBrown,
          ),
          _divider(),
          _detailItem(
            ride.isUrgent
                ? Icons.bolt_rounded
                : Icons.priority_high_rounded,
            'Priority',
            ride.isUrgent ? 'Urgent' : 'Standard',
            ride.isUrgent ? AppColors.error : AppColors.subtitleText,
          ),
          if (ride.createdAt != null) ...[
            _divider(),
            _detailItem(
              Icons.access_time,
              'Posted',
              DateHelpers.formatRelative(ride.createdAt!),
              AppColors.subtitleText,
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.grey.shade100,
    );
  }

  Widget _detailItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.lightText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(Ride ride) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (ride.hasDriverPoints)
            _detailItem(
              Icons.emoji_events_rounded,
              'Driver Pts',
              '${ride.driverPoints}',
              AppColors.rowanGold,
            ),
          if (ride.hasDriverPoints && ride.hasRiderPoints) _divider(),
          if (ride.hasRiderPoints)
            _detailItem(
              Icons.toll_rounded,
              'Rider Pts',
              '${ride.riderPoints}',
              AppColors.info,
            ),
        ],
      ),
    );
  }

  Widget _buildPersonCard(
    BuildContext context, {
    required String label,
    required String name,
    required String avatar,
    required String uid,
    required bool isCurrentUser,
  }) {
    return GestureDetector(
      onTap: isCurrentUser
          ? null
          : () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PublicProfileScreen(userId: uid),
                ),
              );
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            AvatarWidget(
              avatarId: avatar,
              size: AvatarSize.medium,
              showRing: true,
              isDriver: label == 'Driver',
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.rowanBrown.withValues(alpha: 0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCurrentUser ? '$name (You)' : name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
            ),
            if (!isCurrentUser)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.rowanBrown.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.rowanBrown,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    Ride ride,
    String myUid,
    bool isRider,
    bool isDriver,
  ) {
    final actions = <Widget>[];

    switch (ride.status) {
      case RideStatus.open:
        if (isRider) {
          actions.add(_actionButton(
            context,
            'Edit',
            Icons.edit_rounded,
            AppColors.info,
            () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditRideScreen(rideId: ride.id),
                ),
              );
            },
          ));
          actions.add(const SizedBox(width: 12));
          actions.add(_actionButton(
            context,
            'Cancel',
            Icons.close_rounded,
            AppColors.error,
            () => _showCancelDialog(context, ride, myUid),
          ));
        } else {
          // Driver: show "Offer to Drive" button (offer status shown in body)
          actions.add(Expanded(
            child: StreamBuilder<RideOffer?>(
              stream: context.read<RideProvider>().myOfferStream(ride.id, myUid),
              builder: (context, snap) {
                final offer = snap.data;

                // Already offered — keep chat access visible in action bar.
                if (offer != null) {
                  return SizedBox(
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () => _openThreadChat(context, ride.id, offer),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text(
                        'Open Chat',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.rowanBrown,
                        side: BorderSide(
                          color: AppColors.rowanBrown.withValues(alpha: 0.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _driverCreateOffer(context, ride),
                      icon: const Icon(Icons.local_taxi_rounded),
                      label: const Text(
                        'Offer to Drive',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ));
        }
        break;

      case RideStatus.accepted:
        actions.add(_actionButton(
          context,
          'Chat',
          Icons.chat_rounded,
          AppColors.rowanBrown,
          () => _openChat(context, ride),
        ));
        actions.add(const SizedBox(width: 12));

        if (isDriver) {
          actions.add(Expanded(
            child: SizedBox(
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning,
                      AppColors.warning.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _startRide(context, ride),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(
                    'Start Ride',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ));
        }
        actions.add(const SizedBox(width: 12));
        actions.add(_actionButton(
          context,
          'Cancel',
          Icons.close_rounded,
          AppColors.error,
          () => _showCancelDialog(context, ride, myUid),
        ));
        break;

      case RideStatus.inProgress:
        actions.add(_actionButton(
          context,
          'Chat',
          Icons.chat_rounded,
          AppColors.rowanBrown,
          () => _openChat(context, ride),
        ));
        actions.add(const SizedBox(width: 12));
        if (isDriver) {
          actions.add(Expanded(
            child: SizedBox(
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.success, Color(0xFF43A047)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _completeRide(context, ride),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text(
                    'Complete',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ));
        }
        break;

      case RideStatus.completed:
        // Points button (if not yet logged)
        final needsPoints = (isRider && !ride.hasRiderPoints) ||
            (isDriver && !ride.hasDriverPoints);
        if (needsPoints) {
          actions.add(_actionButton(
            context,
            'Points',
            Icons.toll_rounded,
            AppColors.rowanGold,
            () => _showPointsInputIfNeeded(ride),
          ));
        }
        final canRate = (isRider && !ride.riderRated) ||
            (isDriver && !ride.driverRated);
        if (canRate) {
          if (actions.isNotEmpty) actions.add(const SizedBox(width: 12));
          actions.add(Expanded(
            child: SizedBox(
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.rowanGold, Color(0xFFFFD54F)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.rowanGold.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _rateRide(context, ride, myUid, isRider),
                  icon: const Icon(Icons.star_rounded),
                  label: const Text(
                    'Rate This Ride',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: AppColors.darkText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ));
        }
        if (ride.hasDriver) {
          if (actions.isNotEmpty) actions.add(const SizedBox(width: 12));
          actions.add(_actionButton(
            context,
            'Chat',
            Icons.chat_rounded,
            AppColors.rowanBrown,
            () => _openChat(context, ride),
          ));
        }
        if (isRider) {
          if (actions.isNotEmpty) actions.add(const SizedBox(width: 12));
          actions.add(_actionButton(
            context,
            'Re-book',
            Icons.replay_rounded,
            AppColors.info,
            () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateRideScreen(
                    initialPickup: ride.pickupArea,
                    initialDestination: ride.destination,
                  ),
                ),
              );
            },
          ));
        }
        if (actions.isNotEmpty) actions.add(const SizedBox(width: 12));
        actions.add(_actionButton(
          context,
          'Share',
          Icons.share_rounded,
          AppColors.subtitleText,
          () => _shareRide(context, ride),
        ));
        break;

      case RideStatus.cancelled:
        break;
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(children: actions),
    );
  }

  Widget _actionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 66,
        height: 54,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Offers Section (Rider View) ─────────────────────────────────

  Widget _buildOffersSection(BuildContext context, Ride ride) {
    final rideProvider = context.read<RideProvider>();

    return StreamBuilder<List<RideOffer>>(
      stream: rideProvider.offersStream(ride.id),
      builder: (context, snapshot) {
        final offers = (snapshot.data ?? [])
            .where((o) => o.isActive || o.isConfirmed)
            .toList();

        if (offers.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                Icon(Icons.people_outline_rounded,
                    size: 32, color: AppColors.lightText),
                const SizedBox(height: 8),
                Text(
                  'Waiting for driver offers...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.subtitleText,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'DRIVER OFFERS (${offers.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.rowanBrown.withAlpha(128),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...offers.map((offer) => OfferCard(
                  offer: offer,
                  isRider: true,
                  onChat: () => _openThreadChat(context, ride.id, offer),
                  onSelect: () =>
                      _riderSelectDriver(context, ride.id, offer),
                  onViewProfile: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PublicProfileScreen(userId: offer.driverUid),
                      ),
                    );
                  },
                )),
          ],
        );
      },
    );
  }

  // ─── Driver's Own Offer Status ──────────────────────────────────

  Widget _buildMyOfferSection(
      BuildContext context, Ride ride, String myUid) {
    final rideProvider = context.read<RideProvider>();

    return StreamBuilder<RideOffer?>(
      stream: rideProvider.myOfferStream(ride.id, myUid),
      builder: (context, snapshot) {
        final offer = snapshot.data;

        if (offer == null) {
          // No offer yet — show "Offer to Drive" in action bar instead
          return const SizedBox.shrink();
        }

        return OfferCard(
          offer: offer,
          isRider: false,
          onWithdraw: () => _driverWithdrawOffer(context, ride),
          onConfirm: () => _driverConfirmOffer(context, ride),
          onChat: () => _openThreadChat(context, ride.id, offer),
        );
      },
    );
  }

  // ─── Chat ───────────────────────────────────────────────────────

  void _openChat(BuildContext context, Ride ride) {
    final auth = context.read<AuthProvider>();
    final myUid = auth.currentUser?.uid ?? '';
    final otherUid = ride.riderUid == myUid ? ride.driverUid : ride.riderUid;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          rideId: ride.id,
          otherUserId: otherUid ?? ride.riderUid,
          threadDriverUid: ride.driverUid,
        ),
      ),
    );
  }

  void _openThreadChat(
      BuildContext context, String rideId, RideOffer offer) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          rideId: rideId,
          otherUserId: offer.driverUid,
          threadDriverUid: offer.driverUid,
        ),
      ),
    );
  }

  // ─── Offer Actions ──────────────────────────────────────────────

  Future<void> _riderSelectDriver(
      BuildContext context, String rideId, RideOffer offer) async {
    HapticFeedback.mediumImpact();
    final rideProvider = context.read<RideProvider>();
    await rideProvider.riderConfirmOffer(
        rideId, offer.driverUid, offer.driverName);
    if (context.mounted) {
      SnackbarHelper.showSuccess(
          context, 'Selected ${offer.driverName}. Waiting for confirmation.');
    }
  }

  Future<void> _driverWithdrawOffer(
      BuildContext context, Ride ride) async {
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthProvider>();
    final rideProvider = context.read<RideProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    await rideProvider.withdrawOffer(ride.id, user);
    if (context.mounted) {
      SnackbarHelper.showInfo(context, 'Offer withdrawn');
    }
  }

  Future<void> _driverConfirmOffer(
      BuildContext context, Ride ride) async {
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthProvider>();
    final rideProvider = context.read<RideProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final success = await rideProvider.driverConfirmOffer(ride.id, user);
    if (context.mounted) {
      if (success) {
        SnackbarHelper.showSuccess(context, 'Ride confirmed!');
      } else {
        SnackbarHelper.showError(
          context,
          rideProvider.error ??
              'Could not confirm. The ride may have changed.',
        );
      }
    }
  }

  Future<void> _driverCreateOffer(
      BuildContext context, Ride ride) async {
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthProvider>();
    final rideProvider = context.read<RideProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final success = await rideProvider.createOffer(ride.id, user);
    if (context.mounted) {
      if (success) {
        SnackbarHelper.showSuccess(context, 'Offer sent!');
      } else {
        SnackbarHelper.showError(
          context,
          rideProvider.error ??
              'Could not send offer. You may have already offered.',
        );
      }
    }
  }

  Future<void> _startRide(BuildContext context, Ride ride) async {
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthProvider>();
    final rideProvider = context.read<RideProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    await rideProvider.startRide(ride.id, user);
    if (context.mounted) {
      SnackbarHelper.showSuccess(context, 'Ride started!');
    }
  }

  Future<void> _completeRide(BuildContext context, Ride ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Complete Ride?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Mark this ride as completed?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Yet'),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.success, Color(0xFF43A047)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Complete'),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      HapticFeedback.mediumImpact();
      final auth = context.read<AuthProvider>();
      final rideProvider = context.read<RideProvider>();
      await rideProvider.completeRide(ride.id, auth.currentUser!);
      if (context.mounted) {
        SnackbarHelper.showSuccess(
            context, 'Ride completed! Don\'t forget to rate.');
      }
    }
  }

  void _showCancelDialog(BuildContext context, Ride ride, String myUid) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Cancel Ride?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel?'),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                HapticFeedback.mediumImpact();
                final rideProvider = context.read<RideProvider>();
                final auth = context.read<AuthProvider>();
                await rideProvider.cancelRide(
                  ride.id,
                  auth.currentUser!,
                  reasonController.text.trim().isEmpty
                      ? null
                      : reasonController.text.trim(),
                );
                if (context.mounted) {
                  SnackbarHelper.showInfo(context, 'Ride cancelled');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel Ride'),
            ),
          ),
        ],
      ),
    );
  }

  void _shareRide(BuildContext context, Ride ride) {
    final time = DateHelpers.formatPickupLabel(ride.pickupDatetime);
    final text =
        'Need a ride from ${ride.pickupArea} to ${ride.destination} on $time! '
        'Check out Campus Ride — the Rowan student rideshare app.';
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    SnackbarHelper.showSuccess(context, 'Ride info copied to clipboard!');
  }

  void _rateRide(
    BuildContext context,
    Ride ride,
    String myUid,
    bool isRider,
  ) {
    HapticFeedback.lightImpact();
    final otherUid = isRider ? ride.driverUid! : ride.riderUid;
    final otherName = isRider ? ride.driverName! : ride.riderName;
    final otherAvatar = isRider ? ride.driverAvatar! : ride.riderAvatar;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RateRideScreen(
          rideId: ride.id,
          reviewedUid: otherUid,
          reviewedName: otherName,
          reviewedAvatar: otherAvatar,
          isRiderRating: isRider,
        ),
      ),
    );
  }
}
