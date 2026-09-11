import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bruprog_handora/providers/app_state.dart';
import 'package:bruprog_handora/screens/phone_login_screen.dart';

void main() {
  group('PhoneLoginScreen phone number normalization & validation', () {
    test('validates valid 10-digit Indian mobile number like 9582198165', () {
      expect(PhoneLoginScreen.isValidIndianPhoneNumber('9582198165'), isTrue);
      expect(
        PhoneLoginScreen.validatePhoneNumber('9582198165', isHi: false),
        isNull,
      );
      expect(
        PhoneLoginScreen.validatePhoneNumber('9582198165', isHi: true),
        isNull,
      );
    });

    test('strips +91, 91, trunk 0, spaces, and hyphens without counting toward 10 digits', () {
      // With +91 prefix
      expect(PhoneLoginScreen.normalizePhoneNumber('+919582198165'), '9582198165');
      expect(PhoneLoginScreen.isValidIndianPhoneNumber('+919582198165'), isTrue);
      expect(PhoneLoginScreen.validatePhoneNumber('+919582198165', isHi: false), isNull);

      // With +91 and spaces
      expect(PhoneLoginScreen.normalizePhoneNumber('+91 95821 98165'), '9582198165');
      expect(PhoneLoginScreen.isValidIndianPhoneNumber('+91 95821 98165'), isTrue);
      expect(PhoneLoginScreen.validatePhoneNumber('+91 95821 98165', isHi: false), isNull);

      // With 91 prefix without plus
      expect(PhoneLoginScreen.normalizePhoneNumber('919582198165'), '9582198165');
      expect(PhoneLoginScreen.isValidIndianPhoneNumber('919582198165'), isTrue);

      // With leading 0 trunk prefix
      expect(PhoneLoginScreen.normalizePhoneNumber('09582198165'), '9582198165');
      expect(PhoneLoginScreen.isValidIndianPhoneNumber('09582198165'), isTrue);

      // With hyphens and spaces
      expect(PhoneLoginScreen.normalizePhoneNumber('+91-95821-98165'), '9582198165');
      expect(PhoneLoginScreen.isValidIndianPhoneNumber('+91-95821-98165'), isTrue);
    });

    test('validates numbers starting with digits 6 through 9 (^[6-9]\\d{9}\$)', () {
      // Starting with 6, 7, 8, 9 are valid
      expect(PhoneLoginScreen.isValidIndianPhoneNumber('6123456789'), isTrue);
      expect(PhoneLoginScreen.isValidIndianPhoneNumber('7123456789'), isTrue);
      expect(PhoneLoginScreen.isValidIndianPhoneNumber('8123456789'), isTrue);
      expect(PhoneLoginScreen.isValidIndianPhoneNumber('9123456789'), isTrue);

      // Numbers starting with 0-5 are invalid
      expect(PhoneLoginScreen.isValidIndianPhoneNumber('5582198165'), isFalse);
      expect(PhoneLoginScreen.isValidIndianPhoneNumber('1234567890'), isFalse);
      expect(PhoneLoginScreen.isValidIndianPhoneNumber('0123456789'), isFalse);

      expect(
        PhoneLoginScreen.validatePhoneNumber('1234567890', isHi: false),
        contains('starting with 6-9'),
      );
      expect(
        PhoneLoginScreen.validatePhoneNumber('1234567890', isHi: true),
        contains('6-9'),
      );
    });

    test('rejects numbers shorter or longer than 10 digits', () {
      // Shorter
      expect(PhoneLoginScreen.isValidIndianPhoneNumber('958219816'), isFalse);
      expect(
        PhoneLoginScreen.validatePhoneNumber('958219816', isHi: false),
        contains('10-digit mobile number'),
      );

      // Longer
      expect(PhoneLoginScreen.isValidIndianPhoneNumber('95821981655'), isFalse);
      expect(
        PhoneLoginScreen.validatePhoneNumber('95821981655', isHi: false),
        contains('10-digit mobile number'),
      );

      // Empty
      expect(PhoneLoginScreen.isValidIndianPhoneNumber(''), isFalse);
      expect(PhoneLoginScreen.isValidIndianPhoneNumber(null), isFalse);
    });

    test('IndianPhoneInputFormatter formats and cleans pasted numbers', () {
      const formatter = IndianPhoneInputFormatter();

      // Pasting +91 9582198165
      final pastedWithCode = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '+91 9582198165',
          selection: TextSelection.collapsed(offset: 14),
        ),
      );
      expect(pastedWithCode.text, '9582198165');

      // Pasting 09582198165
      final pastedWithTrunk = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '09582198165',
          selection: TextSelection.collapsed(offset: 11),
        ),
      );
      expect(pastedWithTrunk.text, '9582198165');

      // Typing more than 10 digits clamps to 10
      final typedExtra = formatter.formatEditUpdate(
        const TextEditingValue(text: '9582198165'),
        const TextEditingValue(
          text: '95821981659',
          selection: TextSelection.collapsed(offset: 11),
        ),
      );
      expect(typedExtra.text, '9582198165');
    });
  });

  group('PhoneLoginScreen error sanitization separation', () {
    test('sanitizeSendOtpError never returns OTP error when error has code and invalid', () {
      const errorStr =
          'AuthApiException(message: invalid phone request, statusCode: 400, code: 400)';

      final enResult =
          PhoneLoginScreen.sanitizeSendOtpError(errorStr, isHi: false);
      final hiResult =
          PhoneLoginScreen.sanitizeSendOtpError(errorStr, isHi: true);

      expect(enResult, isNot(contains('OTP code')));
      expect(enResult, isNot(contains('6-digit')));
      expect(hiResult, isNot(contains('ओटीपी कोड')));
      expect(hiResult, isNot(contains('6-अंकों')));
      expect(enResult, contains('Invalid phone number format'));
    });

    test('sanitizeSendOtpError handles rate limits, invalid phone, network, and fallback', () {
      expect(
        PhoneLoginScreen.sanitizeSendOtpError(
          'over_sms_send_rate_limit: 429',
          isHi: false,
        ),
        contains('Too many attempts'),
      );
      expect(
        PhoneLoginScreen.sanitizeSendOtpError(
          'over_sms_send_rate_limit: 429',
          isHi: true,
        ),
        contains('बहुत अधिक प्रयास'),
      );

      expect(
        PhoneLoginScreen.sanitizeSendOtpError(
          'bad_phone_number',
          isHi: false,
        ),
        contains('Invalid phone number format'),
      );
      expect(
        PhoneLoginScreen.sanitizeSendOtpError(
          'bad_phone_number',
          isHi: true,
        ),
        contains('अमान्य मोबाइल नंबर प्रारूप'),
      );

      expect(
        PhoneLoginScreen.sanitizeSendOtpError(
          'SocketException: connection failed',
          isHi: false,
        ),
        contains('Network error'),
      );
      expect(
        PhoneLoginScreen.sanitizeSendOtpError(
          'SocketException: connection failed',
          isHi: true,
        ),
        contains('नेटवर्क त्रुटि'),
      );

      expect(
        PhoneLoginScreen.sanitizeSendOtpError(
          'Some unexpected backend error',
          isHi: false,
        ),
        contains('Failed to send OTP'),
      );
      expect(
        PhoneLoginScreen.sanitizeSendOtpError(
          'Some unexpected backend error',
          isHi: true,
        ),
        contains('ओटीपी भेजने में विफल'),
      );
    });

    test('sanitizeVerifyOtpError handles expired OTP, invalid token, rate limits, and network', () {
      expect(
        PhoneLoginScreen.sanitizeVerifyOtpError(
          'Token has expired',
          isHi: false,
        ),
        contains('OTP has expired'),
      );
      expect(
        PhoneLoginScreen.sanitizeVerifyOtpError(
          'Token has expired',
          isHi: true,
        ),
        contains('ओटीपी की समय सीमा समाप्त'),
      );

      expect(
        PhoneLoginScreen.sanitizeVerifyOtpError(
          'AuthApiException(message: invalid token, code: 403)',
          isHi: false,
        ),
        contains('Invalid or expired OTP code'),
      );
      expect(
        PhoneLoginScreen.sanitizeVerifyOtpError(
          'AuthApiException(message: invalid token, code: 403)',
          isHi: true,
        ),
        contains('अमान्य या समाप्त ओटीपी कोड'),
      );

      expect(
        PhoneLoginScreen.sanitizeVerifyOtpError(
          '429 rate limit reached',
          isHi: false,
        ),
        contains('Too many attempts'),
      );

      expect(
        PhoneLoginScreen.sanitizeVerifyOtpError(
          'ClientException with connection timeout',
          isHi: false,
        ),
        contains('Network error'),
      );

      expect(
        PhoneLoginScreen.sanitizeVerifyOtpError(
          'Unknown verification error',
          isHi: false,
        ),
        contains('Verification failed'),
      );
    });

    test('sanitizeResendOtpError handles rate limit, network, and fallback', () {
      expect(
        PhoneLoginScreen.sanitizeResendOtpError(
          'sms limit reached',
          isHi: false,
        ),
        contains('Too many attempts'),
      );
      expect(
        PhoneLoginScreen.sanitizeResendOtpError(
          'SocketException',
          isHi: false,
        ),
        contains('Network error'),
      );
      expect(
        PhoneLoginScreen.sanitizeResendOtpError(
          'Server internal error',
          isHi: false,
        ),
        contains('Failed to resend OTP'),
      );
    });
  });

  group('PhoneLoginScreen UI error state management', () {
    Widget buildTestWidget({
      bool startAtOtp = false,
      String? initialPhone,
      AppState? appState,
    }) {
      return ChangeNotifierProvider<AppState>.value(
        value: appState ?? AppState(),
        child: MaterialApp(
          initialRoute: '/login',
          onGenerateRoute: (settings) {
            if (settings.name == '/login') {
              return MaterialPageRoute(
                builder: (_) => PhoneLoginScreen(
                  startAtOtp: startAtOtp,
                  initialPhoneNumber: initialPhone,
                ),
                settings: settings,
              );
            }
            if (settings.name == '/') {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('Home Screen')),
                settings: settings,
              );
            }
            return null;
          },
        ),
      );
    }

    testWidgets('entering valid number 9582198165 does not show validation error', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '9582198165');
      await tester.pump();

      expect(find.text('Please enter a valid 10-digit mobile number'), findsNothing);
      expect(find.text('Please enter a valid 10-digit mobile number starting with 6-9'), findsNothing);
    });

    testWidgets('pasting with +91 country code normalizes to 10 digits and accepts 9582198165', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '+91 9582198165');
      await tester.pump();

      // Controller should contain the normalized 10 digits
      expect(find.text('9582198165'), findsOneWidget);
      expect(find.text('Please enter a valid 10-digit mobile number'), findsNothing);
    });

    testWidgets('shows pattern error when 10 digits start with 1-5', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '1234567890');
      await tester.pump();

      final sendOtpButtonFinder = find.widgetWithText(ElevatedButton, 'Send OTP');
      await tester.tap(sendOtpButtonFinder);
      await tester.pump();

      expect(find.text('Please enter a valid 10-digit mobile number starting with 6-9'), findsOneWidget);
    });

    testWidgets('clears error message when user modifies phone number via onChanged', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Enter fewer than 10 digits
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '98765');
      await tester.pump();

      // Tap Send OTP to trigger validation error
      final sendOtpButtonFinder = find.widgetWithText(ElevatedButton, 'Send OTP');
      await tester.tap(sendOtpButtonFinder);
      await tester.pump();

      // Verify validation error is displayed
      expect(find.text('Please enter a valid 10-digit mobile number'), findsOneWidget);

      // Modify the text field by adding a digit (onChanged trigger)
      await tester.enterText(textFieldFinder, '987654');
      await tester.pump();

      // Error message should be immediately removed
      expect(find.text('Please enter a valid 10-digit mobile number'), findsNothing);
    });

    testWidgets('clears error message when user taps clear button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Enter invalid number and trigger validation error
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '123');
      await tester.pump();

      final sendOtpButtonFinder = find.widgetWithText(ElevatedButton, 'Send OTP');
      await tester.tap(sendOtpButtonFinder);
      await tester.pump();

      expect(find.text('Please enter a valid 10-digit mobile number'), findsOneWidget);

      // Tap the clear (X) button
      final clearButtonFinder = find.byIcon(Icons.close_rounded);
      expect(clearButtonFinder, findsOneWidget);
      await tester.tap(clearButtonFinder);
      await tester.pump();

      // Both error message and text should be cleared
      expect(find.text('Please enter a valid 10-digit mobile number'), findsNothing);
      expect(find.text('123'), findsNothing);
    });

    testWidgets('Change Number on OTP step clears errors and transitions to phone entry', (tester) async {
      await tester.pumpWidget(buildTestWidget(startAtOtp: true, initialPhone: '9876543210'));
      await tester.pump();

      // Confirm we are on OTP screen
      expect(find.text('OTP Verification'), findsOneWidget);

      // Tap "Change Number"
      final changeNumberFinder = find.text('Change Number');
      expect(changeNumberFinder, findsOneWidget);
      await tester.tap(changeNumberFinder);
      await tester.pump();

      // Should now be on Phone Login screen
      expect(find.text('Phone Login'), findsOneWidget);
      expect(find.text('Send OTP'), findsOneWidget);

      // Verify no lingering errors exist
      expect(find.text('Invalid or expired OTP code. Please enter the correct 6-digit code.'), findsNothing);
      expect(find.text('Please enter a valid 10-digit mobile number'), findsNothing);
    });

    testWidgets('entering OTP 123456 triggers hackathon demo bypass, authenticates AppState and navigates to home', (tester) async {
      final appState = AppState();
      expect(appState.isAuthenticated, isFalse);

      await tester.pumpWidget(buildTestWidget(
        startAtOtp: true,
        initialPhone: '9876543210',
        appState: appState,
      ));
      await tester.pump();

      expect(find.text('OTP Verification'), findsOneWidget);

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(6));

      // Enter digits 1 through 6 in order
      for (int i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), '${i + 1}');
        await tester.pump();
      }

      await tester.pump(const Duration(milliseconds: 300));

      // AppState must be authenticated via bypass
      expect(appState.isAuthenticated, isTrue);

      // Must have navigated to home route ('/')
      expect(find.text('Home Screen'), findsOneWidget);
    });
  });
}
