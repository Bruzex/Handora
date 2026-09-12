import 'package:flutter/foundation.dart';
import '../l10n/strings.dart';

/// Helper service for Speech-to-Text configuration and execution.
/// Ensures all STT listen invocations explicitly pass the active language's [localeId]
/// matching [Language.localeCode] (e.g. 'hi-IN', 'gu-IN', 'bn-IN', etc.).
class SttService {
  /// Returns the BCP-47 locale ID string for the given language.
  static String getLocaleId(Language language) => language.localeCode;

  /// Starts listening on a SpeechToText instance with explicit [localeId] matching [language.localeCode].
  static Future<void> listen({
    dynamic speechToText,
    required Language language,
    Function(dynamic)? onResult,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    final localeId = language.localeCode;
    if (speechToText != null) {
      try {
        await speechToText.listen(
          localeId: localeId,
          onResult: onResult,
          listenFor: listenFor,
          pauseFor: pauseFor,
        );
      } catch (e) {
        debugPrint('⚠️ STT listen error for localeId $localeId: $e');
      }
    }
  }
}
