import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/chat_input_bar.dart';
import '../../widgets/common/avatar_widget.dart';
import '../profile/public_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final String rideId;
  final String otherUserId;
  final String? threadDriverUid;

  const ChatScreen({
    super.key,
    required this.rideId,
    required this.otherUserId,
    this.threadDriverUid,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  AppUser? _otherUser;
  late AnimationController _emptyAnimController;
  late Animation<double> _emptyFade;

  @override
  void initState() {
    super.initState();
    _loadOtherUser();
    _markMessageNotificationsRead();
    _emptyAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _emptyFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _emptyAnimController, curve: Curves.easeOut),
    );
    _emptyAnimController.forward();
  }

  @override
  void dispose() {
    _emptyAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadOtherUser() async {
    final user = await _userService.getUser(widget.otherUserId);
    if (mounted) setState(() => _otherUser = user);
  }

  Future<void> _markMessageNotificationsRead() async {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;
    await context.read<NotificationProvider>().markMessageNotificationsAsRead(
      uid,
      rideId: widget.rideId,
    );
  }

  Future<void> _sendMessage(String text) async {
    HapticFeedback.lightImpact();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    await _chatService.sendMessage(
      rideId: widget.rideId,
      senderUid: user.uid,
      senderName: user.fullName,
      senderAvatar: user.avatar,
      text: text,
      threadDriverUid: widget.threadDriverUid,
    );
  }

  Future<void> _deleteConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chat?'),
        content: const Text(
          'This will permanently delete messages in this conversation.',
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
      rideId: widget.rideId,
      threadDriverUid: widget.threadDriverUid,
    );
    if (!mounted) return;

    SnackbarHelper.showInfo(
      context,
      deleted == 0 ? 'No messages to delete' : 'Deleted $deleted message(s)',
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final myUid = auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF0ECE5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: AppColors.cardShadow,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                  ),
                  // User avatar
                  GestureDetector(
                    onTap: () {
                      if (_otherUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PublicProfileScreen(userId: widget.otherUserId),
                          ),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        AvatarWidget(
                          avatarId: _otherUser?.avatar ?? 'campus_owl',
                          size: AvatarSize.medium,
                          showRing: true,
                          isDriver: _otherUser?.isDriver ?? false,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _otherUser?.fullName ?? 'Loading...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkText,
                              ),
                            ),
                            if (_otherUser?.isDriver ?? false)
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_car_rounded,
                                    size: 12,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Driver',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Delete chat',
                    onPressed: _deleteConversation,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: widget.threadDriverUid != null
                  ? _chatService.threadMessagesStream(
                      widget.rideId,
                      widget.threadDriverUid!,
                    )
                  : _chatService.messagesStream(widget.rideId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: AppColors.rowanBrown.withValues(alpha: 0.5),
                        strokeWidth: 2.5,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return FadeTransition(
                    opacity: _emptyFade,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.rowanBrown.withValues(
                                alpha: 0.06,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 36,
                              color: AppColors.rowanBrown.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Say hello to start the conversation!',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.subtitleText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderUid == myUid;

                    // Check if we should show date separator
                    final showDate =
                        index == messages.length - 1 ||
                        _shouldShowDate(messages[index], messages[index + 1]);

                    return Column(
                      children: [
                        if (showDate && msg.timestamp != null)
                          _buildDateSeparator(msg.timestamp!),
                        MessageBubble(message: msg, isMe: isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input
          ChatInputBar(onSend: _sendMessage),
        ],
      ),
    );
  }

  bool _shouldShowDate(ChatMessage current, ChatMessage previous) {
    if (current.timestamp == null || previous.timestamp == null) return false;
    final cDate = current.timestamp!;
    final pDate = previous.timestamp!;
    return cDate.day != pDate.day ||
        cDate.month != pDate.month ||
        cDate.year != pDate.year;
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(date.year, date.month, date.day);

    String label;
    if (msgDate == today) {
      label = 'Today';
    } else if (msgDate == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    } else {
      label = '${date.month}/${date.day}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.subtitleText,
            ),
          ),
        ),
      ),
    );
  }
}
