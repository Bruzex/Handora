import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import 'database_helper.dart';
import 'supabase_service.dart';

class GeminiService {
  /// Fetches the artisan's last [limit] products (category + price + title) from local SQLite or Supabase.
  /// Returns an empty list if no products exist or on any error (guaranteed never to throw).
  static Future<List<Map<String, dynamic>>> fetchArtisanProductHistory({
    String? userId,
    int limit = 5,
  }) async {
    // 1. Try local SQLite database first (offline-first & low latency)
    try {
      final db = DatabaseHelper.instance;
      List<Product> products = [];
      if (userId != null && userId.isNotEmpty) {
        products = await db.queryProductsForUser(userId);
      } else {
        products = await db.queryAllProducts();
      }

      final validLocal = products
          .where((p) => p.priceInRupees > 0 && p.status == ProductStatus.live)
          .take(limit)
          .map((p) => {
                'title': p.nameEn,
                'category': p.category,
                'price_inr': p.priceInRupees,
              })
          .toList();

      if (validLocal.isNotEmpty) {
        debugPrint('📦 Loaded ${validLocal.length} history items from local DB for pricing');
        return validLocal;
      }
    } catch (e) {
      debugPrint('⚠️ Local history fetch for pricing failed (falling back): $e');
    }

    // 2. Try Supabase cloud database if local was empty or failed
    try {
      final remote = await SupabaseService.fetchProducts();
      final validRemote = remote
          .where((p) => p.priceInRupees > 0 && p.status == ProductStatus.live)
          .take(limit)
          .map((p) => {
                'title': p.nameEn,
                'category': p.category,
                'price_inr': p.priceInRupees,
              })
          .toList();

      if (validRemote.isNotEmpty) {
        debugPrint('☁️ Loaded ${validRemote.length} history items from Supabase for pricing');
        return validRemote;
      }
    } catch (e) {
      debugPrint('⚠️ Supabase history fetch for pricing failed (falling back): $e');
    }

    return [];
  }

  /// Formats Gemini API errors into clean, bilingual, user-friendly messages for SnackBars.
  static String formatGeminiError(dynamic error, {bool? isHi}) {
    final errStr = error.toString();
    if (errStr.contains('429') ||
        errStr.toLowerCase().contains('quota exceeded') ||
        errStr.contains('RESOURCE_EXHAUSTED')) {
      if (isHi == true) {
        return 'सर्वर अभी व्यस्त है। कृपया 1 मिनट बाद पुनः प्रयास करें।';
      } else if (isHi == false) {
        return 'Server is currently busy. Please wait a minute and try again.';
      }
      return 'Server is currently busy. Please wait a minute and try again. / सर्वर अभी व्यस्त है। कृपया 1 मिनट बाद पुनः प्रयास करें।';
    }

    if (errStr.toLowerCase().contains('api_key') ||
        errStr.contains('GEMINI_API_KEY')) {
      if (isHi == true) {
        return 'AI सेवा कॉन्फ़िगरेशन समस्या। कृपया पुनः प्रयास करें।';
      } else if (isHi == false) {
        return 'AI service configuration issue. Please check API key.';
      }
      return 'AI service configuration issue. / AI सेवा कॉन्फ़िगरेशन समस्या।';
    }

    if (isHi == true) {
      return 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';
    } else if (isHi == false) {
      return 'Something went wrong. Please try again.';
    }
    return 'Something went wrong. Please try again. / कुछ गलत हो गया। कृपया पुनः प्रयास करें।';
  }

  /// Analyzes a product image using Google Gemini API with optional history-aware pricing.
  ///
  /// Incorporates the artisan's recent pricing history (up to 5 products) as a reference
  /// baseline. If history is unavailable, empty, or fails to fetch, it falls back seamlessly
  /// to local Indian market rates without crashing.
  static Future<Map<String, dynamic>> analyzeProductImage(
    File imageFile, {
    String? userId,
    List<Map<String, dynamic>>? history,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not configured in .env');
    }

    // Try fetching pricing history if not explicitly provided
    List<Map<String, dynamic>> pricingHistory = history ?? [];
    if (pricingHistory.isEmpty) {
      try {
        pricingHistory = await fetchArtisanProductHistory(userId: userId);
      } catch (e) {
        debugPrint('⚠️ Pricing history fetch bypassed: $e');
        pricingHistory = [];
      }
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=$apiKey',
    );

    final String historyBlock;
    if (pricingHistory.isNotEmpty) {
      final historyFormatted = pricingHistory.map((item) {
        final title = item['title'] ?? item['name'] ?? '';
        final cat = item['category'] ?? 'General';
        final price = item['price_inr'] ?? item['price'] ?? 0;
        return title.toString().isNotEmpty
            ? '- $title (Category: $cat): ₹$price'
            : '- Category: $cat: ₹$price';
      }).join('\n');

      historyBlock = """

Artisan's recent product pricing history:
$historyFormatted

Pricing guidelines using history:
- Use the image as the PRIMARY source of product identity.
- Use the artisan's pricing history ONLY as a reference baseline for similar items/categories from this specific artisan.
- If the item in the image belongs to a similar category, calibrate the new item's price relative to their past pricing.
- If the history is empty, irrelevant, or from unrelated categories, estimate a fair local Indian market price for handmade goods.
""";
    } else {
      historyBlock = """

No artisan pricing history is available. Estimate a fair local Indian market price for handmade goods based solely on the item shown in the image.
""";
    }

    final promptText = """
You are a product cataloging and pricing expert for Indian local artisans and craftspeople selling on ONDC / Handora.

Look at the image carefully and identify what the item actually is.

Pricing instructions (CRITICAL):
- Evaluate the item strictly at local Indian market / artisan bazaar / mandi rates in INR.
- Think about what a local artisan, street vendor, or village bazaar charges, NOT luxury retail or export prices.
- Avoid luxury/export fantasy pricing. Prefer practical village/town market price range.
- "price_inr" MUST be a realistic, positive integer in INR (e.g. 80, 150, 250, 450, 800).
$historyBlock
Return ONLY a valid, parseable JSON object with NO markdown codeblocks, matching this exact schema:
{
  "title_en": "accurate concise English name",
  "title_hi": "accurate concise Hindi name",
  "description_en": "2-3 sentence honest English description highlighting materials and craft",
  "description_hi": "2-3 sentence natural Hindi description",
  "category": "one of: Pottery, Textiles, Woodwork, Jewelry, Metalwork, Food, Other",
  "price_inr": 250
}

Rules:
- Be accurate about what the item is. If it is food, call it food. If it is a pot, call it a pot.
- Do NOT force items into "artisan handicraft" if they are clearly something else.
- Do NOT inflate prices. Think local Indian wholesale/street rates, not retail or export.
- "price_inr" MUST be a positive integer in INR.
- Return pure JSON only, without any wrapping markdown blocks or explanations.
""";

    final body = {
      "contents": [
        {
          "parts": [
            {"text": promptText},
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Image,
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.2,
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No analysis returned by Gemini.');
    }

    final text = candidates[0]['content']['parts'][0]['text'] as String;

    final cleaned = text
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .trim();

    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        parsed = jsonDecode(cleaned.substring(start, end + 1)) as Map<String, dynamic>;
      } else {
        rethrow;
      }
    }

    // Ensure price_inr is a positive integer
    final rawPrice = parsed['price_inr'] ?? parsed['estimated_price_inr'];
    int priceInr = 500;
    if (rawPrice is num) {
      priceInr = rawPrice.toInt();
    } else if (rawPrice is String) {
      priceInr = int.tryParse(rawPrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 500;
    }
    if (priceInr <= 0) priceInr = 100;

    final descEn = (parsed['description_en'] ?? parsed['description'] ?? '').toString();
    final descHi = (parsed['description_hi'] ?? '').toString();
    final titleEn = (parsed['title_en'] ?? 'Handmade Product').toString();
    final titleHi = (parsed['title_hi'] ?? 'हस्तशिल्प उत्पाद').toString();
    final category = (parsed['category'] ?? 'Other').toString();

    return {
      'title_en': titleEn,
      'title_hi': titleHi,
      'description_en': descEn,
      'description_hi': descHi,
      'category': category,
      'price_inr': priceInr,
      // Backward compatibility keys
      'estimated_price_inr': priceInr,
      'description': descEn.isNotEmpty ? descEn : descHi,
    };
  }

  /// Processes a voice recording containing edit instructions for an existing product.
  static Future<Map<String, dynamic>> processVoiceProductEdit({
    required File audioFile,
    required Product currentProduct,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not configured in .env');
    }

    final bytes = await audioFile.readAsBytes();
    final base64Audio = base64Encode(bytes);

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=$apiKey',
    );

    final promptText = """
You are an AI assistant updating product catalog details for a local artisan on ONDC.
Listen carefully to the user's spoken voice instructions in this audio clip (which may be in Hindi, English, or Hinglish).
Compare the user's voice instructions with the current product details below:
- Current Title (EN): ${currentProduct.nameEn}
- Current Title (HI): ${currentProduct.nameHi}
- Current Price: ₹${currentProduct.priceInRupees}
- Current Description: ${currentProduct.description.isNotEmpty ? currentProduct.description : 'Handcrafted artisan product'}
- Current Category: ${currentProduct.category}

Instructions:
1. Identify any requested changes to price, title, or description from the audio.
2. If the user mentions a new price, update "price_in_rupees" with that integer (in INR).
3. If the user mentions changing the title or description, update "name_en", "name_hi", or "description".
4. If a field was NOT changed or mentioned in the audio, KEEP the current value.
5. Create a concise, natural confirmation message of what was changed in English ("summary_en") and Hindi ("summary_hi").
   Example: "Product price updated to ₹500" / "कीमत बदलकर ₹500 कर दी गई है"

Output STRICTLY valid JSON with no markdown code blocks, matching this schema:
{
  "name_en": "${currentProduct.nameEn}",
  "name_hi": "${currentProduct.nameHi}",
  "price_in_rupees": ${currentProduct.priceInRupees},
  "description": "${currentProduct.description}",
  "category": "${currentProduct.category}",
  "summary_en": "Product details updated",
  "summary_hi": "उत्पाद की जानकारी अपडेट कर दी गई है"
}
""";

    final body = {
      "contents": [
        {
          "parts": [
            {"text": promptText},
            {
              "inlineData": {
                "mimeType": "audio/mp4",
                "data": base64Audio,
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.2,
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini voice edit error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No response returned by Gemini.');
    }

    final text = candidates[0]['content']['parts'][0]['text'] as String;
    final cleaned = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    return jsonDecode(cleaned) as Map<String, dynamic>;
  }
}
