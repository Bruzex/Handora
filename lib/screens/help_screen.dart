import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/palette.dart';
import '../theme/shadows.dart';
import '../widgets/help_card.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.strings;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text.rich(TextSpan(
          text: s.supportTitle,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: dark ? Colors.white : AppColors.ink900),
          children: [
            const TextSpan(text: ' '),
            TextSpan(text: '/ ${s.supportTitleAlt}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink500)),
          ],
        )),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: dark ? AppColors.saffron600.withAlpha(20) : AppColors.saffron50,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(children: [
            GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              child: AnimatedScale(
                scale: _pressed ? 0.95 : 1.0,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: Container(
                  width: 128, height: 128,
                  decoration: BoxDecoration(color: AppColors.saffron600, shape: BoxShape.circle, boxShadow: kLiftShadow),
                  child: const Icon(Icons.mic_rounded, size: 56, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(s.askTitle, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.3, color: dark ? Colors.white : AppColors.ink900)),
            const SizedBox(height: 8),
            Text(s.askSubtext, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.6, color: dark ? AppColors.ink500 : AppColors.ink700)),
          ]),
        ),

        const SizedBox(height: 24),

        HelpCard(
          icon: const Icon(Icons.chat_rounded, size: 28, color: Color(0xFF15803D)),
          iconBg: AppColors.green50,
          iconBorder: AppColors.green600,
          cardBorder: AppColors.green600,
          title: s.whatsappHelpTitle,
          text: s.whatsappHelpText,
          trailing: const Icon(Icons.chevron_right_rounded, size: 24, color: AppColors.ink500),
        ),
        const SizedBox(height: 12),

        HelpCard(
          icon: Icon(Icons.headphones_rounded, size: 28, color: AppColors.saffron600),
          iconBg: AppColors.saffron50,
          iconBorder: AppColors.saffron200,
          cardBorder: dark ? AppColors.ink700 : AppColors.ink200,
          title: s.tutorialTitle,
          text: s.tutorialText,
          trailing: Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(color: AppColors.saffron600, shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded, size: 24, color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),

        HelpCard(
          icon: Icon(Icons.phone_rounded, size: 28, color: dark ? Colors.white : AppColors.ink900),
          iconBg: dark ? AppColors.ink800 : Colors.white,
          iconBorder: dark ? AppColors.ink700 : AppColors.ink200,
          cardBorder: dark ? AppColors.ink700 : AppColors.ink200,
          title: s.callTitle,
          text: s.callNumber,
          emphasizeText: true,
          trailing: const Icon(Icons.chevron_right_rounded, size: 24, color: AppColors.ink500),
        ),
      ]),
    );
  }
}
