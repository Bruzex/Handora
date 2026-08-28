import 'package:flutter/material.dart';
import '../theme/palette.dart';
import '../theme/shadows.dart';

/// Reusable action card for the Help screen (WhatsApp, tutorial, phone).
class HelpCard extends StatelessWidget {
  final Widget icon;
  final Color iconBg, iconBorder, cardBorder;
  final String title, text;
  final bool emphasizeText;
  final Widget trailing;

  const HelpCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconBorder,
    required this.cardBorder,
    required this.title,
    required this.text,
    this.emphasizeText = false,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? AppColors.ink800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
          boxShadow: kCardShadow,
        ),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: iconBorder, width: 2),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3, color: dark ? Colors.white : AppColors.ink900)),
            const SizedBox(height: 2),
            Text(text, style: emphasizeText
              ? TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.saffron700)
              : const TextStyle(fontSize: 14, color: AppColors.ink500)),
          ])),
          const SizedBox(width: 12),
          trailing,
        ]),
      ),
    );
  }
}
