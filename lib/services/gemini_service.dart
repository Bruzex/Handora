import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  /// Analyzes a product image using Google Gemini API to extract title, Hindi title, description, category, and price.
  static Future<Map<String, dynamic>> analyzeProductImage(File imageFile) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not configured in .env');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    final body = {
      "contents": [
        {
          "parts": [
            {
              "text": """
You are an expert for Indian artisan products.
Look at this product photo and return ONLY a valid JSON object with these exact keys:
{
  "title_en": "short English title",
  "title_hi": "short Hindi title",
  "description": "2-3 sentence description in simple English",
  "category": "one of: Pottery, Textiles, Woodwork, Jewelry, Metalwork, Other",
  "estimated_price_inr": 450
}
Price should be realistic for handmade Indian products in INR.
Do not add any extra text outside the JSON.
"""
            },
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Image
              }
            }
          ]
        }
      ]
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

    // Clean JSON markdown code blocks if returned
    final cleaned = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    return jsonDecode(cleaned) as Map<String, dynamic>;
  }
}
