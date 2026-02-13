import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';

class ChatInputBar extends StatefulWidget {
  final ValueChanged<String> onSend;

  const ChatInputBar({super.key, required this.onSend});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  bool _hasText = false;
  bool _showQuickReplies = true;
  late AnimationController _sendAnimController;
  late Animation<double> _sendScale;

  static const _quickReplies = [
    'On my way!',
    "I'm here!",
    'Running late',
    'Thanks!',
  ];

  @override
  void initState() {
    super.initState();
    _sendAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _sendScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sendAnimController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _sendAnimController.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    final hasText = value.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
        if (hasText) _showQuickReplies = false;
      });
      if (hasText) {
        _sendAnimController.forward();
      } else {
        _sendAnimController.reverse();
        setState(() => _showQuickReplies = true);
      }
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    widget.onSend(text);
    _controller.clear();
    setState(() {
      _hasText = false;
      _showQuickReplies = true;
    });
    _sendAnimController.reverse();
  }

  void _sendQuickReply(String text) {
    HapticFeedback.lightImpact();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppColors.bottomBarShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick reply chips
          if (_showQuickReplies)
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: _quickReplies.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _sendQuickReply(_quickReplies[index]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.rowanBrown.withAlpha(15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.rowanBrown.withAlpha(30),
                        ),
                      ),
                      child: Text(
                        _quickReplies[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.rowanBrown,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          // Input row
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: _showQuickReplies ? 4 : 10,
              bottom: MediaQuery.of(context).padding.bottom + 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _hasText
                            ? AppColors.rowanBrown.withAlpha(51)
                            : Colors.transparent,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      onChanged: _onTextChanged,
                      onSubmitted: (_) => _send(),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.darkText,
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: AppColors.lightText,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ScaleTransition(
                  scale: _sendScale,
                  child: GestureDetector(
                    onTap: _hasText ? _send : null,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF6B1420),
                            AppColors.rowanBrown,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.rowanBrown.withAlpha(77),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
