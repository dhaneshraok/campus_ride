import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../models/ride_offer_model.dart';
import '../../models/message_model.dart';
import '../../providers/ride_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/empty_state.dart';
import 'chat_screen.dart';

/// Shows all driver threads for a ride (rider's view).
/// Each thread is a driver who offered on this ride.
class RideThreadsScreen extends StatelessWidget {
  final Ride ride;

  const RideThreadsScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final rideProvider = context.watch<RideProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driver Offers',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${ride.pickupArea} → ${ride.destination}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.subtitleText,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<RideOffer>>(
        stream: rideProvider.offersStream(ride.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppColors.rowanBrown.withAlpha(128),
                  strokeWidth: 2.5,
                  strokeCap: StrokeCap.round,
                ),
              ),
            );
          }

          final offers = (snapshot.data ?? [])
              .where((o) => o.isActive || o.isConfirmed)
              .toList();

          if (offers.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No Offers Yet',
              subtitle: 'When drivers offer to drive,\nthey will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: offers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _ThreadItem(
                rideId: ride.id,
                offer: offers[index],
                animationIndex: index,
              );
            },
          );
        },
      ),
    );
  }
}

class _ThreadItem extends StatefulWidget {
  final String rideId;
  final RideOffer offer;
  final int animationIndex;

  const _ThreadItem({
    required this.rideId,
    required this.offer,
    this.animationIndex = 0,
  });

  @override
  State<_ThreadItem> createState() => _ThreadItemState();
}

class _ThreadItemState extends State<_ThreadItem>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  ChatMessage? _latestMessage;
  bool _pressed = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _loadLatestMessage();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    Future.delayed(
      Duration(milliseconds: 60 * widget.animationIndex),
      () {
        if (mounted) _animController.forward();
      },
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestMessage() async {
    final msg = await _chatService.getLatestThreadMessage(
      widget.rideId,
      widget.offer.driverUid,
    );
    if (mounted) setState(() => _latestMessage = msg);
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;

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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  rideId: widget.rideId,
                  otherUserId: offer.driverUid,
                  threadDriverUid: offer.driverUid,
                ),
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _pressed
                  ? AppColors.rowanBrown.withAlpha(8)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: offer.isRiderConfirmed
                    ? AppColors.rowanGold.withAlpha(100)
                    : Colors.grey.withAlpha(30),
                width: offer.isRiderConfirmed ? 1.5 : 1,
              ),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                AvatarWidget(
                  avatarId: offer.driverAvatar,
                  size: AvatarSize.medium,
                  showRing: true,
                  isDriver: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              offer.driverName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.darkText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusChip(offer),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _latestMessage?.text ?? 'No messages yet',
                        style: TextStyle(
                          fontSize: 13,
                          color: _latestMessage != null
                              ? AppColors.subtitleText
                              : AppColors.lightText,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[300],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(RideOffer offer) {
    String label;
    Color color;

    if (offer.isPending) {
      label = 'Pending';
      color = AppColors.info;
    } else if (offer.isRiderConfirmed) {
      label = 'Selected';
      color = AppColors.rowanGold;
    } else if (offer.isConfirmed) {
      label = 'Confirmed';
      color = AppColors.success;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
