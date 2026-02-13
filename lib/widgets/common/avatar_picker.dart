import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../constants/avatar_data.dart';
import 'avatar_widget.dart';

class AvatarPicker extends StatelessWidget {
  final String selectedAvatar;
  final ValueChanged<String> onAvatarSelected;
  final bool isDriver;

  const AvatarPicker({
    super.key,
    required this.selectedAvatar,
    required this.onAvatarSelected,
    this.isDriver = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDriver) {
      return _buildGrid(AvatarCollection.riderAvatars);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Campus'),
        const SizedBox(height: 8),
        _buildGrid(AvatarCollection.riderAvatars),
        const SizedBox(height: 16),
        _buildSectionTitle('Drivers'),
        const SizedBox(height: 8),
        _buildGrid(AvatarCollection.driverAvatars),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.subtitleText,
      ),
    );
  }

  Widget _buildGrid(List<AvatarData> avatars) {
    final rows = (avatars.length / 4).ceil();
    final height = rows * 100.0 + 8;

    return SizedBox(
      height: height,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: avatars.length,
        itemBuilder: (context, index) {
          final avatar = avatars[index];
          final isSelected = avatar.id == selectedAvatar;
          return _AvatarGridItem(
            avatar: avatar,
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.lightImpact();
              onAvatarSelected(avatar.id);
            },
          );
        },
      ),
    );
  }
}

class _AvatarGridItem extends StatefulWidget {
  final AvatarData avatar;
  final bool isSelected;
  final VoidCallback onTap;

  const _AvatarGridItem({
    required this.avatar,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AvatarGridItem> createState() => _AvatarGridItemState();
}

class _AvatarGridItemState extends State<_AvatarGridItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      lowerBound: 0.0,
      upperBound: 0.1,
    );
  }

  @override
  void didUpdateWidget(_AvatarGridItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _scaleController.forward().then((_) => _scaleController.reverse());
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + _scaleController.value,
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.all(widget.isSelected ? 3 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.isSelected ? AppColors.goldGradient : null,
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.rowanGold.withAlpha(60),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: AvatarWidget(
                avatarId: widget.avatar.id,
                size: AvatarSize.medium,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.avatar.label.split(' ').first,
              style: TextStyle(
                fontSize: 10,
                fontWeight: widget.isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: widget.isSelected
                    ? AppColors.darkText
                    : AppColors.subtitleText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
