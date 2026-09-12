import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/strings.dart';
import '../theme/palette.dart';

/// Gramin Modernism Language Selector Button & Bottom Sheet.
/// Supports switching between English, Hindi, Marathi, Tamil, Telugu, Gujarati, and Bengali.
class LanguageSelector extends StatelessWidget {
  final Language currentLanguage;
  final ValueChanged<Language> onLanguageChange;
  final bool compact;

  const LanguageSelector({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChange,
    this.compact = false,
  });

  void _showLanguageBottomSheet(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.ink900 : Colors.white;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: dark ? AppColors.ink700 : AppColors.ink200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.saffron50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.saffron200),
                        ),
                        child: const Icon(
                          Icons.translate_rounded,
                          color: AppColors.saffron600,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'भाषा चुनें / Select Language',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: dark ? Colors.white : AppColors.ink900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select your preferred language for Handora',
                            style: TextStyle(
                              fontSize: 13,
                              color: dark ? Colors.white60 : AppColors.ink500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Scrollable Language options list
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...Language.values.map((lang) {
                            final isSelected = lang == currentLanguage;
                            final subtitle = switch (lang) {
                              Language.en => 'English',
                              Language.hi => 'Hindi',
                              Language.mr => 'Marathi',
                              Language.ta => 'Tamil',
                              Language.te => 'Telugu',
                              Language.gu => 'Gujarati',
                              Language.bn => 'Bengali',
                            };

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Material(
                                color: isSelected
                                    ? (dark ? AppColors.saffron600.withAlpha(40) : AppColors.saffron50)
                                    : (dark ? AppColors.ink800 : AppColors.surfaceIvory),
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    onLanguageChange(lang);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.saffron600
                                            : (dark ? AppColors.ink700 : AppColors.ink200.withAlpha(150)),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Language badge
                                        Container(
                                          width: 42,
                                          height: 42,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.saffron600 : (dark ? AppColors.ink700 : Colors.white),
                                            borderRadius: BorderRadius.circular(12),
                                            border: isSelected ? null : Border.all(color: AppColors.saffron200),
                                          ),
                                          child: Text(
                                            lang.shortLabel,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: isSelected ? Colors.white : AppColors.saffron700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Language Name
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                lang.displayName,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                  color: isSelected
                                                      ? AppColors.saffron700
                                                      : (dark ? Colors.white : AppColors.ink900),
                                                ),
                                              ),
                                              Text(
                                                subtitle,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: dark ? Colors.white60 : AppColors.ink500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Selection indicator
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: AppColors.saffron600,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check_rounded,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          )
                                        else
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 20,
                                            color: dark ? AppColors.ink500 : AppColors.ink500,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showLanguageBottomSheet(context),
      child: Container(
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: dark ? AppColors.ink800 : AppColors.saffron50,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: AppColors.saffron600,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.saffron600.withAlpha(25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.translate_rounded,
              size: 16,
              color: AppColors.saffron700,
            ),
            const SizedBox(width: 6),
            Text(
              currentLanguage.shortLabel,
              style: GoogleFonts.notoSans(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w800,
                color: AppColors.saffron700,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.saffron700,
            ),
          ],
        ),
      ),
    );
  }
}
