import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                color: Colors.black.withAlpha(77),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppColors.elevatedShadow,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BrandedLoader(),
                        const SizedBox(height: 18),
                        if (message != null)
                          Text(
                            message!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.bodyText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BrandedLoader extends StatefulWidget {
  @override
  State<_BrandedLoader> createState() => _BrandedLoaderState();
}

class _BrandedLoaderState extends State<_BrandedLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 50,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _CarLoaderPainter(_controller.value),
          );
        },
      ),
    );
  }
}

class _CarLoaderPainter extends CustomPainter {
  final double progress;

  _CarLoaderPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final roadY = size.height * 0.7;

    // Road line
    final roadPaint = Paint()
      ..color = AppColors.rowanBrown.withAlpha(30)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, roadY),
      Offset(size.width, roadY),
      roadPaint,
    );

    // Dashed center line
    final dashPaint = Paint()
      ..color = AppColors.rowanGold.withAlpha(80)
      ..strokeWidth = 1.5;

    for (double x = 0; x < size.width; x += 12) {
      final dashOffset = (progress * 24) % 12;
      canvas.drawLine(
        Offset(x - dashOffset, roadY - 6),
        Offset(x + 6 - dashOffset, roadY - 6),
        dashPaint,
      );
    }

    // Car body
    final carX = progress * (size.width + 30) - 15;
    final bounce = (1 - (2 * progress - 1).abs()) * 2;
    final carY = roadY - 16 - bounce;

    final carPaint = Paint()..color = AppColors.rowanBrown;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(carX - 12, carY, 24, 10),
      const Radius.circular(3),
    );
    canvas.drawRRect(bodyRect, carPaint);

    // Car top
    final topPaint = Paint()..color = AppColors.rowanBrown.withAlpha(200);
    final topRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(carX - 6, carY - 7, 14, 8),
      const Radius.circular(3),
    );
    canvas.drawRRect(topRect, topPaint);

    // Wheels
    final wheelPaint = Paint()..color = AppColors.darkText;
    canvas.drawCircle(Offset(carX - 7, carY + 10), 3, wheelPaint);
    canvas.drawCircle(Offset(carX + 7, carY + 10), 3, wheelPaint);

    // Headlight
    final lightPaint = Paint()..color = AppColors.rowanGold;
    canvas.drawCircle(Offset(carX + 12, carY + 3), 1.5, lightPaint);
  }

  @override
  bool shouldRepaint(_CarLoaderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

