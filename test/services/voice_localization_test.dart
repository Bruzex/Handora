import 'package:flutter_test/flutter_test.dart';
import 'package:bruprog_handora/l10n/strings.dart';
import 'package:bruprog_handora/providers/app_state.dart';
import 'package:bruprog_handora/services/gemini_service.dart';
import 'package:bruprog_handora/services/stt_service.dart';
import 'package:bruprog_handora/services/voice_assistant_service.dart';

void main() {
  group('Language localeCode and BCP-47 mappings', () {
    test('all 7 languages have correct BCP-47 localeCode', () {
      expect(Language.en.localeCode, 'en-IN');
      expect(Language.hi.localeCode, 'hi-IN');
      expect(Language.mr.localeCode, 'mr-IN');
      expect(Language.ta.localeCode, 'ta-IN');
      expect(Language.te.localeCode, 'te-IN');
      expect(Language.gu.localeCode, 'gu-IN');
      expect(Language.bn.localeCode, 'bn-IN');
    });

    test('displayName returns proper native scripts for 7 languages', () {
      expect(Language.en.displayName, 'English');
      expect(Language.hi.displayName, 'हिन्दी');
      expect(Language.mr.displayName, 'मराठी');
      expect(Language.ta.displayName, 'தமிழ்');
      expect(Language.te.displayName, 'తెలుగు');
      expect(Language.gu.displayName, 'ગુજરાતી');
      expect(Language.bn.displayName, 'বাংলা');
    });
  });

  group('AppState selectedLanguage getter', () {
    test('selectedLanguage matches language', () {
      final appState = AppState();
      expect(appState.selectedLanguage, appState.language);

      appState.setLanguage(Language.gu);
      expect(appState.selectedLanguage, Language.gu);

      appState.setLanguage(Language.bn);
      expect(appState.selectedLanguage, Language.bn);
    });
  });

  group('VoiceAssistantService system instruction generation', () {
    test('buildSystemPrompt dynamically injects strict native script instruction', () {
      for (final lang in Language.values) {
        final prompt = VoiceAssistantService.buildSystemPrompt(lang);
        expect(
          prompt.startsWith(
            'You are a helpful assistant for Indian rural artisans. '
            'You must strictly reply in ${lang.displayName} native script.',
          ),
          isTrue,
        );
        expect(prompt.contains(lang.displayName), isTrue);
      }
    });
  });

  group('SttService locale configuration', () {
    test('getLocaleId returns language.localeCode for all languages', () {
      for (final lang in Language.values) {
        expect(SttService.getLocaleId(lang), lang.localeCode);
      }
    });

    test('listen passes localeId to mock speechToText', () async {
      String? capturedLocale;
      final mockStt = _MockSpeechToText((locale) => capturedLocale = locale);

      await SttService.listen(
        speechToText: mockStt,
        language: Language.ta,
      );

      expect(capturedLocale, 'ta-IN');

      await SttService.listen(
        speechToText: mockStt,
        language: Language.gu,
      );

      expect(capturedLocale, 'gu-IN');
    });
  });

  group('GeminiService formatGeminiError localized messages', () {
    test('returns localized messages for 429 quota error across all 7 languages', () {
      final quotaError = Exception('Error 429: Quota exceeded');
      for (final lang in Language.values) {
        final msg = GeminiService.formatGeminiError(quotaError, language: lang);
        expect(msg.isNotEmpty, isTrue);
      }
      expect(
        GeminiService.formatGeminiError(quotaError, language: Language.gu),
        contains('સર્વર હાલમાં વ્યસ્ત છે'),
      );
      expect(
        GeminiService.formatGeminiError(quotaError, language: Language.bn),
        contains('সার্ভার বর্তমানে ব্যস্ত'),
      );
    });
  });
}

class _MockSpeechToText {
  final void Function(String? localeId) onListen;
  _MockSpeechToText(this.onListen);

  Future<void> listen({
    String? localeId,
    Function(dynamic)? onResult,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    onListen(localeId);
  }
}
