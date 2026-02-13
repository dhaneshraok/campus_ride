import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../../constants/ride_status.dart';
import '../../models/fuel_entry_model.dart';
import '../../services/fuel_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/ride/ride_card.dart';
import 'ride_detail_screen.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: const Text(
            'Ride History',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.rowanBrown.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                onTap: (_) => HapticFeedback.selectionClick(),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.rowanBrown,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B1420), AppColors.rowanBrown],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.rowanBrown.withAlpha(64),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(10),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'As Rider'),
                  Tab(text: 'As Driver'),
                ],
              ),
            ),
          ),
        ),
        body: Consumer2<AuthProvider, RideProvider>(
          builder: (context, auth, rideProvider, _) {
            final allRides = rideProvider.allMyRides;
            final riderRides = rideProvider.myRiderRides;
            final driverRides = rideProvider.myDriverRides;

            return Column(
              children: [
                // Summary header
                if (allRides.isNotEmpty)
                  _SummaryHeader(
                    rides: allRides,
                    uid: auth.currentUser!.uid,
                  ),

                // Tab views
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildRideList(context, allRides),
                      _buildRideList(context, riderRides),
                      _buildRideList(context, driverRides),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRideList(BuildContext context, List<Ride> rides) {
    if (rides.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'No Rides Yet',
        subtitle: 'Your ride history will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        return RideCard(
          ride: ride,
          animationIndex: index,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RideDetailScreen(rideId: ride.id),
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final List<Ride> rides;
  final String uid;
  final FuelService _fuelService = FuelService();

  _SummaryHeader({required this.rides, required this.uid});

  @override
  Widget build(BuildContext context) {
    final completed =
        rides.where((r) => r.status == RideStatus.completed).toList();
    final totalRides = completed.length;

    int pointsGained = 0;
    for (final r in completed) {
      if (r.riderUid == uid && r.riderPoints != null) {
        pointsGained += r.riderPoints!;
      }
      if (r.driverUid == uid && r.driverPoints != null) {
        pointsGained += r.driverPoints!;
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B1420), AppColors.rowanBrown],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.rowanBrown.withAlpha(50),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryStat(
            icon: Icons.directions_car_rounded,
            value: '$totalRides',
            label: 'Total Rides',
          ),
          Container(
            width: 1,
            height: 28,
            color: Colors.white.withAlpha(30),
          ),
          _SummaryStat(
            icon: Icons.star_rounded,
            value: '$pointsGained',
            label: 'Points',
          ),
          Container(
            width: 1,
            height: 28,
            color: Colors.white.withAlpha(30),
          ),
          StreamBuilder<List<FuelEntry>>(
            stream: _fuelService.entriesStream(uid),
            builder: (context, snapshot) {
              final total = (snapshot.data ?? [])
                  .fold(0.0, (sum, e) => sum + e.amount);
              return _SummaryStat(
                icon: Icons.local_gas_station_rounded,
                value: '\$${total.toStringAsFixed(0)}',
                label: 'Fuel Spent',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryStat({
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
            fontSize: 16,
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
