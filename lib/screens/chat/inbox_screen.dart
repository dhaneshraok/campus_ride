import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/ride_status.dart';
import '../../models/message_model.dart';
import '../../models/ride_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../../services/chat_service.dart';
import '../../utils/date_helpers.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/ride/ride_status_badge.dart';
import '../rides/ride_detail_screen.dart';
import 'chat_screen.dart';
import 'ride_threads_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final myUid = auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inbox',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      body: _InboxContent(myUid: myUid),
    );
  }
}

class _InboxContent extends StatelessWidget {
  final String myUid;

  const _InboxContent({required this.myUid});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final rideProvider = context.watch<RideProvider>();
    final rides = List<Ride>.from(rideProvider.allMyRides);

    // Sort by most recently updated for inbox ordering
    rides.sort(
      (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(2000)).compareTo(
        a.updatedAt ?? a.createdAt ?? DateTime(2000),
      ),
    );

    if (rides.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No Conversations',
        subtitle:
            'When you create or accept a ride,\nconversations will appear here.',
      );
    }

    return RefreshIndicator(
      color: AppColors.rowanBrown,
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        final uid = auth.currentUser?.uid;
        if (uid != null) rideProvider.initStreams(uid);
        await Future.delayed(const Duration(milliseconds: 450));
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: rides.length,
        separatorBuilder: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(height: 1, color: Colors.grey[100]),
        ),
        itemBuilder: (context, index) {
          final ride = rides[index];
          return _InboxItem(ride: ride, myUid: myUid, animationIndex: index);
        },
      ),
    );
  }
}

class _InboxItem extends StatefulWidget {
  final Ride ride;
  final String myUid;
  final int animationIndex;

  const _InboxItem({
    required this.ride,
    required this.myUid,
    this.animationIndex = 0,
  });

  @override
  State<_InboxItem> createState() => _InboxItemState();
}

class _InboxItemState extends State<_InboxItem>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  bool _pressed = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    Future.delayed(Duration(milliseconds: 60 * widget.animationIndex), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRider = widget.ride.riderUid == widget.myUid;
    final isOpen = widget.ride.status == RideStatus.open;
    final otherName = isRider
        ? (isOpen && widget.ride.hasOffers
              ? '${widget.ride.offerCount} driver offer${widget.ride.offerCount > 1 ? 's' : ''}'
              : (widget.ride.driverName ?? 'Waiting for offers'))
        : widget.ride.riderName;
    final otherAvatar = isRider
        ? (widget.ride.driverAvatar ?? 'car_mcqueen')
        : widget.ride.riderAvatar;
    final otherUid = isRider
        ? (widget.ride.driverUid ?? widget.ride.riderUid)
        : widget.ride.riderUid;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onLongPress: _deleteConversation,
          onTap: () {
            HapticFeedback.lightImpact();
            final isRider = widget.ride.riderUid == widget.myUid;

            if (isRider &&
                widget.ride.status == RideStatus.open &&
                widget.ride.hasOffers) {
              // Rider with offers: open threads screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RideThreadsScreen(ride: widget.ride),
                ),
              );
            } else if (isRider &&
                widget.ride.status == RideStatus.open &&
                !widget.ride.hasOffers) {
              // Rider with no offers: open ride detail
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RideDetailScreen(rideId: widget.ride.id),
                ),
              );
            } else {
              // Confirmed rides: open chat with thread filter
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    rideId: widget.ride.id,
                    otherUserId: otherUid,
                    threadDriverUid: widget.ride.driverUid,
                  ),
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            color: _pressed
                ? AppColors.rowanBrown.withAlpha(10)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                // Avatar
                AvatarWidget(
                  avatarId: otherAvatar,
                  size: AvatarSize.medium,
                  showRing: true,
                  isDriver: !isRider,
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.darkText,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.ride.updatedAt != null ||
                              widget.ride.createdAt != null)
                            Text(
                              DateHelpers.formatRelative(
                                widget.ride.updatedAt ?? widget.ride.createdAt!,
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.lightText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: _buildPreviewRow()),
                          const SizedBox(width: 8),
                          RideStatusBadge(status: widget.ride.status),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteConversation();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.error,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text('Delete Chat'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Conversation?'),
        content: const Text(
          'This will permanently delete messages for this ride chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final deleted = await _chatService.deleteConversation(
      rideId: widget.ride.id,
    );
    if (!mounted) return;

    SnackbarHelper.showInfo(
      context,
      deleted == 0 ? 'No messages to delete' : 'Deleted $deleted message(s)',
    );
  }

  Widget _buildPreviewRow() {
    return StreamBuilder<ChatMessage?>(
      stream: _chatService.latestMessageStream(widget.ride.id),
      builder: (_, snapshot) {
        final msg = snapshot.data;
        if (msg == null) {
          return Row(
            children: [
              const Icon(
                Icons.route_rounded,
                size: 14,
                color: AppColors.subtitleText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${widget.ride.pickupArea} → ${widget.ride.destination}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.subtitleText,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }

        final prefix = msg.isSystem ? 'System: ' : '';
        return Row(
          children: [
            Icon(
              msg.isSystem
                  ? Icons.info_outline_rounded
                  : Icons.chat_bubble_outline_rounded,
              size: 14,
              color: AppColors.subtitleText,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$prefix${msg.text}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.subtitleText,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
