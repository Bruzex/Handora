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
    final isHi = language == Language.hi;
    return switch (status.toLowerCase()) {
      'new' || 'new_order' => isHi ? 'ऑर्डर प्राप्त हुआ 🛍️' : 'Order Confirmed 🛍️',
      'processing' => isHi ? 'तैयारी में 🎨📦' : 'In Progress / Processing 🎨📦',
      'shipped' => isHi ? 'भेज दिया गया (Shipped) 🚚💨' : 'Dispatched & Shipped 🚚💨',
      'delivered' => isHi ? 'डिलीवर हो गया 🎉✅' : 'Delivered 🎉✅',
      'cancelled' => isHi ? 'रद्द किया गया ❌' : 'Order Cancelled ❌',
      _ => status,
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
    if (digits.length == 11 && digits.startsWith('0')) {
      digits = '91${digits.substring(1)}';
    } else if (digits.length == 10) {
      digits = '91$digits';
    }
    return digits;
  }

  /// Builds a friendly bilingual WhatsApp update message using REAL product data,
  /// order ID, price, status, buyer name, and optional custom note.
  ///
  /// EN format:
  /// "Hello, your Handora order #HND-2479 for Wooden Spice Box (₹350) is now Processing. We will update you again soon. — Handora Artisan"
  ///
  /// HI format:
  /// "नमस्ते, आपका Handora ऑर्डर #HND-2479 (Wooden Spice Box, ₹350) अब Processing में है। जल्द अपडेट देंगे। — Handora"
  static String buildOrderMessage({
    required Order order,
    String? customNote,
    Language language = Language.en,
  }) {
    final isHi = language == Language.hi;

    // Real product title from order (fallback gracefully if empty)
    final productTitle = isHi
        ? (order.productHi.trim().isNotEmpty
            ? order.productHi.trim()
            : (order.productEn.trim().isNotEmpty
                ? order.productEn.trim()
                : 'Handicraft Item'))
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

    if (isHi) {
      final greeting = hasBuyerName ? 'नमस्ते $trimmedBuyer,' : 'नमस्ते,';
      final statusPhrase = formatStatusHiPhrase(order.status);
      final notePart = note != null ? ' नोट: $note।' : '';
      return '$greeting आपका Handora ऑर्डर $orderId ($productTitle, ₹$price) $statusPhrase$notePart जल्द अपडेट देंगे। — Handora';
    } else {
      final greeting = hasBuyerName ? 'Hello $trimmedBuyer,' : 'Hello,';
      final statusEn = formatStatusEn(order.status);
      final notePart = note != null ? ' Note: $note.' : '';
      return '$greeting your Handora order $orderId for $productTitle (₹$price) is now $statusEn.$notePart We will update you again soon. — Handora Artisan';
    }
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
