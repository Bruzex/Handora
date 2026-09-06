import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../l10n/strings.dart';

enum VoiceAssistantError { micPermission, network, emptyRecording, noAnswer, generic }

class VoiceAssistantService {
  static const _systemPrompt =
      "You are Handora AI, a helpful voice assistant for Indian artisans who sell "
      "handicrafts on ONDC. Listen carefully to the audio clip below. The user is "
      "speaking a question or request — it may be in Hindi, English, or Hinglish. "
      "Understand exactly what they are asking, then provide a direct, specific, "
      "and helpful answer to THAT question. Do NOT give a generic greeting or "
      "introduction — jump straight into answering the user's actual query. "
      "Reply in the same language the user spoke in.";

  /// Matches any Devanagari character (U+0900–U+097F).
  static final _devanagariRegex = RegExp(r'[\u0900-\u097F]');

  final AudioRecorder _recorder = AudioRecorder();
  final FlutterTts _tts = FlutterTts();

  final ValueNotifier<bool> isSpeaking = ValueNotifier(false);
  final ValueNotifier<bool> ttsPaused = ValueNotifier(false);

  /// Set to true after the last `speak()` call if the requested Hindi
  /// voice was not available on the device. The UI can read this to show
  /// a snackbar once.
  bool hindiVoiceUnavailable = false;

  bool _ttsReady = false;
  String? _recordingPath;

  VoiceAssistantService() {
    _tts.setStartHandler(() {
      isSpeaking.value = true;
      ttsPaused.value = false;
    });
    _tts.setCompletionHandler(() {
      isSpeaking.value = false;
      ttsPaused.value = false;
    });
    _tts.setCancelHandler(() {
      isSpeaking.value = false;
      ttsPaused.value = false;
    });
    _tts.setPauseHandler(() {
      isSpeaking.value = false;
      ttsPaused.value = true;
    });
    _tts.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
      isSpeaking.value = false;
      ttsPaused.value = false;
    });

    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.awaitSpeakCompletion(true);
      _ttsReady = true;
    } catch (e) {
      debugPrint('TTS init warning: $e');
      _ttsReady = false;
    }
  }

  /// Returns true if `text` contains Devanagari script characters.
  static bool _containsDevanagari(String text) =>
      _devanagariRegex.hasMatch(text);

  /// Determines whether the text should be spoken in Hindi.
  /// Uses Devanagari presence as the primary signal, with the app language
  /// toggle as a secondary signal for ambiguous text (e.g. pure-English
  /// answers returned by Gemini in Hindi mode).
  static bool _isHindiAnswer(String text, Language appLanguage) {
    if (_containsDevanagari(text)) return true;
    // If the app toggle is set to Hindi but the answer has no Devanagari,
    // it's likely Hinglish written in Latin script — use Hindi voice
    // which handles both Hindi and English tokens better.
    if (appLanguage == Language.hi) return true;
    return false;
  }

  /// Attempts to set the TTS language to the given locale code.
  /// Returns `true` if the language was set successfully.
  Future<bool> _trySetLanguage(String locale) async {
    try {
      // isLanguageAvailable returns 1 on Android if available
      final available = await _tts.isLanguageAvailable(locale);
      if (available == true || available == 1) {
        final result = await _tts.setLanguage(locale);
        // setLanguage returns 1 on success (Android)
        return result == 1 || result == true;
      }
    } catch (e) {
      debugPrint('TTS setLanguage($locale) failed: $e');
    }
    return false;
  }

  /// Sets the TTS engine to the best available voice for the given text
  /// and app language. Returns `true` if a Hindi voice was needed but
  /// unavailable (so the caller can show a user-facing message).
  Future<bool> _setTtsLanguageForText(String text, Language appLanguage) async {
    final wantHindi = _isHindiAnswer(text, appLanguage);

    if (wantHindi) {
      // Try hi-IN first, then bare hi
      if (await _trySetLanguage('hi-IN')) return false;
      if (await _trySetLanguage('hi')) return false;

      // Hindi voice not available — fall back to English and report
      debugPrint('⚠️ Hindi TTS voice unavailable, falling back to English');
      await _trySetLanguage('en-IN');
      return true; // signal: Hindi was wanted but missing
    } else {
      // English answer
      if (await _trySetLanguage('en-IN')) return false;
      if (await _trySetLanguage('en-US')) return false;
      // Last resort: default engine language
      return false;
    }
  }

  Future<void> startRecording() async {
    final granted = await _recorder.hasPermission();
    if (!granted) throw VoiceAssistantError.micPermission;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/handora_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );
    _recordingPath = path;
  }

  Future<double> getMicLevel() async {
    if (_recordingPath == null) return 0;
    try {
      final amp = await _recorder.getAmplitude();
      return ((amp.current + 45) / 45).clamp(0.0, 1.0).toDouble();
    } catch (_) {
      return 0;
    }
  }

  Future<String> stopRecordingAndAsk() async {
    final path = await _recorder.stop();
    _recordingPath = null;
    if (path == null) throw VoiceAssistantError.emptyRecording;

    final file = File(path);
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) throw VoiceAssistantError.emptyRecording;
      try { await file.delete(); } catch (_) {}
      return await _askGemini(bytes);
    } on FileSystemException {
      throw VoiceAssistantError.emptyRecording;
    }
  }

  Future<void> cancelRecording() async {
    final path = await _recorder.stop();
    _recordingPath = null;
    if (path != null) {
      try { await File(path).delete(); } catch (_) {}
    }
  }

  Future<String> _askGemini(List<int> audioBytes) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) throw VoiceAssistantError.generic;

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=$apiKey',
      );

      final body = {
        "system_instruction": {
          "parts": [{"text": _systemPrompt}]
        },
        "contents": [
          {
            "parts": [
              {
                "text": "Listen carefully to the user's spoken voice query in this "
                    "audio clip. Understand what they are asking — it could be in "
                    "Hindi, English, or Hinglish. Provide a direct, helpful answer "
                    "to their specific question. Do NOT introduce yourself or give "
                    "a generic greeting."
              },
              {
                "inline_data": {
                  "mime_type": "audio/aac",
                  "data": base64Encode(audioBytes),
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.4,
          "thinkingConfig": {"thinkingBudget": 0},
        },
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        debugPrint('Gemini voice error ${response.statusCode}: ${response.body}');
        throw VoiceAssistantError.generic;
      }

      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw VoiceAssistantError.noAnswer;
      }

      final parts = candidates[0]['content']['parts'] as List;
      final text = parts
          .where((p) => p['text'] != null)
          .map((p) => p['text'] as String)
          .join()
          .trim();
      if (text.isEmpty) throw VoiceAssistantError.noAnswer;
      return text;
    } on VoiceAssistantError {
      rethrow;
    } on TimeoutException {
      throw VoiceAssistantError.network;
    } on SocketException {
      throw VoiceAssistantError.network;
    } on http.ClientException {
      throw VoiceAssistantError.network;
    } catch (_) {
      throw VoiceAssistantError.generic;
    }
  }

  /// Speaks [text] aloud using the correct TTS voice for the content.
  ///
  /// Language detection:
  /// - If [text] contains Devanagari characters → Hindi voice (`hi-IN`)
  /// - If [language] is Hindi (app toggle) → Hindi voice
  /// - Otherwise → English voice (`en-IN` or `en-US` fallback)
  ///
  /// Sets [hindiVoiceUnavailable] to `true` if Hindi was needed but
  /// the device has no Hindi TTS voice installed.
  Future<void> speak(String text, {required Language language}) async {
    try { await _tts.stop(); } catch (_) {}

    if (!_ttsReady) await _initTts();

    // Detect language and set the correct TTS voice
    final hindiMissing = await _setTtsLanguageForText(text, language);
    hindiVoiceUnavailable = hindiMissing;

    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }

  Future<void> pauseSpeaking() async {
    try { await _tts.pause(); } catch (_) {}
  }

  Future<void> stopSpeaking() async {
    try { await _tts.stop(); } catch (_) {}
  }

  Future<void> dispose() async {
    if (_recordingPath != null) {
      try { await _recorder.cancel(); } catch (_) {}
    }
    try { await _tts.stop(); } catch (_) {}
    try { await _recorder.dispose(); } catch (_) {}
  }
}
