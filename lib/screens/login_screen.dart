import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/strings.dart';
import '../providers/app_state.dart';
import '../theme/palette.dart';
import 'email_login_screen.dart';
import 'phone_login_screen.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isGoogleLoading = false;

  @override
  Widget build(BuildContext context) {
    final isHi = context.watch<AppState>().language == Language.hi;

    return Scaffold(
      backgroundColor: AppColors.surfaceIvory,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.sm,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  16,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // App Logo (Icon.png from Desktop)
                  Center(
                    child: Image.asset(
                      'assets/images/Icon.png',
                      height: 110,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Headline & Bilingual Subtitle
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Welcome to Handora',
                          style: TextStyle(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            fontFamily: 'Inter',
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'हैंडोरा में आपका स्वागत है',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Primary: Continue with Phone (Primary for rural artisans)
                  _buildPrimaryPhoneButton(isHi),

                  const SizedBox(height: 20),

                  // OR / या Divider
                  _buildOrDivider(),

                  const SizedBox(height: 20),

                  // Continue with Email Button
                  _buildOutlinedSocialButton(
                    icon: Icons.mail_outline_rounded,
                    label: isHi
                        ? 'ईमेल से जारी रखें (Continue with Email)'
                        : 'Continue with Email',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        EmailLoginScreen.routeName,
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Continue with Google Button
                  _buildGoogleSignInButton(),

                  const Spacer(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Primary button: Continue with Phone -> opens PhoneLoginScreen
  Widget _buildPrimaryPhoneButton(bool isHi) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x339F4200),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            PhoneLoginScreen.routeName,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.phone_android_rounded,
              size: 22,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              isHi
                  ? 'फ़ोन नंबर से जारी रखें (Continue with Phone)'
                  : 'Continue with Phone',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.outlineVariant, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR / या',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant.withAlpha(200),
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.outlineVariant, thickness: 1),
        ),
      ],
    );
  }

  Widget _buildOutlinedSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surfaceContainerLowest,
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.surfaceDim, width: 1.2),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Handles the real Google Sign-In → Supabase signInWithIdToken flow.
  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;

    final app = context.read<AppState>();
    final isHi = app.language == Language.hi;

    setState(() => _isGoogleLoading = true);

    try {
      // ── 1. Trigger native Google Sign-In ──
      // TODO: Replace the serverClientId below with your Google Cloud
      //       OAuth 2.0 **Web** Client ID (the one registered in Supabase
      //       Dashboard → Authentication → Providers → Google).
      const webClientId =
          '122129827888-cgmtmmuubrdqjabq4nl9s8ij1k926g7q.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();

      // User cancelled the Google picker dialog
      if (googleUser == null) {
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('Google Sign-In did not return an ID token.');
      }

      // ── 2. Authenticate with Supabase using the Google token ──
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (!mounted) return;

      // ── 3. Update AppState and navigate to dashboard ──
      context.read<AppState>().loginFromSession();
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } on AuthException catch (e) {
      debugPrint('Google Sign-In AuthException: ${e.message}');
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHi
                ? 'Google साइन-इन विफल। कृपया पुनः प्रयास करें।\n${e.message}'
                : 'Google Sign-In failed. Please try again.\n${e.message}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHi
                ? 'Google साइन-इन में त्रुटि हुई। कृपया पुनः प्रयास करें।'
                : 'Something went wrong with Google Sign-In. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    }
  }

  Widget _buildGoogleSignInButton() {
    return OutlinedButton(
      onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surfaceContainerLowest,
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.surfaceDim, width: 1.2),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: _isGoogleLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/google_logo.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
    );
  }
}

