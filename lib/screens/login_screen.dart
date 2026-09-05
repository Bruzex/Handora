import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../providers/app_state.dart';
import '../theme/palette.dart';
import 'email_login_screen.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _handleSendOtp() {
    final rawNumber = _phoneController.text.trim();
    final app = context.read<AppState>();
    final isHi = app.language == Language.hi;

    if (rawNumber.length != 10) {
      setState(() {
        _errorMessage = isHi
            ? 'कृपया 10 अंकों का वैध मोबाइल नंबर दर्ज करें'
            : 'Please enter a valid 10-digit mobile number';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Simulate fast OTP network dispatch
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final formattedPhone = '+91 $rawNumber';
      Navigator.pushNamed(
        context,
        OtpVerificationScreen.routeName,
        arguments: {'phoneNumber': formattedPhone},
      );
    });
  }

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
                  const SizedBox(height: 12),

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
                        Text(
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
                        Text(
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

                  const SizedBox(height: 32),

                  // Input Label (Bilingual)
                  Text(
                    'Login with Mobile Number / मोबाइल नंबर से लॉगिन',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Phone Input Card Container with +91 Prefix & Clear Button
                  _buildPhoneInputField(),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFBA1A1A),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Primary Send OTP Button
                  _buildSendOtpButton(isHi),

                  const SizedBox(height: 22),

                  // OR / या Divider
                  _buildOrDivider(),

                  const SizedBox(height: 18),

                  // Continue with Email Button
                  _buildOutlinedSocialButton(
                    icon: Icons.mail_outline_rounded,
                    label: 'Continue with Email',
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



  Widget _buildPhoneInputField() {
    final hasText = _phoneController.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _errorMessage != null
              ? const Color(0xFFBA1A1A)
              : AppColors.surfaceDim,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // +91 Country Code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: const Text(
              '+91',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
          // Vertical Divider
          Container(
            width: 1,
            height: 28,
            color: AppColors.surfaceDim,
          ),
          // Text Input Field
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
                letterSpacing: 0.8,
              ),
              decoration: const InputDecoration(
                hintText: '9876543210',
                hintStyle: TextStyle(
                  color: Color(0xFF9E8E84),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          // Clear Button
          if (hasText)
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.onSurfaceVariant,
              ),
              onPressed: () {
                _phoneController.clear();
                setState(() => _errorMessage = null);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSendOtpButton(bool isHi) {
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
        onPressed: _isLoading ? null : _handleSendOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                isHi ? 'ओटीपी भेजें (Send OTP)' : 'Send OTP',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
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

  Widget _buildGoogleSignInButton() {
    return OutlinedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In initiated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
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

