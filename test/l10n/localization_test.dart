import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bruprog_handora/l10n/strings.dart';
import 'package:bruprog_handora/models/order.dart';
import 'package:bruprog_handora/providers/app_state.dart';
import 'package:bruprog_handora/screens/phone_login_screen.dart';
import 'package:bruprog_handora/services/whatsapp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('7-Language Localization Definition Tests', () {
    test('Language enum has exactly 7 supported Indian languages', () {
      expect(Language.values.length, 7);
      expect(Language.values, containsAll([
        Language.en,
        Language.hi,
        Language.mr,
        Language.ta,
        Language.te,
        Language.gu,
        Language.bn,
      ]));
    });

    test('Each language has proper display name and short label', () {
      expect(Language.en.displayName, 'English');
      expect(Language.en.shortLabel, 'EN');
      expect(Language.en.isIndic, isFalse);

      expect(Language.hi.displayName, 'हिन्दी');
      expect(Language.hi.shortLabel, 'हिं');
      expect(Language.hi.isIndic, isTrue);

      expect(Language.mr.displayName, 'मराठी');
      expect(Language.mr.shortLabel, 'मरा');
      expect(Language.mr.isIndic, isTrue);

      expect(Language.ta.displayName, 'தமிழ்');
      expect(Language.ta.shortLabel, 'தமி');
      expect(Language.ta.isIndic, isTrue);

      expect(Language.te.displayName, 'తెలుగు');
      expect(Language.te.shortLabel, 'తెలు');
      expect(Language.te.isIndic, isTrue);

      expect(Language.gu.displayName, 'ગુજરાતી');
      expect(Language.gu.shortLabel, 'ગુજ');
      expect(Language.gu.isIndic, isTrue);

      expect(Language.bn.displayName, 'বাংলা');
      expect(Language.bn.shortLabel, 'বাং');
      expect(Language.bn.isIndic, isTrue);
    });

    test('kStrings contains complete translations for all 7 languages', () {
      for (final lang in Language.values) {
        final strings = kStrings[lang];
        expect(strings, isNotNull, reason: 'Missing strings for ${lang.name}');

        // Test essential keys are populated and non-empty
        expect(strings!.loginWelcome.isNotEmpty, isTrue);
        expect(strings.continuePhone.isNotEmpty, isTrue);
        expect(strings.continueEmail.isNotEmpty, isTrue);
        expect(strings.continueGoogle.isNotEmpty, isTrue);
        expect(strings.phoneLoginTitle.isNotEmpty, isTrue);
        expect(strings.sendOtp.isNotEmpty, isTrue);
        expect(strings.verifyLogin.isNotEmpty, isTrue);
        expect(strings.resendOtp.isNotEmpty, isTrue);
        expect(strings.changeNumber.isNotEmpty, isTrue);
        expect(strings.logout.isNotEmpty, isTrue);
        expect(strings.cancel.isNotEmpty, isTrue);
        expect(strings.save.isNotEmpty, isTrue);
        expect(strings.recentOrders.isNotEmpty, isTrue);
        expect(strings.sendWhatsappUpdate.isNotEmpty, isTrue);
        expect(strings.updateOrderStatus.isNotEmpty, isTrue);
      }
    });

    test('Marathi translations verify native script', () {
      final mr = kStrings[Language.mr]!;
      expect(mr.loginWelcome, 'हँडोरा मध्ये आपले स्वागत आहे');
      expect(mr.continuePhone, 'फोन नंबरने सुरू करा');
      expect(mr.sendOtp, 'ओटीपी पाठवा');
      expect(mr.verifyLogin, 'पडताळणी करा आणि पुढे जा');
      expect(mr.logout, 'लॉग आउट');
      expect(mr.orderStatusShipped, 'पाठवले');
    });

    test('Tamil translations verify native script', () {
      final ta = kStrings[Language.ta]!;
      expect(ta.loginWelcome, 'ஹண்டோராவிற்கு நல்வரவு');
      expect(ta.continuePhone, 'தொலைபேசி மூலம் தொடரவும்');
      expect(ta.sendOtp, 'OTP அனுப்பவும்');
      expect(ta.verifyLogin, 'சரிபார்த்து உள்நுழைக');
      expect(ta.logout, 'வெளியேறு');
      expect(ta.orderStatusShipped, 'அனுப்பப்பட்டது');
    });

    test('Telugu translations verify native script', () {
      final te = kStrings[Language.te]!;
      expect(te.loginWelcome, 'హండోరాకు స్వాగతం');
      expect(te.continuePhone, 'ఫోన్ నంబర్‌తో కొనసాగించండి');
      expect(te.sendOtp, 'OTP పంపండి');
      expect(te.verifyLogin, 'ధృవీకరించి లాగిన్ అవ్వండి');
      expect(te.logout, 'లాగ్ అవుట్');
      expect(te.orderStatusShipped, 'రవాణా చేయబడింది');
    });

    test('Gujarati translations verify native script', () {
      final gu = kStrings[Language.gu]!;
      expect(gu.loginWelcome, 'હંદોરામાં સ્વાગત છે');
      expect(gu.continuePhone, 'ફોન નંબર સાથે આગળ વધો');
      expect(gu.sendOtp, 'OTP મોકલો');
      expect(gu.verifyLogin, 'ચકાસો અને લૉગિન કરો');
      expect(gu.logout, 'લૉગ આઉટ');
      expect(gu.orderStatusShipped, 'મોકલેલ');
    });

    test('Bengali translations verify native script', () {
      final bn = kStrings[Language.bn]!;
      expect(bn.loginWelcome, 'হ্যান্ডোরায় স্বাগতম');
      expect(bn.continuePhone, 'ফোন নম্বর দিয়ে এগিয়ে যান');
      expect(bn.sendOtp, 'OTP পাঠান');
      expect(bn.verifyLogin, 'যাচাই করে লগইন করুন');
      expect(bn.logout, 'লগ আউট');
      expect(bn.orderStatusShipped, 'পাঠানো হয়েছে');
    });
  });

  group('AppState Language Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('AppState defaults to English if no preference is saved', () {
      final appState = AppState();
      expect(appState.language, Language.en);
    });

    test('AppState loads previously saved language from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'handora_selected_language': 'gu',
      });

      final appState = AppState();
      // Allow async SharedPreferences load to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(appState.language, Language.gu);
    });

    test('Changing language updates state and persists in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState();

      appState.setLanguage(Language.bn);
      expect(appState.language, Language.bn);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('handora_selected_language'), 'bn');
    });
  });

  group('WhatsAppService 7-Language Message Construction', () {
    const testOrder = Order(
      id: 'HND-5555',
      quantity: 1,
      productEn: 'Handmade Silk Saree',
      productHi: 'हाथ से बुनी सिल्क साड़ी',
      amountInRupees: 3500,
      placedAt: 'Just now',
      thumbnail: 'assets/images/saree.jpg',
      status: 'shipped',
      buyerName: 'Kavitha',
      buyerPhone: '919876543210',
    );

    test('builds Marathi order message', () {
      final msg = WhatsAppService.buildOrderMessage(
        order: testOrder,
        language: Language.mr,
      );
      expect(msg, contains('नमस्कार Kavitha'));
      expect(msg, contains('Handora ऑर्डर #HND-5555'));
      expect(msg, contains('3500'));
      expect(msg, contains('Shipped'));
    });

    test('builds Tamil order message', () {
      final msg = WhatsAppService.buildOrderMessage(
        order: testOrder,
        language: Language.ta,
      );
      expect(msg, contains('வணக்கம் Kavitha'));
      expect(msg, contains('Handora ஆர்டர் #HND-5555'));
      expect(msg, contains('3500'));
      expect(msg, contains('Shipped'));
    });

    test('builds Telugu order message', () {
      final msg = WhatsAppService.buildOrderMessage(
        order: testOrder,
        language: Language.te,
      );
      expect(msg, contains('నమస్కారం Kavitha'));
      expect(msg, contains('Handora ఆర్డర్ #HND-5555'));
      expect(msg, contains('3500'));
      expect(msg, contains('Shipped'));
    });

    test('builds Gujarati order message', () {
      final msg = WhatsAppService.buildOrderMessage(
        order: testOrder,
        language: Language.gu,
      );
      expect(msg, contains('નમસ્તે Kavitha'));
      expect(msg, contains('Handora ઓર્ડર #HND-5555'));
      expect(msg, contains('3500'));
      expect(msg, contains('Shipped'));
    });

    test('builds Bengali order message', () {
      final msg = WhatsAppService.buildOrderMessage(
        order: testOrder,
        language: Language.bn,
      );
      expect(msg, contains('নমস্কার Kavitha'));
      expect(msg, contains('Handora অর্ডার #HND-5555'));
      expect(msg, contains('3500'));
      expect(msg, contains('Shipped'));
    });

    test('formats status labels for Gujarati and Bengali', () {
      expect(WhatsAppService.formatStatusLabel('shipped', Language.gu), contains('મોકલી દેવાયો'));
      expect(WhatsAppService.formatStatusLabel('delivered', Language.bn), contains('পৌঁছে গেছে'));
      expect(WhatsAppService.formatStatusLabel('new', Language.gu), contains('ઓર્ડર મળ્યો'));
      expect(WhatsAppService.formatStatusLabel('cancelled', Language.bn), contains('অর্ডার বাতিল'));
    });
  });

  group('PhoneLoginScreen 7-Language Error Sanitization', () {
    test('sanitizes validation and errors in all Indic languages', () {
      // Marathi
      expect(
        PhoneLoginScreen.validatePhoneNumber('12345', language: Language.mr),
        contains('१० अंकी'),
      );
      expect(
        PhoneLoginScreen.sanitizeSendOtpError('429 rate limit', language: Language.mr),
        contains('प्रयत्न'),
      );

      // Tamil
      expect(
        PhoneLoginScreen.validatePhoneNumber('12345', language: Language.ta),
        contains('10 இலக்க'),
      );
      expect(
        PhoneLoginScreen.sanitizeSendOtpError('429 rate limit', language: Language.ta),
        contains('முயற்சிகள்'),
      );

      // Telugu
      expect(
        PhoneLoginScreen.validatePhoneNumber('12345', language: Language.te),
        contains('10 అంకెల'),
      );
      expect(
        PhoneLoginScreen.sanitizeSendOtpError('429 rate limit', language: Language.te),
        contains('ప్రయత్నాలు'),
      );

      // Gujarati
      expect(
        PhoneLoginScreen.validatePhoneNumber('12345', language: Language.gu),
        contains('૧૦ અંકનો'),
      );
      expect(
        PhoneLoginScreen.sanitizeSendOtpError('429 rate limit', language: Language.gu),
        contains('પ્રયાસો'),
      );

      // Bengali
      expect(
        PhoneLoginScreen.validatePhoneNumber('12345', language: Language.bn),
        contains('১০ সংখ্যার'),
      );
      expect(
        PhoneLoginScreen.sanitizeSendOtpError('429 rate limit', language: Language.bn),
        contains('প্রচেষ্টা'),
      );
    });
  });
}
