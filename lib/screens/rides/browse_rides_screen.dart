import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/ride/ride_card.dart';
import 'ride_detail_screen.dart';

enum _RideFilter { all, urgent, today, tomorrow }
enum _RideSort { soonest, latest }

class BrowseRidesScreen extends StatefulWidget {
  const BrowseRidesScreen({super.key});

  @override
  State<BrowseRidesScreen> createState() => _BrowseRidesScreenState();
}

class _BrowseRidesScreenState extends State<BrowseRidesScreen> {
  _RideFilter _activeFilter = _RideFilter.all;
  _RideSort _activeSort = _RideSort.soonest;

  List<Ride> _applyFilter(List<Ride> rides) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final tomorrowEnd = todayEnd.add(const Duration(days: 1));

    switch (_activeFilter) {
      case _RideFilter.all:
        return rides;
      case _RideFilter.urgent:
        return rides.where((r) => r.isUrgent).toList();
      case _RideFilter.today:
        return rides
            .where((r) => r.pickupDatetime.isBefore(todayEnd))
            .toList();
      case _RideFilter.tomorrow:
        return rides
            .where((r) =>
                r.pickupDatetime.isAfter(todayEnd) &&
                r.pickupDatetime.isBefore(tomorrowEnd))
            .toList();
    }
  }

  List<Ride> _applySort(List<Ride> rides) {
    final sorted = List<Ride>.from(rides);
    sorted.sort(
      (a, b) => _activeSort == _RideSort.soonest
          ? a.pickupDatetime.compareTo(b.pickupDatetime)
          : b.pickupDatetime.compareTo(a.pickupDatetime),
    );
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rideProvider = context.watch<RideProvider>();
    final myUid = auth.currentUser?.uid ?? '';

    final allRides =
        rideProvider.openRides.where((r) => r.riderUid != myUid).toList();
    final rides = _applySort(_applyFilter(allRides));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(
          'Browse Rides',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.cardShadow,
              ),
              child: TextField(
                onChanged: rideProvider.setSearchQuery,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.darkText,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by location or name...',
                  hintStyle: TextStyle(
                    color: AppColors.lightText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.rowanBrown.withAlpha(128),
                    size: 22,
                  ),
                  suffixIcon: rideProvider.searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () => rideProvider.setSearchQuery(''),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.lightText,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: _RideFilter.values.map((f) {
                final isActive = f == _activeFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _activeFilter = f);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF6B1420),
                                  AppColors.rowanBrown
                                ],
                              )
                            : null,
                        color: isActive ? null : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: isActive
                            ? null
                            : Border.all(color: Colors.grey.shade200),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.rowanBrown.withAlpha(40),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (f == _RideFilter.urgent)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.bolt_rounded,
                                size: 14,
                                color:
                                    isActive ? Colors.white : AppColors.error,
                              ),
                            ),
                          Text(
                            _filterLabel(f),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? Colors.white
                                  : AppColors.subtitleText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Sort + clear controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Sort:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.subtitleText,
                  ),
                ),
                const SizedBox(width: 8),
                _sortChip(_RideSort.soonest, 'Soonest'),
                const SizedBox(width: 8),
                _sortChip(_RideSort.latest, 'Latest'),
                const Spacer(),
                if (_activeFilter != _RideFilter.all ||
                    rideProvider.searchQuery.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _activeFilter = _RideFilter.all);
                      rideProvider.setSearchQuery('');
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),

          // Results count
          if (rides.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    '${rides.length} ride${rides.length == 1 ? '' : 's'} available',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.subtitleText,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Rides list
          Expanded(
            child: rides.isEmpty
                ? const EmptyState(
                    icon: Icons.explore_off_rounded,
                    title: 'No Rides Available',
                    subtitle:
                        'There are no open ride requests right now.\nCheck back soon!',
                  )
                : RefreshIndicator(
                    color: AppColors.rowanBrown,
                    backgroundColor: Colors.white,
                    onRefresh: () async {
                      HapticFeedback.mediumImpact();
                      final uid = auth.currentUser?.uid;
                      if (uid != null) rideProvider.initStreams(uid);
                      await Future.delayed(
                          const Duration(milliseconds: 500));
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                builder: (_) =>
                                    RideDetailScreen(rideId: ride.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(_RideFilter f) {
    switch (f) {
      case _RideFilter.all:
        return 'All';
      case _RideFilter.urgent:
        return 'Urgent';
      case _RideFilter.today:
        return 'Today';
      case _RideFilter.tomorrow:
        return 'Tomorrow';
    }
  }

  Widget _sortChip(_RideSort s, String label) {
    final isActive = s == _activeSort;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeSort = s);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.rowanBrown.withAlpha(20)
              : Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.rowanBrown.withAlpha(60)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? AppColors.rowanBrown : AppColors.subtitleText,
          ),
        ),
      ),
    );
  }
}
