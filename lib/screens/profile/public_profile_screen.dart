import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/review_model.dart';
import '../../services/user_service.dart';
import '../../services/review_service.dart';
import '../../services/stats_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/review_card.dart';
import '../safety/report_user_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  int _rideCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRideCount();
  }

  Future<void> _loadRideCount() async {
    final count = await StatsService().completedRideCount(widget.userId);
    if (mounted) setState(() => _rideCount = count);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report') {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ReportUserScreen(reportedUid: widget.userId),
                  ),
                );
              }
            },
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text(
                      'Report User',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<AppUser?>(
        stream: UserService().userStream(widget.userId),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.rowanGold),
            );
          }

          final user = userSnap.data;
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      ProfileHeader(
                          user: user, rideCount: _rideCount),
                      const SizedBox(height: 14),
                      // Verified Student badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.success.withAlpha(25),
                              AppColors.success.withAlpha(10),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.success.withAlpha(40),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Verified Rowan Student',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Reviews section header
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.rowanBrown.withAlpha(25),
                            AppColors.rowanGold.withAlpha(15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.rate_review_rounded,
                          size: 18, color: AppColors.rowanBrown),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Reviews',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Reviews stream
                StreamBuilder<List<Review>>(
                  stream: ReviewService().reviewsStream(widget.userId),
                  builder: (context, reviewSnap) {
                    if (reviewSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.rowanGold,
                        ),
                      );
                    }

                    final reviews = reviewSnap.data ?? [];

                    if (reviews.isEmpty) {
                      return const EmptyState(
                        icon: Icons.rate_review_outlined,
                        title: 'No Reviews Yet',
                        subtitle:
                            'Reviews will appear after\ncompleted rides.',
                      );
                    }

                    return Column(
                      children: reviews
                          .map((r) => ReviewCard(review: r))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
