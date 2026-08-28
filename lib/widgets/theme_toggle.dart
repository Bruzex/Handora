import 'package:flutter/material.dart';
import '../theme/palette.dart';

/// Sun/Moon toggle switch for dark mode.
class ThemeToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const ThemeToggle({super.key, required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 76, height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: dark ? AppColors.ink700 : AppColors.ink200),
          color: dark ? AppColors.ink800 : Colors.white,
        ),
        child: Stack(children: [
          // Sliding knob
          AnimatedAlign(
            alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(
                color: AppColors.saffron600,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Icons
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            Icon(Icons.light_mode_rounded, size: 20,
              color: isDark ? AppColors.ink500 : Colors.white),
            Icon(Icons.dark_mode_rounded, size: 20,
              color: isDark ? Colors.white : AppColors.ink500),
          ]),
        ]),
      ),
    );
  }
}
