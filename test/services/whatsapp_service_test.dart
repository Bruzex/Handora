import 'package:flutter_test/flutter_test.dart';
import 'package:bruprog_handora/l10n/strings.dart';
import 'package:bruprog_handora/models/order.dart';
import 'package:bruprog_handora/services/whatsapp_service.dart';

void main() {
  group('WhatsAppService - Phone Validation & Sanitization', () {
    test('validates 10-digit Indian numbers', () {
      expect(WhatsAppService.isValidPhoneNumber('9876543210'), isTrue);
      expect(WhatsAppService.sanitizePhoneNumber('9876543210'), '919876543210');
    });

    test('validates 12-digit Indian numbers with country code', () {
      expect(WhatsAppService.isValidPhoneNumber('919876543210'), isTrue);
      expect(WhatsAppService.sanitizePhoneNumber('919876543210'), '919876543210');
      expect(WhatsAppService.sanitizePhoneNumber('+91 98765-43210'), '919876543210');
    });

    test('validates 11-digit numbers with leading 0', () {
      expect(WhatsAppService.isValidPhoneNumber('09876543210'), isTrue);
      expect(WhatsAppService.sanitizePhoneNumber('09876543210'), '919876543210');
    });

    test('rejects empty, short, or invalid numbers', () {
      expect(WhatsAppService.isValidPhoneNumber(''), isFalse);
      expect(WhatsAppService.isValidPhoneNumber(null), isFalse);
      expect(WhatsAppService.isValidPhoneNumber('12345'), isFalse);
      expect(WhatsAppService.isValidPhoneNumber('abcdef'), isFalse);
    });
  });

  group('WhatsAppService - Message Construction', () {
    test('builds English message with exact prompt specifications', () {
      const order = Order(
        id: 'HND-2479',
        quantity: 1,
        productEn: 'Wooden Spice Box',
        productHi: 'लकड़ी का मसाला डिब्बा',
        amountInRupees: 350,
        placedAt: 'Yesterday',
        thumbnail: 'assets/images/box.jpg',
        status: 'processing',
        buyerName: '', // no buyer name
        buyerPhone: '919876543210',
      );

      final message = WhatsAppService.buildOrderMessage(
        order: order,
        language: Language.en,
      );

      expect(
        message,
        'Hello, your Handora order #HND-2479 for Wooden Spice Box (₹350) is now Processing. We will update you again soon. — Handora Artisan',
      );
    });

    test('builds Hindi message with exact prompt specifications', () {
      const order = Order(
        id: 'HND-2479',
        quantity: 1,
        productEn: 'Wooden Spice Box',
        productHi: 'Wooden Spice Box',
        amountInRupees: 350,
        placedAt: 'Yesterday',
        thumbnail: 'assets/images/box.jpg',
        status: 'processing',
        buyerName: '', // no buyer name
        buyerPhone: '919876543210',
      );

      final message = WhatsAppService.buildOrderMessage(
        order: order,
        language: Language.hi,
      );

      expect(
        message,
        'नमस्ते, आपका Handora ऑर्डर #HND-2479 (Wooden Spice Box, ₹350) अब Processing में है। जल्द अपडेट देंगे। — Handora',
      );
    });

    test('includes buyer name when available and not default placeholder', () {
      const order = Order(
        id: 'HND-2481',
        quantity: 1,
        productEn: 'Handmade Scarf',
        productHi: 'हाथ से बुना मफलर',
        amountInRupees: 850,
        placedAt: '10 min ago',
        thumbnail: 'assets/images/scarf.jpg',
        status: 'shipped',
        buyerName: 'Priya Sharma',
        buyerPhone: '919876543210',
      );

      final messageEn = WhatsAppService.buildOrderMessage(
        order: order,
        language: Language.en,
      );
      expect(
        messageEn,
        'Hello Priya Sharma, your Handora order #HND-2481 for Handmade Scarf (₹850) is now Shipped. We will update you again soon. — Handora Artisan',
      );

      final messageHi = WhatsAppService.buildOrderMessage(
        order: order,
        language: Language.hi,
      );
      expect(
        messageHi,
        'नमस्ते Priya Sharma, आपका Handora ऑर्डर #HND-2481 (हाथ से बुना मफलर, ₹850) अब Shipped है। जल्द अपडेट देंगे। — Handora',
      );
    });

    test('includes custom note when provided', () {
      const order = Order(
        id: 'HND-2480',
        quantity: 2,
        productEn: 'Handmade Clay Pot',
        productHi: 'हाथ से बना मिट्टी का बर्तन',
        amountInRupees: 900,
        placedAt: '2 hours ago',
        thumbnail: 'assets/images/clay_pot.jpg',
        status: 'processing',
        buyerName: 'Amit Verma',
        buyerPhone: '919812345678',
      );

      final messageEn = WhatsAppService.buildOrderMessage(
        order: order,
        customNote: 'Dispatched via Speed Post',
        language: Language.en,
      );
      expect(
        messageEn,
        'Hello Amit Verma, your Handora order #HND-2480 for Handmade Clay Pot (₹900) is now Processing. Note: Dispatched via Speed Post. We will update you again soon. — Handora Artisan',
      );

      final messageHi = WhatsAppService.buildOrderMessage(
        order: order,
        customNote: 'स्पीड पोस्ट से भेजा गया',
        language: Language.hi,
      );
      expect(
        messageHi,
        'नमस्ते Amit Verma, आपका Handora ऑर्डर #HND-2480 (हाथ से बना मिट्टी का बर्तन, ₹900) अब Processing में है। नोट: स्पीड पोस्ट से भेजा गया। जल्द अपडेट देंगे। — Handora',
      );
    });

    test('sendWhatsAppOrderUpdate returns invalidPhone when phone number is invalid', () async {
      const invalidOrder = Order(
        id: 'HND-9999',
        quantity: 1,
        productEn: 'Terracotta Vase',
        productHi: 'मिट्टी का फूलदान',
        amountInRupees: 500,
        placedAt: 'Just now',
        thumbnail: 'assets/images/vase.jpg',
        status: 'new',
        buyerName: 'Ravi Kumar',
        buyerPhone: '', // missing phone
      );

      final result = await WhatsAppService.sendWhatsAppOrderUpdate(order: invalidOrder);
      expect(result, WhatsAppResult.invalidPhone);
    });
  });
}
