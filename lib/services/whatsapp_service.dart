import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/strings.dart';
import '../models/order.dart';

class WhatsAppService {
  /// Returns a formatted, user-friendly status string with an emoji.
  static String formatStatusLabel(String status, Language language) {
    final isHi = language == Language.hi;
    return switch (status.toLowerCase()) {
      'new' || 'new_order' => isHi ? 'ऑर्डर प्राप्त हुआ 🛍️' : 'Order Confirmed 🛍️',
      'processing' => isHi ? 'तैयार किया जा रहा है 🎨📦' : 'In Progress / Packing 🎨📦',
      'shipped' => isHi ? 'भेज दिया गया है (रास्ते में) 🚚💨' : 'Dispatched & Shipped 🚚💨',
      'delivered' => isHi ? 'सफलतापूर्वक डिलीवर हो गया 🎉✅' : 'Delivered 🎉✅',
      'cancelled' => isHi ? 'ऑर्डर रद्द किया गया ❌' : 'Order Cancelled ❌',
      _ => status,
    };
  }

  /// Cleans and ensures a valid 12-digit Indian phone number (or international).
  static String sanitizePhoneNumber(String phone) {
    var clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 10) {
      clean = '91$clean';
    }
    return clean;
  }

  /// Builds a friendly bilingual WhatsApp update message for artisans to send to buyers.
  static String buildOrderMessage({
    required Order order,
    String? customNote,
    Language language = Language.en,
  }) {
    final isHi = language == Language.hi;
    final productName = isHi ? order.productHi : order.productEn;
    final statusText = formatStatusLabel(order.status, language);

    final buffer = StringBuffer();
    if (isHi) {
      buffer.writeln('नमस्ते ${order.buyerName}! 🌸');
      buffer.writeln('हंडोरा (Handora) कारीगर स्टोर से आपके ऑर्डर का अपडेट:');
      buffer.writeln('');
      buffer.writeln('📦 ऑर्डर आईडी: #${order.id}');
      buffer.writeln('🏷️ उत्पाद: $productName (मात्रा: ${order.quantity})');
      buffer.writeln('💰 कुल राशि: ₹${order.amountInRupees}');
      buffer.writeln('🚚 स्थिति: $statusText');
      if (customNote != null && customNote.trim().isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('📝 कारीगर का संदेश: ${customNote.trim()}');
      }
      buffer.writeln('');
      buffer.writeln('भारतीय स्थानीय कारीगरों का समर्थन करने के लिए धन्यवाद! 🙏✨');
    } else {
      buffer.writeln('Hello ${order.buyerName}! 🌸');
      buffer.writeln('Greetings from Handora Artisan Store:');
      buffer.writeln('');
      buffer.writeln('📦 Order ID: #${order.id}');
      buffer.writeln('🏷️ Item: $productName (Qty: ${order.quantity})');
      buffer.writeln('💰 Total Amount: ₹${order.amountInRupees}');
      buffer.writeln('🚚 Status: $statusText');
      if (customNote != null && customNote.trim().isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('📝 Note from Artisan: ${customNote.trim()}');
      }
      buffer.writeln('');
      buffer.writeln('Thank you for supporting local Indian artisans! 🙏✨');
    }

    return buffer.toString();
  }

  /// Launches WhatsApp via deep link `https://wa.me/...`.
  static Future<bool> sendWhatsAppOrderUpdate({
    required Order order,
    String? customNote,
    Language language = Language.en,
  }) async {
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
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        return true;
      }
    } catch (e) {
      debugPrint('❌ WhatsApp launch failed: $e');
      return false;
    }
  }
}
