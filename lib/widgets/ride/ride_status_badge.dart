import 'package:flutter/material.dart';
import '../../constants/ride_status.dart';

class RideStatusBadge extends StatefulWidget {
  final RideStatus status;
  final bool large;

  const RideStatusBadge({
    super.key,
    required this.status,
    this.large = false,
  });

  @override
  State<RideStatusBadge> createState() => _RideStatusBadgeState();
}

class _RideStatusBadgeState extends State<RideStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.status == RideStatus.inProgress) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(RideStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == RideStatus.inProgress) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final large = widget.large;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: status == RideStatus.inProgress ? _pulseAnim.value : 1.0,
          child: child,
        );
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: Container(
          key: ValueKey(status),
          padding: EdgeInsets.symmetric(
            horizontal: large ? 16 : 10,
            vertical: large ? 8 : 5,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                status.color.withAlpha(36),
                status.color.withAlpha(15),
              ],
            ),
            borderRadius: BorderRadius.circular(large ? 14 : 20),
            border: Border.all(
              color: status.color.withAlpha(64),
            ),
            boxShadow: large
                ? [
                    BoxShadow(
                      color: status.color.withAlpha(25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == RideStatus.inProgress) ...[
                _LiveDot(color: status.color),
                const SizedBox(width: 6),
              ] else ...[
                Icon(
                  status.icon,
                  size: large ? 18 : 14,
                  color: status.color,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                status.displayLabel,
                style: TextStyle(
                  fontSize: large ? 14 : 11,
                  fontWeight: FontWeight.w700,
                  color: status.color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated live dot indicator
class _LiveDot extends StatefulWidget {
  final Color color;

  const _LiveDot({required this.color});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withAlpha(
                  (100 * (0.5 + 0.5 * _controller.value)).round(),
                ),
                blurRadius: 4 + 4 * _controller.value,
                spreadRadius: 1 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

