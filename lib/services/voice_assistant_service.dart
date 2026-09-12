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
  static String buildSystemPrompt(Language language) {
    return "You are a helpful assistant for Indian rural artisans. "
        "You must strictly reply in ${language.displayName} native script.\n\n"
        "You are Handora AI, a helpful voice assistant for Indian artisans who sell "
        "handicrafts on ONDC. Listen carefully to the audio clip below. The user is "
        "speaking a question or request. "
        "Understand exactly what they are asking, then provide a direct, specific, "
        "and helpful answer to THAT question in ${language.displayName} native script. "
        "Do NOT give a generic greeting or introduction — jump straight into answering the user's actual query. "
        "You must strictly reply in ${language.displayName} native script.";
  }


  final AudioRecorder _recorder = AudioRecorder();
  final FlutterTts _tts = FlutterTts();

  final ValueNotifier<bool> isSpeaking = ValueNotifier(false);
  final ValueNotifier<bool> ttsPaused = ValueNotifier(false);

  /// Set to true after the last `speak()` call if the requested regional
  /// voice was not available on the device.
  bool hindiVoiceUnavailable = false;
  bool get regionalVoiceUnavailable => hindiVoiceUnavailable;

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

  static const _model = 'gemini-3.6-flash';

  Future<String> stopRecordingAndAsk({Language language = Language.en}) async {
    final path = await _recorder.stop();
    _recordingPath = null;
    if (path == null || path.isEmpty) {
      debugPrint('Voice Assistant: Recording path is null or empty');
      throw VoiceAssistantError.emptyRecording;
    }

    final file = File(path);
    if (!await file.exists()) {
      debugPrint('Voice Assistant: Recording file does not exist at $path');
      throw VoiceAssistantError.emptyRecording;
    }

    final fileSize = await file.length();
    debugPrint('🎙️ Voice Assistant: Recorded audio size = $fileSize bytes');
    if (fileSize == 0) {
      debugPrint('Voice Assistant: Recording file is empty (0 bytes)');
      try { await file.delete(); } catch (_) {}
      throw VoiceAssistantError.emptyRecording;
    }

    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        debugPrint('Voice Assistant: Audio bytes are empty');
        try { await file.delete(); } catch (_) {}
        throw VoiceAssistantError.emptyRecording;
      }
      try { await file.delete(); } catch (_) {}
      return await _askGemini(bytes, language: language);
    } on FileSystemException catch (e) {
      debugPrint('Voice Assistant FileSystemException: $e');
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

  Future<String> _askGemini(List<int> audioBytes, {Language language = Language.en}) async {
    if (audioBytes.isEmpty) {
      debugPrint('Voice Assistant: audioBytes is empty in _askGemini');
      throw VoiceAssistantError.emptyRecording;
    }

    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('Voice Assistant Error: GEMINI_API_KEY is not configured in .env');
      throw VoiceAssistantError.generic;
    }

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey',
      );

      final body = {
        "contents": [
          {
            "parts": [
              {"text": buildSystemPrompt(language)},
              {
                "inlineData": {
                  "mimeType": "audio/mp4",
                  "data": base64Encode(audioBytes),
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
    } on TimeoutException catch (e) {
      debugPrint('Voice Assistant Timeout: $e');
      throw VoiceAssistantError.network;
    } on SocketException catch (e) {
      debugPrint('Voice Assistant SocketException: $e');
      throw VoiceAssistantError.network;
    } on http.ClientException catch (e) {
      debugPrint('Voice Assistant ClientException: $e');
      throw VoiceAssistantError.network;
    } catch (e) {
      debugPrint('Voice Assistant Unexpected Error: $e');
      throw VoiceAssistantError.generic;
    }
  }

  /// Speaks [text] aloud using the selected [Language.localeCode] regional voice.
  /// Explicitly calls `setLanguage(language.localeCode)` with safe fallback try-catch.
  Future<void> speak(String text, {required Language language}) async {
    try { await _tts.stop(); } catch (_) {}

    if (!_ttsReady) await _initTts();

    // Explicitly set language using currentLanguage.localeCode with safe fallback
    try {
      final res = await _tts.setLanguage(language.localeCode);
      if (res != 1 && res != true && res != null) {
        throw Exception('Locale ${language.localeCode} not available on device');
      }
      hindiVoiceUnavailable = false;
    } catch (e) {
      debugPrint('⚠️ TTS setLanguage(${language.localeCode}) failed, falling back to en-IN: $e');
      hindiVoiceUnavailable = language != Language.en;
      try {
        await _tts.setLanguage('en-IN');
      } catch (_) {}
    }

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
