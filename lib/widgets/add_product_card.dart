import 'package:flutter/material.dart';
import '../screens/capture_screen.dart';
import '../theme/palette.dart';
import '../theme/shadows.dart';

/// Big circle CTA for camera + mic on the Home screen.
class AddProductCard extends StatefulWidget {
  final String title;
  final String subtext;
  final String buttonLabel;

  const AddProductCard({
    super.key,
    required this.title,
    required this.subtext,
    required this.buttonLabel,
  });

  @override
  State<AddProductCard> createState() => _AddProductCardState();
}

class _AddProductCardState extends State<AddProductCard> {
  bool _pressed = false;

  void _openCapture(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaptureScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: dark ? AppColors.ink800 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dark ? AppColors.ink700 : AppColors.saffron100),
        boxShadow: kLiftShadow,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              _openCapture(context);
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  color: AppColors.saffron600,
                  shape: BoxShape.circle,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_rounded, size: 56, color: Colors.white),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 40, color: Colors.white38),
                    const SizedBox(width: 12),
                    const Icon(Icons.mic_rounded, size: 56, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w800, height: 1.3,
              color: dark ? Colors.white : AppColors.ink900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtext,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.ink500),
          ),
        ],
      ),
    );
  }
}
