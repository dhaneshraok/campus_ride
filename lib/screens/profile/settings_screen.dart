import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/ride_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../../services/seed_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/profile/profile_header.dart';
import 'edit_profile_screen.dart';
import '../rides/ride_history_screen.dart';
import '../safety/emergency_screen.dart';
import 'fuel_log_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showDevTools = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rideProvider = context.watch<RideProvider>();
    final user = auth.currentUser;

    if (user == null) return const SizedBox.shrink();

    final completedRides = rideProvider.allMyRides
        .where((r) => r.status == RideStatus.completed)
        .length;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile header card
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.cardShadow,
              ),
              child: ProfileHeader(user: user, rideCount: completedRides),
            ),
            const SizedBox(height: 24),

            // Main menu
            _menuCard([
              _menuItem(
                Icons.edit_rounded,
                'Edit Profile',
                'Update your info',
                onTap: () => _navigate(const EditProfileScreen()),
              ),
              _menuDivider(),
              _menuItem(
                Icons.history_rounded,
                'Ride History',
                'View past rides',
                onTap: () => _navigate(const RideHistoryScreen()),
              ),
              if (user.isDriver) ...[
                _menuDivider(),
                _menuItem(
                  Icons.local_gas_station_rounded,
                  'Fuel Log',
                  'Track fuel expenses',
                  onTap: () => _navigate(const FuelLogScreen()),
                ),
              ],
              _menuDivider(),
              _menuItem(
                Icons.emergency_rounded,
                'Emergency Info',
                'Safety contacts',
                onTap: () => _navigate(const EmergencyScreen()),
              ),
            ]),
            const SizedBox(height: 16),

            // Dev tools — hidden behind long-press on "About"
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showDevTools
                  ? Column(
                      children: [
                        _menuCard([
                          _menuItem(
                            Icons.data_object_rounded,
                            'Load Test Data',
                            'Seed sample data for testing',
                            onTap: () => _seedData(),
                            iconColor: AppColors.info,
                          ),
                          _menuDivider(),
                          _menuItem(
                            Icons.delete_sweep_rounded,
                            'Clear Test Data',
                            'Remove seeded data',
                            onTap: () => _clearData(),
                            iconColor: AppColors.warning,
                          ),
                        ]),
                        const SizedBox(height: 16),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // About & sign out
            _menuCard([
              _menuItem(
                Icons.info_outline_rounded,
                'About Campus Ride',
                'Version 1.0.0',
                onTap: () {},
                onLongPress: () {
                  HapticFeedback.heavyImpact();
                  setState(() => _showDevTools = !_showDevTools);
                  SnackbarHelper.showInfo(
                    context,
                    _showDevTools
                        ? 'Developer tools enabled'
                        : 'Developer tools hidden',
                  );
                },
              ),
              _menuDivider(),
              _menuItem(
                Icons.logout_rounded,
                'Sign Out',
                'See you later!',
                onTap: () => _signOut(),
                isDestructive: true,
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _navigate(Widget screen) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _menuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(children: children),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool isDestructive = false,
    Color? iconColor,
  }) {
    final color =
        isDestructive ? AppColors.error : (iconColor ?? AppColors.rowanBrown);
    return ListTile(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: onLongPress,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withAlpha(25),
              color.withAlpha(13),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: isDestructive ? AppColors.error : AppColors.darkText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.subtitleText,
        ),
      ),
      trailing: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey.shade300,
          size: 18,
        ),
      ),
    );
  }

  Widget _menuDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: Colors.grey.shade100),
    );
  }

  Future<void> _seedData() async {
    try {
      SnackbarHelper.showInfo(context, 'Loading test data...');
      await SeedService().seedAll();
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Test data loaded!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to load test data');
      }
    }
  }

  Future<void> _clearData() async {
    try {
      SnackbarHelper.showInfo(context, 'Clearing test data...');
      await SeedService().clearAll();
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Test data cleared!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to clear test data');
      }
    }
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Sign Out?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Are you sure you want to sign out?'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                HapticFeedback.mediumImpact();
                context.read<AuthProvider>().signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }
}
