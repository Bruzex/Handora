import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/strings.dart';
import '../models/order.dart';

enum WhatsAppResult {
  success,
  invalidPhone,
  launchFailed,
}

class WhatsAppService {
  /// Returns a formatted, user-friendly status string with an emoji (for UI chips/snackbars).
  static String formatStatusLabel(String status, Language language) {
    return switch (language) {
      Language.hi => switch (status.toLowerCase()) {
          'new' || 'new_order' => 'ऑर्डर प्राप्त हुआ 🛍️',
          'processing' => 'तैयारी में 🎨📦',
          'shipped' => 'भेज दिया गया (Shipped) 🚚💨',
          'delivered' => 'डिलीवर हो गया 🎉✅',
          'cancelled' => 'रद्द किया गया ❌',
          _ => status,
        },
      Language.mr => switch (status.toLowerCase()) {
          'new' || 'new_order' => 'नवीन ऑर्डर प्राप्त 🛍️',
          'processing' => 'तयारी सुरू आहे 🎨📦',
          'shipped' => 'पाठवले गेले (Shipped) 🚚💨',
          'delivered' => 'वितरित झाले 🎉✅',
          'cancelled' => 'रद्द केले ❌',
          _ => status,
        },
      Language.ta => switch (status.toLowerCase()) {
          'new' || 'new_order' => 'ஆர்டர் உறுதி செய்யப்பட்டது 🛍️',
          'processing' => 'தயாரிப்பில் உள்ளது 🎨📦',
          'shipped' => 'அனுப்பப்பட்டது (Shipped) 🚚💨',
          'delivered' => 'விநியோகிக்கப்பட்டது 🎉✅',
          'cancelled' => 'ஆர்டர் ரத்து செய்யப்பட்டது ❌',
          _ => status,
        },
      Language.te => switch (status.toLowerCase()) {
          'new' || 'new_order' => 'ఆర్డర్ నిర్ధారించబడింది 🛍️',
          'processing' => 'ప్రాసెసింగ్ లో ఉంది 🎨📦',
          'shipped' => 'రవాణా చేయబడింది (Shipped) 🚚💨',
          'delivered' => 'డెలివరీ చేయబడింది 🎉✅',
          'cancelled' => 'రద్దు చేయబడింది ❌',
          _ => status,
        },
      Language.gu => switch (status.toLowerCase()) {
          'new' || 'new_order' => 'ઓર્ડર મળ્યો 🛍️',
          'processing' => 'પ્રોસેસિંગમાં છે 🎨📦',
          'shipped' => 'મોકલી દેવાયો (Shipped) 🚚💨',
          'delivered' => 'ડિલિવર થઈ ગયો 🎉✅',
          'cancelled' => 'ઓર્ડર રદ થયો ❌',
          _ => status,
        },
      Language.bn => switch (status.toLowerCase()) {
          'new' || 'new_order' => 'অর্ডার নিশ্চিত হয়েছে 🛍️',
          'processing' => 'প্রক্রিয়াকরণ চলছে 🎨📦',
          'shipped' => 'পাঠানো হয়েছে (Shipped) 🚚💨',
          'delivered' => 'পৌঁছে গেছে 🎉✅',
          'cancelled' => 'অর্ডার বাতিল হয়েছে ❌',
          _ => status,
        },
      Language.en => switch (status.toLowerCase()) {
          'new' || 'new_order' => 'Order Confirmed 🛍️',
          'processing' => 'In Progress / Processing 🎨📦',
          'shipped' => 'Dispatched & Shipped 🚚💨',
          'delivered' => 'Delivered 🎉✅',
          'cancelled' => 'Order Cancelled ❌',
          _ => status,
        },
    };
  }

  /// Formats the order status for English messages (e.g. Processing, Shipped, Delivered).
  static String formatStatusEn(String status) {
    return switch (status.toLowerCase()) {
      'new' || 'new_order' => 'Confirmed',
      'processing' => 'Processing',
      'shipped' => 'Shipped',
      'delivered' => 'Delivered',
      'cancelled' => 'Cancelled',
      _ => status.isNotEmpty
          ? '${status[0].toUpperCase()}${status.substring(1)}'
          : status,
    };
  }

  /// Formats the order status into a natural Hindi phrase (e.g. 'अब Processing में है।').
  static String formatStatusHiPhrase(String status) {
    return switch (status.toLowerCase()) {
      'processing' => 'अब Processing में है।',
      'shipped' => 'अब Shipped है।',
      'delivered' => 'अब Delivered है।',
      'cancelled' => 'अब Cancelled है।',
      'new' || 'new_order' => 'अब Confirmed है।',
      _ => 'अब $status में है।',
    };
  }

  /// Checks whether phone number contains a valid digit length (10 to 15 digits).
  static bool isValidPhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) return false;
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 10 && digits.length <= 15;
  }

  /// Cleans and ensures a valid WhatsApp phone number (adds 91 for 10-digit Indian numbers).
  static String sanitizePhoneNumber(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) {
      digits = '91$digits';
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = '91${digits.substring(1)}';
    }
    return digits;
  }

  /// Builds a localized WhatsApp message with real product details.
  static String buildOrderMessage({
    required Order order,
    String? customNote,
    Language language = Language.en,
  }) {
    // Real product title from order (fallback gracefully if empty)
    final productTitle = (order.productHi.trim().isNotEmpty && language != Language.en)
        ? order.productHi.trim()
        : (order.productEn.trim().isNotEmpty
            ? order.productEn.trim()
            : (order.productHi.trim().isNotEmpty
                ? order.productHi.trim()
                : 'Handicraft Item'));

    // Real price
    final price = order.amountInRupees;

    // Order ID formatted with single '#' prefix
    final rawId = order.id.trim();
    final orderId = rawId.startsWith('#') ? rawId : '#$rawId';

    // Buyer greeting
    final trimmedBuyer = order.buyerName.trim();
    final hasBuyerName = trimmedBuyer.isNotEmpty &&
        trimmedBuyer.toLowerCase() != 'valued customer';

    // Optional artisan note
    final note = (customNote != null && customNote.trim().isNotEmpty)
        ? customNote.trim()
        : null;

    return switch (language) {
      Language.hi => () {
          final greeting = hasBuyerName ? 'नमस्ते $trimmedBuyer,' : 'नमस्ते,';
          final statusPhrase = formatStatusHiPhrase(order.status);
          final notePart = note != null ? ' नोट: $note।' : '';
          return '$greeting आपका Handora ऑर्डर $orderId ($productTitle, ₹$price) $statusPhrase$notePart जल्द अपडेट देंगे। — Handora';
        }(),
      Language.mr => () {
          final greeting = hasBuyerName ? 'नमस्कार $trimmedBuyer,' : 'नमस्कार,';
          final statusPhrase = formatStatusHiPhrase(order.status);
          final notePart = note != null ? ' टीप: $note.' : '';
          return '$greeting तुमची Handora ऑर्डर $orderId ($productTitle, ₹$price) $statusPhrase$notePart लवकरच अपडेट देऊ. — Handora';
        }(),
      Language.ta => () {
          final greeting = hasBuyerName ? 'வணக்கம் $trimmedBuyer,' : 'வணக்கம்,';
          final statusEn = formatStatusEn(order.status);
          final notePart = note != null ? ' குறிப்பு: $note.' : '';
          return '$greeting உங்கள் Handora ஆர்டர் $orderId ($productTitle, ₹$price) இப்போது $statusEn நிலைக்கு வந்துள்ளது.$notePart விரைவில் அடுத்த விவரம் தருகிறோம். — Handora';
        }(),
      Language.te => () {
          final greeting = hasBuyerName ? 'నమస్కారం $trimmedBuyer,' : 'నమస్కారం,';
          final statusEn = formatStatusEn(order.status);
          final notePart = note != null ? ' గమనిక: $note.' : '';
          return '$greeting మీ Handora ఆర్డర్ $orderId ($productTitle, ₹$price) ఇప్పుడు $statusEn లో ఉంది.$notePart త్వరలో మరిన్ని వివరాలు అందిస్తాము. — Handora';
        }(),
      Language.gu => () {
          final greeting = hasBuyerName ? 'નમસ્તે $trimmedBuyer,' : 'નમસ્તે,';
          final statusEn = formatStatusEn(order.status);
          final notePart = note != null ? ' નોંધ: $note.' : '';
          return '$greeting તમારો Handora ઓર્ડર $orderId ($productTitle, ₹$price) હવે $statusEn છે.$notePart ટૂંક સમયમાં અપડેટ આપીશું. — Handora';
        }(),
      Language.bn => () {
          final greeting = hasBuyerName ? 'নমস্কার $trimmedBuyer,' : 'নমস্কার,';
          final statusEn = formatStatusEn(order.status);
          final notePart = note != null ? ' বিশেষ দ্রষ্টব্য: $note.' : '';
          return '$greeting আপনার Handora অর্ডার $orderId ($productTitle, ₹$price) এখন $statusEn অবস্থায় রয়েছে।$notePart শীঘ্রই আপডেট জানাব। — Handora';
        }(),
      Language.en => () {
          final greeting = hasBuyerName ? 'Hello $trimmedBuyer,' : 'Hello,';
          final statusEn = formatStatusEn(order.status);
          final notePart = note != null ? ' Note: $note.' : '';
          return '$greeting your Handora order $orderId for $productTitle (₹$price) is now $statusEn.$notePart We will update you again soon. — Handora Artisan';
        }(),
    };
  }

  /// Launches WhatsApp via deep link `https://wa.me/<buyerPhone>?text=<urlencoded message>`.
  static Future<WhatsAppResult> sendWhatsAppOrderUpdate({
    required Order order,
    String? customNote,
    Language language = Language.en,
  }) async {
    if (!isValidPhoneNumber(order.buyerPhone)) {
      return WhatsAppResult.invalidPhone;
    }

    final cleanPhone = sanitizePhoneNumber(order.buyerPhone);
    final message = buildOrderMessage(
      order: order,
      customNote: customNote,
      language: language,
    );

    final urlString = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}';
    final uri = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) return WhatsAppResult.success;
      }
      // Fallback mode for desktop/browser/emulators
      final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      return launched ? WhatsAppResult.success : WhatsAppResult.launchFailed;
    } catch (e) {
      debugPrint('❌ WhatsApp launch failed: $e');
      return WhatsAppResult.launchFailed;
    }
  }
}
