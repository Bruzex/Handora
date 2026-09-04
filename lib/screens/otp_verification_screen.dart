import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../providers/app_state.dart';
import '../theme/palette.dart';

class OtpVerificationScreen extends StatefulWidget {
  static const String routeName = '/otp';
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late AnimationController _pulseController;

  Timer? _countdownTimer;
  int _secondsRemaining = 30;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (_) => TextEditingController());
    _focusNodes = List.generate(4, (_) => FocusNode());

    // Tactile pulsing animation for hero SMS icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _startCountdown();

    // Autofocus first input box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
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

  void _handleResendOtp() {
    if (_secondsRemaining > 0) return;
    _startCountdown();
    final isHi = context.read<AppState>().language == Language.hi;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isHi
              ? 'ओटीपी पुनः भेजा गया: ${widget.phoneNumber}'
              : 'OTP resent to ${widget.phoneNumber}',
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleVerify() {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 4) {
      final isHi = context.read<AppState>().language == Language.hi;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHi
                ? 'कृपया पूरा 4-अंकों का ओटीपी दर्ज करें'
                : 'Please enter complete 4-digit OTP',
          ),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isVerifying = false);

      _showSuccessDialog();
    });
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Verification Success',
      barrierColor: Colors.black.withAlpha(160),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
      pageBuilder: (ctx, anim1, anim2) {
        final app = context.read<AppState>();
        final isHi = app.language == Language.hi;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Floating Confetti Particle Layer
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ConfettiPainter(),
                ),
              ),
            ),

            // Modal Card
            Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.86,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Green Checkmark Icon Badge
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.green50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.green600.withAlpha(80),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.green600,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Title
                    Text(
                      isHi ? 'सत्यापन सफल!' : 'Verification Successful!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      isHi
                          ? 'आपका मोबाइल नंबर ${widget.phoneNumber} सफलतापूर्वक प्रमाणित हो गया है।'
                          : 'Your phone number ${widget.phoneNumber} has been authenticated.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Primary CTA: Go to Dashboard
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop(); // Close dialog
                          app.login(); // Authenticate in AppState
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/',
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isHi ? 'डैशबोर्ड पर जाएं' : 'Go to Dashboard',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Secondary: Back to Login
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        isHi ? 'लॉगिन पर वापस जाएं' : 'Back to Login',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
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
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(
          isHi ? 'ओटीपी सत्यापन' : 'OTP Verification',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // Hero Context: Tactile Saffron Message Icon with Pulse
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ripple pulse aura
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
                            // Main Circular Orange Container
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

                        // "OTP sent to"
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

                        // Phone Number Headline
                        Text(
                          widget.phoneNumber,
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            letterSpacing: 0.5,
                            fontFamily: 'Inter',
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Hindi Subtitle
                        Text(
                          'ओटीपी ${widget.phoneNumber} पर भेजा गया',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant.withAlpha(180),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 4 High-Contrast Responsive OTP Input Boxes
                  _buildOtpInputBoxes(),

                  const Spacer(),
                  const SizedBox(height: 20),

                  // Sticky Bottom Section: Resend Logic & CTA
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
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _secondsRemaining > 0
                                  ? AppColors.primary
                                  : AppColors.primaryContainer,
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

                  // Primary CTA: Verify & Proceed ->
                  _buildVerifyButton(isHi),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInputBoxes() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final hasFocus = _focusNodes[index].hasFocus;
            final isFilled = _controllers[index].text.isNotEmpty;

            return Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 64, maxHeight: 64),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasFocus || isFilled
                        ? AppColors.primary
                        : AppColors.surfaceDim,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: hasFocus
                          ? const Color(0x269F4200)
                          : AppColors.shadowColor,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontFamily: 'Inter',
                    ),
                    cursorColor: AppColors.primary,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      setState(() {});
                      if (value.isNotEmpty && index < 3) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }

                      // If all 4 are filled, trigger auto-verify
                      final allFilled = _controllers.every((c) => c.text.isNotEmpty);
                      if (allFilled) {
                        _handleVerify();
                      }
                    },
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildVerifyButton(bool isHi) {
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
        onPressed: _isVerifying ? null : _handleVerify,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isVerifying
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
                    isHi ? 'सत्यापित करें और आगे बढ़ें' : 'Verify & Proceed',
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
    );
  }
}

/// Custom painter for festive floating celebration confetti particles
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final confetti = [
      {'x': size.width * 0.18, 'y': size.height * 0.22, 'w': 6.0, 'h': 12.0, 'c': const Color(0xFF22C55E), 'rot': 0.4},
      {'x': size.width * 0.25, 'y': size.height * 0.16, 'w': 8.0, 'h': 6.0, 'c': const Color(0xFFF97316), 'rot': -0.6},
      {'x': size.width * 0.35, 'y': size.height * 0.26, 'w': 10.0, 'h': 4.0, 'c': const Color(0xFFEAB308), 'rot': 0.8},
      {'x': size.width * 0.45, 'y': size.height * 0.14, 'w': 6.0, 'h': 10.0, 'c': const Color(0xFF10B981), 'rot': -0.3},
      {'x': size.width * 0.60, 'y': size.height * 0.20, 'w': 8.0, 'h': 8.0, 'c': const Color(0xFFFF7722), 'rot': 0.5},
      {'x': size.width * 0.72, 'y': size.height * 0.15, 'w': 5.0, 'h': 12.0, 'c': const Color(0xFF22C55E), 'rot': -0.7},
      {'x': size.width * 0.82, 'y': size.height * 0.24, 'w': 9.0, 'h': 5.0, 'c': const Color(0xFFEA580C), 'rot': 0.9},
      {'x': size.width * 0.20, 'y': size.height * 0.32, 'w': 7.0, 'h': 7.0, 'c': const Color(0xFFFB923C), 'rot': -0.2},
      {'x': size.width * 0.80, 'y': size.height * 0.34, 'w': 6.0, 'h': 10.0, 'c': const Color(0xFF34D399), 'rot': 0.6},
      {'x': size.width * 0.52, 'y': size.height * 0.30, 'w': 5.0, 'h': 8.0, 'c': const Color(0xFF16A34A), 'rot': -0.5},
      {'x': size.width * 0.30, 'y': size.height * 0.40, 'w': 8.0, 'h': 4.0, 'c': const Color(0xFF9F4200), 'rot': 0.3},
      {'x': size.width * 0.70, 'y': size.height * 0.42, 'w': 7.0, 'h': 6.0, 'c': const Color(0xFFFFB692), 'rot': -0.8},
    ];

    for (final p in confetti) {
      final paint = Paint()
        ..color = (p['c'] as Color).withAlpha(220)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p['x'] as double, p['y'] as double);
      canvas.rotate(p['rot'] as double);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p['w'] as double,
            height: p['h'] as double,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
