import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/strings.dart';
import '../providers/app_state.dart';
import '../providers/data_provider.dart';
import '../theme/palette.dart';
import '../widgets/language_selector.dart';

enum PhoneStep { phone, otp }

/// Formatter for Indian mobile numbers:
/// - Strips spaces, dashes, parentheses, and non-digit characters.
/// - Automatically strips '+91' or '91' country code prefix when user pastes or types a number with country code.
/// - Automatically strips leading '0' trunk dial prefix.
/// - Limits the input to exactly 10 digits.
class IndianPhoneInputFormatter extends TextInputFormatter {
  const IndianPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Extract all digits from the input
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // If user pasted/entered with +91 country code (12 digits starting with 91)
    if (digits.length > 10 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length > 10 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // Limit to max 10 digits
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    int selectionOffset = digits.length;
    if (newValue.selection.baseOffset >= 0 &&
        newValue.selection.baseOffset <= digits.length) {
      selectionOffset = newValue.selection.baseOffset;
    }

    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }
}

class PhoneLoginScreen extends StatefulWidget {
  static const String routeName = '/phone-login';

  final String? initialPhoneNumber;
  final bool startAtOtp;

  const PhoneLoginScreen({
    super.key,
    this.initialPhoneNumber,
    this.startAtOtp = false,
  });

  static Language _resolveLang({bool isHi = false, Language? language}) {
    if (language != null) return language;
    return isHi ? Language.hi : Language.en;
  }

  /// Sanitizes errors encountered when sending OTP (Phone Step).
  /// NEVER returns OTP verification/token error messages.
  static String sanitizeSendOtpError(
    dynamic error, {
    bool isHi = false,
    Language? language,
  }) {
    final lang = _resolveLang(isHi: isHi, language: language);
    final str = error.toString().toLowerCase();

    // Rate limiting
    if (str.contains('429') ||
        str.contains('rate limit') ||
        str.contains('sms limit') ||
        str.contains('too many') ||
        str.contains('over_sms_send_rate_limit')) {
      return switch (lang) {
        Language.hi => 'बहुत अधिक प्रयास। कृपया थोड़ी देर बाद पुनः प्रयास करें।',
        Language.mr => 'खूप जास्त प्रयत्न. कृपया थोड्या वेळाने पुन्हा प्रयत्न करा.',
        Language.ta => 'அதிக முயற்சிகள். சில நிமிடங்கள் கழித்து மீண்டும் முயற்சிக்கவும்.',
        Language.te => 'ఎక్కువ ప్రయత్నాలు. దయచేసి కొన్ని నిమిషాల తర్వాత మళ్లీ ప్రయత్నించండి.',
        Language.gu => 'ઘણા બધા પ્રયાસો. કૃપા કરીને થોડીવાર પછી ફરી પ્રયાસ કરો.',
        Language.bn => 'অতিরিক্ত প্রচেষ্টা। দয়া করে কিছুক্ষণ পরে আবার চেষ্টা করুন।',
        Language.en => 'Too many attempts. Please wait a few minutes and try again.',
      };
    }

    // Invalid phone number format from backend error
    if (str.contains('bad_phone_number') ||
        str.contains('invalid_phone') ||
        (str.contains('phone') &&
            (str.contains('format') ||
                str.contains('invalid') ||
                str.contains('bad') ||
                str.contains('not_valid')))) {
      return switch (lang) {
        Language.hi => 'अमान्य मोबाइल नंबर प्रारूप। कृपया 10 अंकों का वैध नंबर दर्ज करें।',
        Language.mr => 'अवैध मोबाईल नंबर स्वरूप. कृपया १० अंकी वैध नंबर टाका.',
        Language.ta => 'தவறான மொபைல் எண் வடிவம். சரியான 10 இலக்க எண்ணை உள்ளிடவும்.',
        Language.te => 'చెల్లని మొబైల్ నంబర్ ఫార్మాట్. దయచేసి సరైన 10 అంకెల నంబర్‌ను నమోదు చేయండి.',
        Language.gu => 'અમાન્ય મોબાઇલ નંબર ફોર્મેટ. કૃપા કરીને ૧૦ અંકનો માન્ય નંબર દાખલ કરો.',
        Language.bn => 'ভুল মোবাইল নম্বর ফরম্যাট। দয়া করে ১০ সংখ্যার সঠিক নম্বর লিখুন।',
        Language.en => 'Invalid phone number format. Please enter a valid 10-digit number.',
      };
    }

    // Network / connectivity issues
    if (str.contains('network') ||
        str.contains('socket') ||
        str.contains('connection') ||
        str.contains('clientexception') ||
        str.contains('offline') ||
        str.contains('timeout')) {
      return switch (lang) {
        Language.hi => 'नेटवर्क त्रुटि। कृपया अपना इंटरनेट कनेक्शन जांचें।',
        Language.mr => 'नेटवर्क त्रुटी. कृपया तुमचे इंटरनेट कनेक्शन तपासा.',
        Language.ta => 'பிணையப் பிழை. உங்கள் இணைய இணைப்பைச் சரிபார்க்கவும்.',
        Language.te => 'నెట్‌వర్క్ లోపం. దయచేసి మీ ఇంటర్నెట్ కనెక్షన్‌ని తనిఖీ చేయండి.',
        Language.gu => 'નેટવર્ક ભૂલ. કૃપા કરીને તમારું ઇન્ટરનેટ કનેક્શન તપાસો.',
        Language.bn => 'নেটওয়ার্ক ত্রুটি। আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন।',
        Language.en => 'Network error. Please check your internet connection.',
      };
    }

    // Fallback generic send error (Never mentions OTP code or token)
    return switch (lang) {
      Language.hi => 'ओटीपी भेजने में विफल। कृपया पुनः प्रयास करें।',
      Language.mr => 'ओटीपी पाठवण्यात अपयशी. कृपया पुन्हा प्रयत्न करा.',
      Language.ta => 'OTP அனுப்புவதில் தோல்வி. மீண்டும் முயற்சிக்கவும்.',
      Language.te => 'OTP పంపడంలో విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      Language.gu => 'ઓટીપી મોકલવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.',
      Language.bn => 'ওটিপি পাঠাতে ব্যর্থ হয়েছে। দয়া করে আবার চেষ্টা করুন।',
      Language.en => 'Failed to send OTP. Please check the number and try again.',
    };
  }

  /// Sanitizes errors encountered when verifying OTP (OTP Step).
  /// Strictly dedicated to OTP verification and token mismatch.
  static String sanitizeVerifyOtpError(
    dynamic error, {
    bool isHi = false,
    Language? language,
  }) {
    final lang = _resolveLang(isHi: isHi, language: language);
    final str = error.toString().toLowerCase();

    // Rate limiting
    if (str.contains('429') ||
        str.contains('rate limit') ||
        str.contains('too many')) {
      return switch (lang) {
        Language.hi => 'बहुत अधिक प्रयास। कृपया थोड़ी देर बाद पुनः प्रयास करें।',
        Language.mr => 'खूप जास्त प्रयत्न. कृपया थोड्या वेळाने पुन्हा प्रयत्न करा.',
        Language.ta => 'அதிக முயற்சிகள். சில நிமிடங்கள் கழித்து மீண்டும் முயற்சிக்கவும்.',
        Language.te => 'ఎక్కువ ప్రయత్నాలు. దయచేసి కొన్ని నిమిషాల తర్వాత మళ్లీ ప్రయత్నించండి.',
        Language.gu => 'ઘણા બધા પ્રયાસો. કૃપા કરીને થોડીવાર પછી ફરી પ્રયાસ કરો.',
        Language.bn => 'অতিরিক্ত প্রচেষ্টা। দয়া করে কিছুক্ষণ পরে আবার চেষ্টা করুন।',
        Language.en => 'Too many attempts. Please wait a few minutes and try again.',
      };
    }

    // Expired OTP
    if (str.contains('expired')) {
      return switch (lang) {
        Language.hi => 'ओटीपी की समय सीमा समाप्त हो गई है। कृपया नया ओटीपी भेजें।',
        Language.mr => 'ओटीपीची मुदत संपली आहे. कृपया नवीन ओटीपी पाठवा.',
        Language.ta => 'OTP காலாவதியானது. புதிய குறியீட்டைப் பெற மீண்டும் அனுப்புக என்பதை அழுத்தவும்.',
        Language.te => 'OTP గడువు ముగిసింది. కొత్త కోడ్ కోసం మళ్లీ పంపు నొక్కండి.',
        Language.gu => 'ઓટીપીની સમયસીમા સમાપ્ત થઈ ગઈ છે. કૃપા કરીને ફરીથી મોકલો.',
        Language.bn => 'ওটিপির মেয়াদ শেষ হয়ে গেছে। নতুন ওটিপি পাঠাতে পুনরায় অনুরোধ করুন।',
        Language.en => 'OTP has expired. Please tap resend to get a new code.',
      };
    }

    // Invalid / wrong OTP token or code mismatch
    if (str.contains('invalid') ||
        str.contains('token') ||
        str.contains('otp') ||
        str.contains('code') ||
        str.contains('mismatch') ||
        str.contains('incorrect') ||
        str.contains('wrong')) {
      return switch (lang) {
        Language.hi => 'अमान्य या समाप्त ओटीपी कोड। कृपया सही 6-अंकों का कोड दर्ज करें।',
        Language.mr => 'अवैध किंवा कालबाह्य ओटीपी कोड. कृपया योग्य ६ अंकी कोड टाका.',
        Language.ta => 'தவறான அல்லது காலாவதியான OTP குறியீடு. சரியான 6 இலக்க குறியீட்டை உள்ளிடவும்.',
        Language.te => 'చెల్లని లేదా గడువు ముగిసిన OTP కోడ్. దయచేసి సరైన 6 అంకెల కోడ్‌ను నమోదు చేయండి.',
        Language.gu => 'અમાન્ય અથવા સમાપ્ત થયેલ ઓટીપી. કૃપા કરીને સાચો ૬-અંકનો કોડ દાખલ કરો.',
        Language.bn => 'ভুল বা মেয়াদোত্তীর্ণ ওটিপি কোড। সঠিক ৬-সংখ্যার কোড লিখুন।',
        Language.en => 'Invalid or expired OTP code. Please enter the correct 6-digit code.',
      };
    }

    // Network / connectivity issues
    if (str.contains('network') ||
        str.contains('socket') ||
        str.contains('connection') ||
        str.contains('clientexception') ||
        str.contains('offline') ||
        str.contains('timeout')) {
      return switch (lang) {
        Language.hi => 'नेटवर्क त्रुटि। कृपया अपना इंटरनेट कनेक्शन जांचें।',
        Language.mr => 'नेटवर्क त्रुटी. कृपया तुमचे इंटरनेट कनेक्शन तपासा.',
        Language.ta => 'பிணையப் பிழை. உங்கள் இணைய இணைப்பைச் சரிபார்க்கவும்.',
        Language.te => 'నెట్‌వర్క్ లోపం. దయచేసి మీ ఇంటర్నెట్ కనెక్షన్‌ని తనిఖీ చేయండి.',
        Language.gu => 'નેટવર્ક ભૂલ. કૃપા કરીને તમારું ઇન્ટરનેટ કનેક્શન તપાસો.',
        Language.bn => 'নেটওয়ার্ক ত্রুটি। আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন।',
        Language.en => 'Network error. Please check your internet connection.',
      };
    }

    // Fallback generic verification error
    return switch (lang) {
      Language.hi => 'सत्यापन विफल रहा। कृपया सही कोड दर्ज करें या पुनः प्रयास करें।',
      Language.mr => 'पडताळणी अयशस्वी. कृपया योग्य कोड टाका किंवा पुन्हा प्रयत्न करा.',
      Language.ta => 'சரிபார்ப்பு தோல்வியடைந்தது. சரியான குறியீட்டை உள்ளிடவும் அல்லது மீண்டும் முயற்சிக்கவும்.',
      Language.te => 'ధృవీకరణ విఫలమైంది. దయచేసి సరైన కోడ్‌ను నమోదు చేయండి లేదా మళ్లీ ప్రయత్నించండి.',
      Language.gu => 'ચકાસણી નિષ્ફળ રહી. કૃપા કરીને સાચો કોડ દાખલ કરો અથવા ફરી પ્રયાસ કરો.',
      Language.bn => 'যাচাইকরণ ব্যর্থ হয়েছে। সঠিক কোড দিন অথবা আবার চেষ্টা করুন।',
      Language.en => 'Verification failed. Please check the code and try again.',
    };
  }

  /// Sanitizes errors encountered when resending OTP (OTP Step).
  static String sanitizeResendOtpError(
    dynamic error, {
    bool isHi = false,
    Language? language,
  }) {
    final lang = _resolveLang(isHi: isHi, language: language);
    final str = error.toString().toLowerCase();

    if (str.contains('429') ||
        str.contains('rate limit') ||
        str.contains('sms limit') ||
        str.contains('too many') ||
        str.contains('over_sms_send_rate_limit')) {
      return switch (lang) {
        Language.hi => 'बहुत अधिक प्रयास। कृपया थोड़ी देर बाद पुनः प्रयास करें।',
        Language.mr => 'खूप जास्त प्रयत्न. कृपया थोड्या वेळाने पुन्हा प्रयत्न करा.',
        Language.ta => 'அதிக முயற்சிகள். சில நிமிடங்கள் கழித்து மீண்டும் முயற்சிக்கவும்.',
        Language.te => 'ఎక్కువ ప్రయత్నాలు. దయచేసి కొన్ని నిమిషాల తర్వాత మళ్లీ ప్రయత్నించండి.',
        Language.gu => 'ઘણા બધા પ્રયાસો. કૃપા કરીને થોડીવાર પછી ફરી પ્રયાસ કરો.',
        Language.bn => 'অতিরিক্ত প্রচেষ্টা। দয়া করে কিছুক্ষণ পরে আবার চেষ্টা করুন।',
        Language.en => 'Too many attempts. Please wait a few minutes and try again.',
      };
    }

    if (str.contains('network') ||
        str.contains('socket') ||
        str.contains('connection') ||
        str.contains('clientexception') ||
        str.contains('offline') ||
        str.contains('timeout')) {
      return switch (lang) {
        Language.hi => 'नेटवर्क त्रुटि। कृपया अपना इंटरनेट कनेक्शन जांचें।',
        Language.mr => 'नेटवर्क त्रुटी. कृपया तुमचे इंटरनेट कनेक्शन तपासा.',
        Language.ta => 'பிணையப் பிழை. உங்கள் இணைய இணைப்பைச் சரிபார்க்கவும்.',
        Language.te => 'నెట్‌వర్క్ లోపం. దయచేసి మీ ఇంటర్నెట్ కనెక్షన్‌ని తనిఖీ చేయండి.',
        Language.gu => 'નેટવર્ક ભૂલ. કૃપા કરીને તમારું ઇન્ટરનેટ કનેક્શન તપાસો.',
        Language.bn => 'নেটওয়ার্ক ত্রুটি। আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন।',
        Language.en => 'Network error. Please check your internet connection.',
      };
    }

    return switch (lang) {
      Language.hi => 'ओटीपी पुनः भेजने में विफल। कृपया पुनः प्रयास करें।',
      Language.mr => 'ओटीपी पुन्हा पाठवण्यात अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      Language.ta => 'OTP மீண்டும் அனுப்புவதில் தோல்வி. மீண்டும் முயற்சிக்கவும்.',
      Language.te => 'OTP మళ్లీ పంపడంలో విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      Language.gu => 'ઓટીપી ફરી મોકલવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.',
      Language.bn => 'ওটিপি পুনরায় পাঠাতে ব্যর্থ হয়েছে। দয়া করে আবার চেষ্টা করুন।',
      Language.en => 'Failed to resend OTP. Please try again.',
    };
  }

  /// Indian mobile number pattern: exactly 10 digits starting with digits 6 through 9 (^[6-9]\d{9}$)
  static final RegExp indianMobileRegex = RegExp(r'^[6-9]\d{9}$');

  /// Normalizes a phone number by:
  /// - Stripping all spaces, dashes, parentheses, non-digits
  /// - Stripping '+91' or '91' country code prefix when total length is 12 digits
  /// - Stripping '0' trunk prefix when total length is 11 digits
  /// Returns the clean 10-digit mobile number, or cleaned digits.
  static String normalizePhoneNumber(String? input) {
    if (input == null) return '';
    var trimmed = input.trim();

    // Remove leading +91 or +
    if (trimmed.startsWith('+91')) {
      trimmed = trimmed.substring(3).trim();
    } else if (trimmed.startsWith('+')) {
      trimmed = trimmed.substring(1).trim();
    }

    // Strip all non-digit characters (spaces, dashes, parens, etc.)
    var digits = trimmed.replaceAll(RegExp(r'\D'), '');

    // If still prefixed with 91 and has > 10 digits (e.g. 919582198165)
    if (digits.length > 10 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length > 10 && digits.startsWith('0')) {
      // Leading trunk 0 prefix (e.g. 09582198165)
      digits = digits.substring(1);
    }

    return digits;
  }

  /// Checks whether the given phone number is a valid 10-digit Indian mobile number:
  /// - Exactly 10 digits (excluding +91 country code)
  /// - Starts with digits 6 through 9 (^[6-9]\d{9}$)
  static bool isValidIndianPhoneNumber(String? phone) {
    if (phone == null) return false;
    final normalized = normalizePhoneNumber(phone);
    return indianMobileRegex.hasMatch(normalized);
  }

  /// Validates an Indian mobile number.
  /// Calls [normalizePhoneNumber] at the very beginning before performing any length or pattern check.
  /// Returns null if valid, or a localized error message if invalid.
  static String? validatePhoneNumber(
    String? phone, {
    bool isHi = false,
    Language? language,
  }) {
    final lang = _resolveLang(isHi: isHi, language: language);
    // 1. Call normalizePhoneNumber at the very beginning
    final normalized = normalizePhoneNumber(phone);

    // 2. Length check evaluated strictly against the clean, normalized 10-digit string
    if (normalized.length != 10) {
      return switch (lang) {
        Language.hi => 'कृपया 10 अंकों का वैध मोबाइल नंबर दर्ज करें',
        Language.mr => 'कृपया १० अंकी वैध मोबाईल नंबर टाका',
        Language.ta => 'சரியான 10 இலக்க மொபைல் எண்ணை உள்ளிடவும்',
        Language.te => 'దయచేసి సరైన 10 అంకెల మొబైల్ నంబర్‌ను నమోదు చేయండి',
        Language.gu => 'કૃપા કરીને ૧૦ અંકનો માન્ય મોબાઇલ નંબર દાખલ કરો',
        Language.bn => 'দয়া করে ১০ সংখ্যার সঠিক মোবাইল নম্বর লিখুন',
        Language.en => 'Please enter a valid 10-digit mobile number',
      };
    }

    // 3. Pattern check evaluated strictly against the clean, normalized string (^[6-9]\d{9}$)
    if (!indianMobileRegex.hasMatch(normalized)) {
      return switch (lang) {
        Language.hi => 'कृपया 6-9 से शुरू होने वाला 10 अंकों का वैध मोबाइल नंबर दर्ज करें',
        Language.mr => 'कृपया ६-९ ने सुरू होणारा १० अंकी वैध मोबाईल नंबर टाका',
        Language.ta => '6-9 இல் தொடங்கும் 10 இலக்க மொபைல் எண்ணை உள்ளிடவும்',
        Language.te => 'దయచేసి 6-9 తో ప్రారంభమయ్యే సరైన 10 అంకెల మొబైల్ నంబర్‌ను నమోదు చేయండి',
        Language.gu => 'કૃપા કરીને ૬-૯ થી શરૂ થતો ૧૦ અંકનો માન્ય મોબાઇલ નંબર દાખલ કરો',
        Language.bn => 'দয়া করে ৬-৯ দিয়ে শুরু হওয়া ১০ সংখ্যার সঠিক মোবাইল নম্বর লিখুন',
        Language.en => 'Please enter a valid 10-digit mobile number starting with 6-9',
      };
    }

    return null;
  }

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
      final clean = PhoneLoginScreen.normalizePhoneNumber(widget.initialPhoneNumber!);
      _phoneController.text = clean;
    }

    _otpControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (_) => FocusNode());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _phoneController.addListener(() {
      if (mounted) {
        if (_phoneErrorMessage != null || _otpErrorMessage != null) {
          _phoneErrorMessage = null;
          _otpErrorMessage = null;
        }
        setState(() {});
      }
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

  /// Called whenever the user modifies the phone number input field.
  /// Instantly resets any lingering error states.
  void _onPhoneNumberChanged(String value) {
    if (_phoneErrorMessage != null || _otpErrorMessage != null) {
      setState(() {
        _phoneErrorMessage = null;
        _otpErrorMessage = null;
      });
    }
  }

  /// Navigates back from OTP screen to Phone Number entry screen.
  /// Completely resets OTP & phone error states and clears OTP fields.
  void _navigateBackToPhone() {
    setState(() {
      _step = PhoneStep.phone;
      _phoneErrorMessage = null;
      _otpErrorMessage = null;
      for (final c in _otpControllers) {
        c.clear();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _phoneFocusNode.requestFocus();
      }
    });
  }



  /// Sends OTP via Supabase Auth + Twilio SMS
  Future<void> _handleSendOtp() async {
    final rawNumber = _phoneController.text.trim();
    final lang = context.read<AppState>().language;

    final validationError =
        PhoneLoginScreen.validatePhoneNumber(rawNumber, language: lang);
    if (validationError != null) {
      setState(() {
        _phoneErrorMessage = validationError;
        _otpErrorMessage = null;
      });
      return;
    }

    final normalizedNumber = PhoneLoginScreen.normalizePhoneNumber(rawNumber);
    if (_phoneController.text != normalizedNumber) {
      _phoneController.text = normalizedNumber;
    }

    setState(() {
      _phoneErrorMessage = null;
      _otpErrorMessage = null;
      _isSendingOtp = true;
    });

    final e164Phone = '+91$normalizedNumber';

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        phone: e164Phone,
      );

      if (!mounted) return;

      setState(() {
        _isSendingOtp = false;
        _step = PhoneStep.otp;
        _phoneErrorMessage = null;
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
      // ignore: avoid_print
      print('🔥 RAW SUPABASE ERROR: $e');
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        _otpErrorMessage = null;
        _phoneErrorMessage =
            PhoneLoginScreen.sanitizeSendOtpError(e, language: lang);
      });
    }
  }

  /// Resend OTP handler
  Future<void> _handleResendOtp() async {
    if (_secondsRemaining > 0) return;

    final rawNumber = _phoneController.text.trim();
    final lang = context.read<AppState>().language;
    final normalized = PhoneLoginScreen.normalizePhoneNumber(rawNumber);
    final e164Phone = '+91$normalized';

    _startCountdown();

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        phone: e164Phone,
      );

      if (!mounted) return;

      final resentMsg = switch (lang) {
        Language.hi => 'ओटीपी पुनः भेजा गया: $e164Phone',
        Language.mr => 'येथे ओटीपी पुन्हा पाठवला: $e164Phone',
        Language.ta => 'OTP மீண்டும் அனுப்பப்பட்டது: $e164Phone',
        Language.te => 'OTP మళ్లీ పంపబడింది: $e164Phone',
        Language.gu => 'ઓટીપી ફરી મોકલાયો: $e164Phone',
        Language.bn => 'ওটিপি পুনরায় পাঠানো হয়েছে: $e164Phone',
        Language.en => 'OTP resent to $e164Phone',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resentMsg),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _otpErrorMessage =
            PhoneLoginScreen.sanitizeResendOtpError(e, language: lang);
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
    final lang = context.read<AppState>().language;

    if (otp.length < 6) {
      setState(() {
        _otpErrorMessage = switch (lang) {
          Language.hi => 'कृपया पूरा 6-अंकों का ओटीपी दर्ज करें',
          Language.mr => 'कृपया संपूर्ण ६ अंकी ओटीपी टाका',
          Language.ta => 'முழுமையான 6 இலக்க OTP ஐ உள்ளிடவும்',
          Language.te => 'దయచేసి పూర్తి 6 అంకెల OTP నమోదు చేయండి',
          Language.gu => 'કૃપા કરીને પૂરો ૬-અંકનો ઓટીપી દાખલ કરો',
          Language.bn => 'দয়া করে সম্পূর্ণ ৬-সংখ্যার ওটিপি লিখুন',
          Language.en => 'Please enter complete 6-digit OTP',
        };
      });
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _otpErrorMessage = null;
      _phoneErrorMessage = null;
    });

    // Hackathon demo bypass: strictly '123456'
    if (otp == '123456') {
      _countdownTimer?.cancel();
      final appState = context.read<AppState>();
      appState.loginFromSession();
      if (!appState.isAuthenticated) {
        appState.login();
      }

      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          context.read<DataProvider>().reloadForUser(userId);
        }
      } catch (_) {}

      setState(() => _isVerifyingOtp = false);

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
      return;
    }

    final rawNumber = _phoneController.text.trim();
    final normalized = PhoneLoginScreen.normalizePhoneNumber(rawNumber);
    final e164Phone = '+91$normalized';

    try {
      await Supabase.instance.client.auth.verifyOTP(
        phone: e164Phone,
        token: otp,
        type: OtpType.sms,
      );

      if (!mounted) return;

      _countdownTimer?.cancel();

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
        _otpErrorMessage =
            PhoneLoginScreen.sanitizeVerifyOtpError(e, language: lang);
      });
    }
  }

  /// Helper to format masked phone number: +91 98****3210
  String _getMaskedPhone() {
    final raw = PhoneLoginScreen.normalizePhoneNumber(_phoneController.text);
    if (raw.length == 10) {
      return '+91 ${raw.substring(0, 2)}****${raw.substring(6)}';
    }
    return '+91 $raw';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.strings;

    return PopScope(
      canPop: _step == PhoneStep.phone || widget.startAtOtp,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_step == PhoneStep.otp && !widget.startAtOtp) {
          _navigateBackToPhone();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceIvory,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceIvory,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () {
              if (_step == PhoneStep.otp && !widget.startAtOtp) {
                _navigateBackToPhone();
              } else {
                Navigator.of(context).pop();
              }
            },
            tooltip: 'Back',
          ),
          title: Text(
            _step == PhoneStep.phone ? s.phoneLoginTitle : s.otpTitle,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: LanguageSelector(
                compact: true,
                currentLanguage: app.language,
                onLanguageChange: app.setLanguage,
              ),
            ),
          ],
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
                    ? _buildEnterPhoneStep(app, s)
                    : _buildEnterOtpStep(app, s),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SCREEN A: ENTER PHONE
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildEnterPhoneStep(AppState app, DashboardStrings s) {
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

        // Title & Multilingual Subtitle
        Center(
          child: Column(
            children: [
              Text(
                s.enterMobile,
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
                switch (app.language) {
                  Language.hi => 'हम आपके नंबर पर एक 6-अंकों का ओटीपी भेजेंगे',
                  Language.mr => 'आम्ही तुमच्या नंबरवर ६ अंकी ओटीपी पाठवू',
                  Language.ta => 'உங்கள் எண்ணிற்கு 6 இலக்க OTP அனுப்புவோம்',
                  Language.te => 'మీ నంబర్‌కు 6 అంకెల OTP ని పంపుతాము',
                  Language.gu => 'અમે તમારા નંબર પર ૬-અંકનો ઓટીપી મોકલીશું',
                  Language.bn => 'আমরা আপনার নম্বরে একটি ৬-সংখ্যার ওটিপি পাঠাব',
                  Language.en => "We'll send a 6-digit OTP verification code",
                },
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
          switch (app.language) {
            Language.hi => 'मोबाइल नंबर',
            Language.mr => 'मोबाईल नंबर',
            Language.ta => 'கைபேசி எண்',
            Language.te => 'మొబైల్ నంబర్',
            Language.gu => 'મોબાઇલ નંબર',
            Language.bn => 'মোবাইল নম্বর',
            Language.en => 'Mobile Number',
          },
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
                  inputFormatters: const [
                    IndianPhoneInputFormatter(),
                  ],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                    letterSpacing: 1.0,
                  ),
                  decoration: InputDecoration(
                    hintText: s.mobileNumberHint,
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
                  onChanged: _onPhoneNumberChanged,
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
                    setState(() {
                      _phoneErrorMessage = null;
                      _otpErrorMessage = null;
                    });
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
                        s.sendOtp,
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

  Widget _buildEnterOtpStep(AppState app, DashboardStrings s) {
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
                switch (app.language) {
                  Language.hi => 'ओटीपी भेजा गया:',
                  Language.mr => 'येथे ओटीपी पाठवला:',
                  Language.ta => 'OTP அனுப்பப்பட்டது:',
                  Language.te => 'OTP పంపబడింది:',
                  Language.gu => 'ઓટીપી મોકલાયો:',
                  Language.bn => 'ওটিপি পাঠানো হয়েছে:',
                  Language.en => 'OTP sent to',
                },
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
                onTap: _navigateBackToPhone,
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
                        s.changeNumber,
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
                switch (app.language) {
                  Language.hi => 'ओटीपी नहीं मिला?',
                  Language.mr => 'ओटीपी मिळाला नाही?',
                  Language.ta => 'OTP வரவில்லையா?',
                  Language.te => 'OTP రాలేదా?',
                  Language.gu => 'ઓટીપી નથી મળ્યો?',
                  Language.bn => 'ওটিপি পাননি?',
                  Language.en => "Didn't receive code?",
                },
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
                      ? (switch (app.language) {
                          Language.hi => '$_secondsRemaining सेकंड में पुनः भेजें',
                          Language.mr => '$_secondsRemaining सेकंदात पुन्हा पाठवा',
                          Language.ta => '$_secondsRemaining வினாடிகளில் மீண்டும் அனுப்பவும்',
                          Language.te => '$_secondsRemaining సెకన్లలో మళ్లీ పంపండి',
                          Language.gu => '$_secondsRemaining સેકન્ડમાં ફરી મોકલો',
                          Language.bn => '$_secondsRemaining সেকেন্ডে পুনরায় পাঠান',
                          Language.en => 'Resend in ${_secondsRemaining}s',
                        })
                      : s.resendOtp,
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
                        s.verifyLogin,
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
