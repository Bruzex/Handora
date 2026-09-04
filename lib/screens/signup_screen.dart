import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_state.dart';
import '../theme/palette.dart';
import 'email_login_screen.dart';

class SignUpScreen extends StatefulWidget {
  static const String routeName = '/signup';

  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    // Validation
    if (fullName.isEmpty) {
      setState(() {
        _errorMessage =
            'Please enter your full name\nकृपया अपना पूरा नाम दर्ज करें';
      });
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage =
            'Please enter a valid email\nकृपया एक वैध ईमेल दर्ज करें';
      });
      return;
    }

    if (phone.length != 10) {
      setState(() {
        _errorMessage =
            'Please enter a valid 10-digit mobile number\nकृपया 10 अंकों का वैध मोबाइल नंबर दर्ज करें';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage =
            'Password must be at least 6 characters\nपासवर्ड कम से कम 6 अक्षर का होना चाहिए';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': '+91$phone',
        },
      );

      if (!mounted) return;

      context.read<AppState>().loginFromSession();
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Something went wrong. Please try again.\nकुछ गड़बड़ हो गई। कृपया पुनः प्रयास करें।';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceIvory,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top App Bar ──
            _buildTopBar(),

            // ── Scrollable Content ──
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 14),

                    // Logo
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowColor,
                              blurRadius: 20,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/Icon.png',
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Headings
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            'Create Account',
                            style: TextStyle(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 26,
                              fontFamily: 'Inter',
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'नया खाता बनाएं',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Subtitle
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Enter your details to register your artisan shop',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant.withAlpha(200),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'अपनी दुकान पंजीकृत करने के लिए विवरण दर्ज करें',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant.withAlpha(180),
                              fontWeight: FontWeight.w400,
                              fontSize: 13,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Full Name ──
                    _buildInputField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      icon: Icons.person_outline_rounded,
                      hintText: 'Enter your full name (पूरा नाम)',
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _emailFocusNode.requestFocus(),
                    ),

                    const SizedBox(height: 12),

                    // ── Email ──
                    _buildInputField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      icon: Icons.email_outlined,
                      hintText: 'Enter your email (ईमेल)',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _phoneFocusNode.requestFocus(),
                    ),

                    const SizedBox(height: 12),

                    // ── Phone Number with +91 ──
                    _buildPhoneField(),

                    const SizedBox(height: 12),

                    // ── Password ──
                    _buildInputField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      icon: Icons.lock_outline_rounded,
                      hintText: 'Create a password (पासवर्ड बनाएं)',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleSignUp(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.onSurfaceVariant,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBA1A1A).withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFBA1A1A),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Sign Up Button (Saffron Gradient) ──
                    _buildSignUpButton(),

                    const SizedBox(height: 16),

                    // ── Already have an account? Log in ──
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant.withAlpha(200),
                              fontSize: 14,
                              fontFamily: 'Inter',
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Pop to email login or replace if coming from login
                              Navigator.pushReplacementNamed(
                                  context, EmailLoginScreen.routeName);
                            },
                            child: const Text(
                              'Log in',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ── Hindi subtitle ──
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'पहले से खाता है? ',
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant.withAlpha(160),
                              fontSize: 13,
                              fontFamily: 'Inter',
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                  context, EmailLoginScreen.routeName);
                            },
                            child: const Text(
                              'लॉगिन करें',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Terms & Privacy footer ──
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant.withAlpha(180),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              height: 1.5,
                            ),
                            children: const [
                              TextSpan(
                                  text:
                                      'By signing up, you agree to Handora\'s '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(text: '\n& '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar with Back Button and Title ──
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withAlpha(80),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: AppColors.onSurface,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'Handora',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                fontFamily: 'Inter',
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button width
        ],
      ),
    );
  }

  // ── Reusable Input Field ──
  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceDim,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        inputFormatters: inputFormatters,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
          fontFamily: 'Inter',
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            size: 22,
            color: AppColors.onSurfaceVariant,
          ),
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.onSurfaceVariant.withAlpha(150),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            fontFamily: 'Inter',
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // ── Phone Field with +91 prefix ──
  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceDim,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Phone icon
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Icon(
              Icons.phone_outlined,
              size: 22,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          // +91 prefix
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Text(
              '+91',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withAlpha(200),
                fontFamily: 'Inter',
              ),
            ),
          ),
          // Text Input
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passwordFocusNode.requestFocus(),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
                fontFamily: 'Inter',
                letterSpacing: 0.5,
              ),
              decoration: InputDecoration(
                hintText: '10-digit mobile number (मोबाइल नंबर)',
                hintStyle: TextStyle(
                  color: AppColors.onSurfaceVariant.withAlpha(150),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Inter',
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sign Up Button with Gradient ──
  Widget _buildSignUpButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFFEB660B), Color(0xFFD45800)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x339F4200),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
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
            : const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sign Up & Register Shop',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'खाता बनाएं और आगे बढ़ें',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
