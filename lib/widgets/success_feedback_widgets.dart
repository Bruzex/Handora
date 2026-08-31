import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/palette.dart';

/// Animated success icon with scaling spring bounce, glowing concentric rings,
/// and subtle celebratory particle bursts.
class SuccessCheckAnimation extends StatefulWidget {
  final double size;
  final Color primaryColor;
  final Color glowColor;
  final IconData icon;

  const SuccessCheckAnimation({
    super.key,
    this.size = 72.0,
    this.primaryColor = AppColors.green600,
    this.glowColor = const Color(0x3316A34A),
    this.icon = Icons.check_rounded,
  });

  @override
  State<SuccessCheckAnimation> createState() => _SuccessCheckAnimationState();
}

class _SuccessCheckAnimationState extends State<SuccessCheckAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  late final Animation<double> _scaleAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );

  late final Animation<double> _ringAnimation = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
  );

  late final Animation<double> _particleAnimation = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
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
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            progress: _particleAnimation.value,
            color: widget.primaryColor,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer expanding aura ring
              Transform.scale(
                scale: 1.0 + 0.35 * _ringAnimation.value,
                child: Container(
                  width: widget.size + 24,
                  height: widget.size + 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.glowColor.withAlpha(
                      ((1.0 - _ringAnimation.value) * 90).round().clamp(0, 255),
                    ),
                  ),
                ),
              ),

              // Main spring-bouncing icon circle
              Transform.scale(
                scale: _scaleAnimation.value.clamp(0.0, 1.2),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withAlpha(90),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: widget.size * 0.54,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final count = 8;
    final maxDistance = size.width * 0.75;
    final distance = maxDistance * progress;
    final alpha = ((1.0 - progress) * 220).round().clamp(0, 255);
    final paint = Paint()
      ..color = color.withAlpha(alpha)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final angle = (2 * math.pi / count) * i;
      final offset = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );
      final radius = (3.5 * (1.0 - progress * 0.5)).clamp(1.0, 4.0);
      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Visual row displaying Before ➔ After changes with clear highlighting.
class BeforeAfterDiffRow extends StatelessWidget {
  final String label;
  final String oldValue;
  final String newValue;
  final bool isDark;

  const BeforeAfterDiffRow({
    super.key,
    required this.label,
    required this.oldValue,
    required this.newValue,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.ink800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.ink700 : AppColors.saffron200,
        ),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.ink500,
            ),
          ),
          // Old value (muted strikethrough)
          Flexible(
            child: Text(
              oldValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                decoration: TextDecoration.lineThrough,
                color: isDark ? Colors.white38 : AppColors.ink500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: AppColors.saffron600,
          ),
          const SizedBox(width: 8),
          // New updated value (highlighted)
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.green50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.green600.withAlpha(60)),
              ),
              child: Text(
                newValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
