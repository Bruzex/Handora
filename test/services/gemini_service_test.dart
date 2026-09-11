import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bruprog_handora/models/product.dart';
import 'package:bruprog_handora/services/database_helper.dart';
import 'package:bruprog_handora/services/gemini_service.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dotenv.testLoad(fileInput: '''
SUPABASE_URL=https://mock.supabase.co
SUPABASE_ANON_KEY=mock-key
GEMINI_API_KEY=mock-gemini-key
''');
  });

  group('GeminiService - formatGeminiError', () {
    test('formats 429 quota error in bilingual, EN, and HI', () {
      const quotaErr = 'Exception: Gemini error (429): Quota exceeded for resource';

      final enMsg = GeminiService.formatGeminiError(quotaErr, isHi: false);
      expect(enMsg, contains('busy'));

      final hiMsg = GeminiService.formatGeminiError(quotaErr, isHi: true);
      expect(hiMsg, contains('व्यस्त'));

      final bilingual = GeminiService.formatGeminiError(quotaErr);
      expect(bilingual, contains('/'));
    });

    test('formats API key error', () {
      const apiKeyErr = 'Exception: GEMINI_API_KEY is not configured';

      final enMsg = GeminiService.formatGeminiError(apiKeyErr, isHi: false);
      expect(enMsg, contains('AI service configuration'));

      final hiMsg = GeminiService.formatGeminiError(apiKeyErr, isHi: true);
      expect(hiMsg, contains('AI सेवा कॉन्फ़िगरेशन'));
    });

    test('formats generic error fallback', () {
      const genericErr = 'Exception: Unknown error occurred';

      final enMsg = GeminiService.formatGeminiError(genericErr, isHi: false);
      expect(enMsg, 'Something went wrong. Please try again.');

      final hiMsg = GeminiService.formatGeminiError(genericErr, isHi: true);
      expect(hiMsg, 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।');
    });
  });

  group('GeminiService - fetchArtisanProductHistory', () {
    test('fetches up to 5 valid products from local SQLite without throwing', () async {
      final db = DatabaseHelper.instance;
      // Insert test products
      await db.insertProduct(const Product(
        id: 'test-p1',
        nameEn: 'Handmade Shawl',
        nameHi: 'हाथ की शॉल',
        priceInRupees: 650,
        category: 'Textiles',
        status: ProductStatus.live,
        image: 'assets/images/scarf.jpg',
        userId: 'artisan-1',
      ));

      await db.insertProduct(const Product(
        id: 'test-p2',
        nameEn: 'Clay Diya',
        nameHi: 'मिट्टी का दीया',
        priceInRupees: 120,
        category: 'Pottery',
        status: ProductStatus.live,
        image: 'assets/images/clay_pot.jpg',
        userId: 'artisan-1',
      ));

      final history = await GeminiService.fetchArtisanProductHistory(userId: 'artisan-1', limit: 5);

      expect(history, isNotEmpty);
      expect(history.length, lessThanOrEqualTo(5));
      expect(history.first['category'], isNotNull);
      expect(history.first['price_inr'], isPositive);
    });

    test('returns empty list gracefully when user has no products', () async {
      final history = await GeminiService.fetchArtisanProductHistory(userId: 'non-existent-user-xyz');
      expect(history, isEmpty);
    });
  });
}
