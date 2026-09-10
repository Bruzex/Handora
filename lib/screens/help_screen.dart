import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/data_provider.dart';
import '../theme/palette.dart';
import '../theme/shadows.dart';
import '../widgets/help_card.dart';
import '../widgets/voice_assistant_modal.dart';
import '../l10n/strings.dart';
import 'login_screen.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _openVoiceAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(140),
      builder: (_) => const VoiceAssistantModal(),
    );
  }

  void _handleLogout() {
    final app = context.read<AppState>();
    final isHi = app.language == Language.hi;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceIvory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isHi ? 'लॉग आउट करें?' : 'Log Out?',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            fontFamily: 'Inter',
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          isHi
              ? 'क्या आप वाकई लॉग आउट करना चाहते हैं?'
              : 'Are you sure you want to log out?',
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.onSurfaceVariant,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isHi ? 'रद्द करें' : 'Cancel',
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await app.signOut();
              if (!mounted) return;
              context.read<DataProvider>().clearProducts();
              Navigator.of(context).pushNamedAndRemoveUntil(
                LoginScreen.routeName,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              isHi ? 'लॉग आउट' : 'Log Out',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.strings;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isHi = app.language == Language.hi;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ── Profile Header (only when authenticated with profile data) ──
        if (app.isAuthenticated && app.userDisplayName != null) ...[
          _buildProfileHeader(app, dark),
          const SizedBox(height: 20),
        ],

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
              onTapUp: (_) {
                setState(() => _pressed = false);
                _openVoiceAssistant();
              },
              onTapCancel: () => setState(() => _pressed = false),
              child: AnimatedScale(
                scale: _pressed ? 0.95 : 1.0,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: SizedBox(
                  width: 160, height: 160,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      final t = _pulse.value;
                      return Stack(alignment: Alignment.center, children: [
                        Container(
                          width: 128 + 28 * t, height: 128 + 28 * t,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.saffron600.withAlpha((130 * (1 - t)).round()),
                              width: 2,
                            ),
                          ),
                        ),
                        Container(
                          width: 128, height: 128,
                          decoration: BoxDecoration(color: AppColors.saffron600, shape: BoxShape.circle, boxShadow: kLiftShadow),
                          child: const Icon(Icons.mic_rounded, size: 56, color: Colors.white),
                        ),
                      ]);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(s.voiceHelpTitle, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.3, color: dark ? Colors.white : AppColors.ink900)),
            const SizedBox(height: 8),
            Text(s.voiceHelpSubtitle, textAlign: TextAlign.center,
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

        // ── Logout Button ──
        if (app.isAuthenticated) ...[
          const SizedBox(height: 32),
          _buildLogoutButton(isHi),
        ],
      ]),
    );
  }

  // ── Profile Header Widget ──
  Widget _buildProfileHeader(AppState app, bool dark) {
    final initials = _getInitials(app.userDisplayName ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.ink800 : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? AppColors.ink700 : AppColors.outlineVariant.withAlpha(120),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEB660B), Color(0xFFD45800)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(50),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.userDisplayName ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : AppColors.onSurface,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (app.userEmail != null &&
                    app.userEmail != app.userDisplayName) ...[
                  const SizedBox(height: 2),
                  Text(
                    app.userEmail!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: dark ? AppColors.ink500 : AppColors.onSurfaceVariant,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else if (app.userPhone != null &&
                    app.userPhone != app.userDisplayName) ...[
                  const SizedBox(height: 2),
                  Text(
                    app.userPhone!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: dark ? AppColors.ink500 : AppColors.onSurfaceVariant,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Verified badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.green50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.green600.withAlpha(60)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 14, color: AppColors.green600),
                SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.green800,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Logout Button ──
  Widget _buildLogoutButton(bool isHi) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDC2626).withAlpha(60),
          width: 1.2,
        ),
      ),
      child: Material(
        color: const Color(0xFFFEE2E2), // Soft red background
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _handleLogout,
          borderRadius: BorderRadius.circular(14),
          splashColor: const Color(0xFFDC2626).withAlpha(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isHi ? 'लॉग आउट' : 'Log Out',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isHi ? 'Log Out' : 'लॉग आउट',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFDC2626).withAlpha(160),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    if (name.startsWith('+') || RegExp(r'^[0-9+]+$').hasMatch(name.trim())) {
      return 'H';
    }
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
