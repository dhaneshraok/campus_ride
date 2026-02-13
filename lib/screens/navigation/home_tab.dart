import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../../providers/notification_provider.dart';
import '../../constants/ride_status.dart';
import '../../models/fuel_entry_model.dart';
import '../../services/fuel_service.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/ride/ride_card.dart';
import '../../utils/snackbar_helper.dart';
import '../rides/create_ride_screen.dart';
import '../rides/ride_detail_screen.dart';
import '../rides/browse_rides_screen.dart';
import '../rides/edit_ride_screen.dart';
import '../chat/inbox_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _staleCheckQueued = false;
  bool _isShowingStaleDialog = false;
  final Set<String> _handledStaleRideIds = <String>{};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rideProvider = context.watch<RideProvider>();
    final user = auth.currentUser;

    if (user == null) return const SizedBox.shrink();
    _queueStaleRideCheck(user, rideProvider);

    // Count only the user's completed rides
    final completedRides = rideProvider.allMyRides
        .where((r) => r.status == RideStatus.completed)
        .toList();
    final totalRides = completedRides.length;

    // Aggregate points from completed rides
    int pointsGained = 0;
    for (final r in completedRides) {
      if (r.riderUid == user.uid && r.riderPoints != null) {
        pointsGained += r.riderPoints!;
      }
      if (r.driverUid == user.uid && r.driverPoints != null) {
        pointsGained += r.driverPoints!;
      }
    }

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.rowanBrown,
        backgroundColor: Colors.white,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          rideProvider.initStreams(user.uid);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Custom gradient app bar
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: AppColors.rowanBrown,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.brownDarkGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Avatar with ring
                              AvatarWidget(
                                avatarId: user.avatar,
                                size: AvatarSize.medium,
                                showRing: true,
                                isDriver: user.isDriver,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hey, ${user.fullName.split(' ').first}!',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Where are you heading today?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withAlpha(165),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Notification bell
                              Consumer<NotificationProvider>(
                                builder: (_, notif, _) => GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const InboxScreen(),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(30),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          Icons.notifications_outlined,
                                          color: Colors.white.withAlpha(230),
                                          size: 22,
                                        ),
                                      ),
                                      if (notif.unreadCount > 0)
                                        Positioned(
                                          right: -2,
                                          top: -2,
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: AppColors.rowanGold,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.rowanBrown,
                                                width: 2,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${notif.unreadCount > 9 ? '9+' : notif.unreadCount}',
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.darkText,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          // Eco stats strip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withAlpha(15),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                _EcoStat(
                                  icon: Icons.directions_car_rounded,
                                  value: '$totalRides',
                                  label: 'Rides',
                                ),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.white.withAlpha(30),
                                ),
                                _EcoStat(
                                  icon: Icons.star_rounded,
                                  value: '$pointsGained',
                                  label: 'Points',
                                ),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.white.withAlpha(30),
                                ),
                                _FuelStat(uid: user.uid),
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

            // Content
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick actions
                        _buildQuickActions(context),
                        const SizedBox(height: 28),

                        // Active rides
                        _buildSectionHeader(
                          'Your Active Rides',
                          rideProvider.activeRides.length,
                          Icons.flash_on_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildActiveRides(
                            context, rideProvider.activeRides),
                        const SizedBox(height: 28),

                        // Available rides for drivers
                        if (user.isDriver) ...[
                          _buildSectionHeader(
                            'Available Rides',
                            rideProvider.openRides.length,
                            Icons.local_taxi_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildAvailableRides(
                            context,
                            rideProvider.openRides,
                            user.uid,
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _queueStaleRideCheck(AppUser user, RideProvider rideProvider) {
    if (_staleCheckQueued || _isShowingStaleDialog) return;
    _staleCheckQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _staleCheckQueued = false;
      if (!mounted || _isShowingStaleDialog) return;

      Ride? staleRide;
      for (final ride in rideProvider.myRiderRides) {
        if (ride.isStaleOpenRide && !_handledStaleRideIds.contains(ride.id)) {
          staleRide = ride;
          break;
        }
      }

      final rideToHandle = staleRide;
      if (rideToHandle == null) return;

      _handledStaleRideIds.add(rideToHandle.id);
      _isShowingStaleDialog = true;

      final action = await showDialog<_StaleRideAction>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ride Time Passed'),
          content: Text(
            'Your ride to ${rideToHandle.destination} has passed its pickup time. '
            'You can edit the date/time or remove this ride.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, _StaleRideAction.keep),
              child: const Text('Keep for now'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, _StaleRideAction.edit),
              child: const Text('Edit Time'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, _StaleRideAction.remove),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      _isShowingStaleDialog = false;
      if (!mounted || action == null) return;

      if (action == _StaleRideAction.edit) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditRideScreen(rideId: rideToHandle.id),
          ),
        );
        return;
      }

      if (action == _StaleRideAction.remove) {
        try {
          await rideProvider.cancelRide(
            rideToHandle.id,
            user,
            'Pickup time passed before ride started.',
          );
          if (mounted) {
            SnackbarHelper.showSuccess(
              context,
              'Expired ride removed from active rides.',
            );
          }
        } catch (_) {
          if (mounted) {
            SnackbarHelper.showError(context, 'Failed to remove expired ride');
          }
        }
      }
    });
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.hail_rounded,
            title: 'Need a Ride',
            subtitle: 'Post a request',
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6B1420), AppColors.rowanBrown],
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CreateRideScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.search_rounded,
            title: 'Browse Rides',
            subtitle: 'Help a student',
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BrowseRidesScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.rowanBrown.withAlpha(20),
                AppColors.rowanBrown.withAlpha(10),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.rowanBrown),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.darkText,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 8),
        if (count > 0)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.rowanBrown.withAlpha(30),
                  AppColors.rowanBrown.withAlpha(15),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.rowanBrown,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveRides(BuildContext context, List<Ride> rides) {
    if (rides.isEmpty) {
      return const EmptyState(
        icon: Icons.directions_car_outlined,
        title: 'No Active Rides',
        subtitle:
            'Create a ride request or accept\na ride to get started.',
      );
    }

    return Column(
      children: rides.asMap().entries.map((entry) {
        return RideCard(
          ride: entry.value,
          animationIndex: entry.key,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RideDetailScreen(rideId: entry.value.id),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildAvailableRides(
      BuildContext context, List<Ride> rides, String myUid) {
    final otherRides = rides.take(5).toList();

    if (otherRides.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.explore_off_rounded,
                  size: 32, color: AppColors.lightText),
              SizedBox(height: 8),
              Text(
                'No rides available right now',
                style: TextStyle(
                  color: AppColors.subtitleText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: otherRides.asMap().entries.map((entry) {
        return RideCard(
          ride: entry.value,
          animationIndex: entry.key,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RideDetailScreen(rideId: entry.value.id),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

enum _StaleRideAction { keep, edit, remove }

class _EcoStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _EcoStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.rowanGold),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withAlpha(150),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FuelStat extends StatelessWidget {
  final String uid;
  final FuelService _fuelService = FuelService();

  _FuelStat({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FuelEntry>>(
      stream: _fuelService.entriesStream(uid),
      builder: (context, snapshot) {
        final total = (snapshot.data ?? [])
            .fold(0.0, (sum, e) => sum + e.amount);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_gas_station_rounded,
                size: 16, color: AppColors.rowanGold),
            const SizedBox(height: 4),
            Text(
              '\$${total.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'Fuel Spent',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withAlpha(150),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(38),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(46),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withAlpha(190),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
