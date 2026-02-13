import 'package:flutter/material.dart';
import '../../constants/avatar_data.dart';
import '../../constants/app_colors.dart';

enum AvatarSize { small, medium, large, xlarge }

class AvatarWidget extends StatelessWidget {
  final String avatarId;
  final AvatarSize size;
  final bool showRing;
  final bool isDriver;

  const AvatarWidget({
    super.key,
    required this.avatarId,
    this.size = AvatarSize.medium,
    this.showRing = false,
    this.isDriver = false,
  });

  double get _diameter {
    switch (size) {
      case AvatarSize.small:
        return 28;
      case AvatarSize.medium:
        return 48;
      case AvatarSize.large:
        return 96;
      case AvatarSize.xlarge:
        return 110;
    }
  }

  double get _iconSize {
    switch (size) {
      case AvatarSize.small:
        return 14;
      case AvatarSize.medium:
        return 22;
      case AvatarSize.large:
        return 44;
      case AvatarSize.xlarge:
        return 50;
    }
  }

  double get _ringWidth {
    switch (size) {
      case AvatarSize.small:
        return 1.5;
      case AvatarSize.medium:
        return 2.5;
      case AvatarSize.large:
        return 3.5;
      case AvatarSize.xlarge:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalized = AvatarCollection.normalizeAvatarId(avatarId);
    final avatarData = AvatarCollection.getById(normalized);

    Widget avatar = avatarData != null
        ? _buildStyledAvatar(avatarData)
        : _buildFallbackAvatar();

    if (showRing) {
      return _wrapWithRing(avatar);
    }
    return avatar;
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: _diameter,
      height: _diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.rowanBrown.withAlpha(25),
            AppColors.rowanGold.withAlpha(15),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: _iconSize,
          color: AppColors.rowanBrown,
        ),
      ),
    );
  }

  Widget _buildStyledAvatar(AvatarData data) {
    return Container(
      width: _diameter,
      height: _diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [data.primaryColor, data.primaryColor.withAlpha(180)],
        ),
        boxShadow: [
          BoxShadow(
            color: data.primaryColor.withAlpha(60),
            blurRadius: size == AvatarSize.large || size == AvatarSize.xlarge
                ? 16
                : 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: data.secondaryColor.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle inner glow
          Container(
            width: _diameter * 0.7,
            height: _diameter * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [data.secondaryColor.withAlpha(50), Colors.transparent],
              ),
            ),
          ),
          // Icon
          Text(data.emoji, style: TextStyle(fontSize: _iconSize + 6)),
        ],
      ),
    );
  }

  Widget _wrapWithRing(Widget child) {
    final ringColor = isDriver ? AppColors.rowanGold : AppColors.rowanBrown;
    final ringColorLight = isDriver
        ? AppColors.rowanGoldLight
        : AppColors.rowanBrownLight;

    return Container(
      padding: EdgeInsets.all(_ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ringColor, ringColorLight],
        ),
        boxShadow: [
          BoxShadow(
            color: ringColor.withAlpha(50),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
