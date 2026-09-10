import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/strings.dart';
import '../providers/app_state.dart';
import '../providers/data_provider.dart';
import '../theme/palette.dart';

enum PhoneStep { phone, otp }

class PhoneLoginScreen extends StatefulWidget {
  static const String routeName = '/phone-login';

  final String? initialPhoneNumber;
  final bool startAtOtp;

  const PhoneLoginScreen({
    super.key,
    this.initialPhoneNumber,
    this.startAtOtp = false,
  });

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen>
    with SingleTickerProviderStateMixin {
  late PhoneStep _step;

  // Phone controllers & state
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isSendingOtp = false;
  String? _phoneErrorMessage;

  // OTP controllers & state (6-digit OTP for Twilio / Supabase)
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;
  bool _isVerifyingOtp = false;
  String? _otpErrorMessage;

  // Resend cooldown timer
  Timer? _countdownTimer;
  int _secondsRemaining = 30;

  // Pulse animation for hero context icon
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _step = widget.startAtOtp ? PhoneStep.otp : PhoneStep.phone;

    // Clean phone number from initial argument if provided
    if (widget.initialPhoneNumber != null) {
      final clean = widget.initialPhoneNumber!
          .replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.length >= 10) {
        _phoneController.text = clean.substring(clean.length - 10);
      } else {
        _phoneController.text = clean;
      }
    }

    _otpControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (_) => FocusNode());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _phoneController.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.startAtOtp) {
      _startCountdown();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _otpFocusNodes.isNotEmpty) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _phoneFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = 30);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String _sanitizeAuthError(dynamic error, bool isHi) {
    final str = error.toString().toLowerCase();
    if (str.contains('429') ||
        str.contains('rate limit') ||
        str.contains('sms limit') ||
        str.contains('too many')) {
      return isHi
          ? 'बहुत अधिक प्रयास। कृपया थोड़ी देर बाद पुनः प्रयास करें।'
          : 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (str.contains('invalid') &&
        (str.contains('token') ||
            str.contains('otp') ||
            str.contains('code'))) {
      return isHi
          ? 'अमान्य या समाप्त ओटीपी कोड। कृपया सही 6-अंकों का कोड दर्ज करें।'
          : 'Invalid or expired OTP code. Please enter the correct 6-digit code.';
    }
    if (str.contains('expired')) {
      return isHi
          ? 'ओटीपी की समय सीमा समाप्त हो गई है। कृपया नया ओटीपी भेजें।'
          : 'OTP has expired. Please tap resend to get a new code.';
    }
    if (str.contains('phone') &&
        (str.contains('invalid') || str.contains('format'))) {
      return isHi
          ? 'अमान्य मोबाइल नंबर प्रारूप। कृपया 10 अंकों का वैध नंबर दर्ज करें।'
          : 'Invalid phone number format. Please enter a valid 10-digit number.';
    }
    if (str.contains('network') ||
        str.contains('socket') ||
        str.contains('connection') ||
        str.contains('clientexception')) {
      return isHi
          ? 'नेटवर्क त्रुटि। कृपया अपना इंटरनेट कनेक्शन जांचें।'
          : 'Network error. Please check your internet connection.';
    }
    return isHi
        ? 'सत्यापन विफल रहा। कृपया पुनः प्रयास करें।'
        : 'Authentication failed. Please try again.';
  }

  /// Sends OTP via Supabase Auth + Twilio SMS
  Future<void> _handleSendOtp() async {
    final rawNumber = _phoneController.text.trim();
    final isHi = context.read<AppState>().language == Language.hi;

    if (rawNumber.length != 10) {
      setState(() {
        _phoneErrorMessage = isHi
            ? 'कृपया 10 अंकों का वैध मोबाइल नंबर दर्ज करें'
            : 'Please enter a valid 10-digit mobile number';
      });
      return;
    }

    setState(() {
      _phoneErrorMessage = null;
      _isSendingOtp = true;
    });

    final e164Phone = '+91$rawNumber';

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        phone: e164Phone,
      );

      if (!mounted) return;

      setState(() {
        _isSendingOtp = false;
        _step = PhoneStep.otp;
        _otpErrorMessage = null;
        for (final c in _otpControllers) {
          c.clear();
        }
      });

      _startCountdown();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _otpFocusNodes.isNotEmpty) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        _phoneErrorMessage = _sanitizeAuthError(e, isHi);
      });
    }
  }

  /// Resend OTP handler
  Future<void> _handleResendOtp() async {
    if (_secondsRemaining > 0) return;

    final rawNumber = _phoneController.text.trim();
    final isHi = context.read<AppState>().language == Language.hi;
    final e164Phone = '+91$rawNumber';

    _startCountdown();

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        phone: e164Phone,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHi
                ? 'ओटीपी पुनः भेजा गया: $e164Phone'
                : 'OTP resent to $e164Phone',
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _otpErrorMessage = _sanitizeAuthError(e, isHi);
      });
    }
  }

  /// Handles OTP input changes including paste of 6-digit code
  void _onOtpDigitChanged(int index, String value) {
    setState(() {
      _otpErrorMessage = null;
    });

    // Check if the user pasted a multi-digit code (e.g. 6 digits)
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isNotEmpty) {
        for (int i = 0; i < 6; i++) {
          if (i < digits.length) {
            _otpControllers[i].text = digits[i];
          }
        }
        final targetIndex = digits.length < 6 ? digits.length : 5;
        _otpFocusNodes[targetIndex].requestFocus();

        if (digits.length >= 6) {
          _handleVerifyOtp();
        }
        return;
      }
    }

    // Normal single-digit typing
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }

    // Auto-verify if all 6 boxes are filled
    final allFilled = _otpControllers.every((c) => c.text.isNotEmpty);
    if (allFilled) {
      _handleVerifyOtp();
    }
  }

  /// Verifies OTP via Supabase Auth
  Future<void> _handleVerifyOtp() async {
    if (_isVerifyingOtp) return;

    final otp = _otpControllers.map((c) => c.text.trim()).join();
    final isHi = context.read<AppState>().language == Language.hi;

    if (otp.length < 6) {
      setState(() {
        _otpErrorMessage = isHi
            ? 'कृपया पूरा 6-अंकों का ओटीपी दर्ज करें'
            : 'Please enter complete 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _otpErrorMessage = null;
    });

    final rawNumber = _phoneController.text.trim();
    final e164Phone = '+91$rawNumber';

    try {
      await Supabase.instance.client.auth.verifyOTP(
        phone: e164Phone,
        token: otp,
        type: OtpType.sms,
      );

      if (!mounted) return;

      // Update AppState and DataProvider
      final appState = context.read<AppState>();
      appState.loginFromSession();

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        context.read<DataProvider>().reloadForUser(userId);
      }

      setState(() => _isVerifyingOtp = false);

      // Navigate to dashboard and clear entire navigation stack
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifyingOtp = false;
        _otpErrorMessage = _sanitizeAuthError(e, isHi);
      });
    }
  }

  /// Helper to format masked phone number: +91 98****3210
  String _getMaskedPhone() {
    final raw = _phoneController.text.trim();
    if (raw.length == 10) {
      return '+91 ${raw.substring(0, 2)}****${raw.substring(6)}';
    }
    return '+91 $raw';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isHi = app.language == Language.hi;

    return Scaffold(
      backgroundColor: AppColors.surfaceIvory,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceIvory,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () {
            if (_step == PhoneStep.otp && !widget.startAtOtp) {
              setState(() {
                _step = PhoneStep.phone;
                _otpErrorMessage = null;
                _phoneErrorMessage = null;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
          tooltip: 'Back',
        ),
        title: Text(
          _step == PhoneStep.phone
              ? (isHi ? 'फ़ोन लॉगिन' : 'Phone Login')
              : (isHi ? 'ओटीपी सत्यापन' : 'OTP Verification'),
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
      ),
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
                  kToolbarHeight -
                  16,
            ),
            child: IntrinsicHeight(
              child: _step == PhoneStep.phone
                  ? _buildEnterPhoneStep(isHi)
                  : _buildEnterOtpStep(isHi),
            ),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SCREEN A: ENTER PHONE
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildEnterPhoneStep(bool isHi) {
    final hasText = _phoneController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),

        // Hero Phone Icon Container
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 18,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.phone_android_rounded,
              color: Color(0xFF5E2400),
              size: 38,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Title & Bilingual Subtitle
        Center(
          child: Column(
            children: [
              Text(
                isHi ? 'मोबाइल नंबर दर्ज करें' : 'Enter Mobile Number',
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  fontFamily: 'Inter',
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isHi
                    ? 'हम आपके नंबर पर एक 6-अंकों का ओटीपी भेजेंगे'
                    : "We'll send a 6-digit OTP verification code",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 36),

        // Input Label
        Text(
          isHi ? 'मोबाइल नंबर (Mobile Number)' : 'Mobile Number',
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
        ),

        const SizedBox(height: 10),

        // Large Phone Input Field (+91 fixed prefix)
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _phoneErrorMessage != null
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                    letterSpacing: 1.0,
                  ),
                  decoration: InputDecoration(
                    hintText: isHi ? '10-अंकों का नंबर' : '10-digit number',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9E8E84),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onSubmitted: (_) => _handleSendOtp(),
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
                    setState(() => _phoneErrorMessage = null);
                  },
                ),
            ],
          ),
        ),

        // Error message if any
        if (_phoneErrorMessage != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _phoneErrorMessage!,
              style: const TextStyle(
                color: Color(0xFFBA1A1A),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Primary "Send OTP" Button
        Container(
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
            onPressed: _isSendingOtp ? null : _handleSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSendingOtp
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isHi ? 'ओटीपी भेजें (Send OTP)' : 'Send OTP',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        ),

        const Spacer(),
        const SizedBox(height: 16),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SCREEN B: ENTER OTP (6 DIGITS)
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildEnterOtpStep(bool isHi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),

        // Tactile Hero Icon with pulsing aura
        Center(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 84 + (_pulseController.value * 16),
                        height: 84 + (_pulseController.value * 16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryContainer.withAlpha(
                            (38 * (1 - _pulseController.value)).toInt(),
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryContainer,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowColor,
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Color(0xFF5E2400),
                      size: 38,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                isHi ? 'ओटीपी भेजा गया:' : 'OTP sent to',
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  fontFamily: 'Inter',
                ),
              ),

              const SizedBox(height: 4),

              // Masked Phone Number (e.g. +91 98****3210)
              Text(
                _getMaskedPhone(),
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  letterSpacing: 0.5,
                  fontFamily: 'Inter',
                ),
              ),

              const SizedBox(height: 8),

              // "Change number" Link
              InkWell(
                onTap: () {
                  setState(() {
                    _step = PhoneStep.phone;
                    _otpErrorMessage = null;
                    for (final c in _otpControllers) {
                      c.clear();
                    }
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isHi ? 'नंबर बदलें (Change Number)' : 'Change Number',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // 6 High-Contrast OTP Input Boxes
        _build6DigitOtpBoxes(),

        if (_otpErrorMessage != null) ...[
          const SizedBox(height: 12),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _otpErrorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFBA1A1A),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],

        const Spacer(),
        const SizedBox(height: 20),

        // Resend Logic & Cooldown
        Center(
          child: Column(
            children: [
              Text(
                isHi ? 'ओटीपी नहीं मिला?' : "Didn't receive code?",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant.withAlpha(220),
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _secondsRemaining == 0 ? _handleResendOtp : null,
                child: Text(
                  _secondsRemaining > 0
                      ? (isHi
                          ? '$_secondsRemaining सेकंड में पुनः भेजें'
                          : 'Resend in ${_secondsRemaining}s')
                      : (isHi ? 'अभी पुनः भेजें (Resend OTP)' : 'Resend OTP Now'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _secondsRemaining > 0
                        ? AppColors.primary.withAlpha(160)
                        : AppColors.primary,
                    decoration: _secondsRemaining == 0
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Primary CTA: Verify & Login
        Container(
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
            onPressed: _isVerifyingOtp ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isVerifyingOtp
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isHi
                            ? 'सत्यापित करें और लॉगिन करें'
                            : 'Verify & Login',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  /// 6 Responsive OTP Input Boxes with paste support & auto-advance
  Widget _build6DigitOtpBoxes() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final hasFocus = _otpFocusNodes[index].hasFocus;
            final isFilled = _otpControllers[index].text.isNotEmpty;

            return Flexible(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 50,
                  maxHeight: 56,
                  minWidth: 40,
                  minHeight: 52,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _otpErrorMessage != null
                        ? const Color(0xFFBA1A1A)
                        : (hasFocus || isFilled
                            ? AppColors.primary
                            : AppColors.surfaceDim),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: hasFocus
                          ? const Color(0x269F4200)
                          : AppColors.shadowColor,
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontFamily: 'Inter',
                    ),
                    cursorColor: AppColors.primary,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) => _onOtpDigitChanged(index, value),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
