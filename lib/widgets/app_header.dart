import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../theme/palette.dart';
import 'language_selector.dart';

class AppHeader extends StatelessWidget {
  final Language language;
  final ValueChanged<Language> onLanguageChange;

  const AppHeader({
    super.key,
    required this.language,
    required this.onLanguageChange,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.ink950 : Colors.white;
    final borderColor = dark ? AppColors.ink700 : AppColors.ink200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Text.rich(TextSpan(
            text: 'Hand',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: dark ? Colors.white : AppColors.ink900,
            ),
            children: [
              TextSpan(text: 'ora', style: TextStyle(color: AppColors.saffron600)),
            ],
          )),

          // Language Selector
          LanguageSelector(
            currentLanguage: language,
            onLanguageChange: onLanguageChange,
            compact: true,
          ),
        ],
      ),
    );
  }
}
