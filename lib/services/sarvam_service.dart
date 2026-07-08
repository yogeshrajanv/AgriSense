// lib/services/sarvam_service.dart
// Handles Sarvam AI speech integration for Speech-to-Text & Text-to-Speech.
// Falls back to browser Speech Synthesis API on web and mock responses for stability.
// Uses conditional imports so the app compiles on Android/iOS/Web.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Conditionally import js only on web
import 'sarvam_service_stub.dart'
    if (dart.library.html) 'sarvam_service_web.dart' as platform;

class SarvamService {
  static String get _apiKey {
    const vite = String.fromEnvironment('VITE_SARVAM_API_KEY', defaultValue: '');
    const standard = String.fromEnvironment('SARVAM_API_KEY', defaultValue: '');
    return vite.isNotEmpty ? vite : standard;
  }

  static bool get hasApiKey => _apiKey.isNotEmpty;

  /// Helper to map App language code to Sarvam region code.
  static String _getSarvamLangCode(String lang) {
    switch (lang) {
      case 'hi': return 'hi-IN';
      case 'ta': return 'ta-IN';
      case 'te': return 'te-IN';
      case 'mr': return 'mr-IN';
      default: return 'en-IN';
    }
  }

  /// Sends recorded audio binary bytes to Sarvam AI STT API.
  static Future<String> speechToText({
    required List<int> audioBytes,
    required String languageCode,
  }) async {
    if (!hasApiKey) return '';

    final String langCode = _getSarvamLangCode(languageCode);
    final url = Uri.parse('https://api.sarvam.ai/speech-to-text');
    final request = http.MultipartRequest('POST', url)
      ..headers['api-subscription-key'] = _apiKey
      ..fields['model'] = 'saaras:v3'
      ..fields['language-code'] = langCode
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        audioBytes,
        filename: 'audio.wav',
      ));

    try {
      final response = await request.send().timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        return (data['transcript'] as String?) ?? '';
      }
    } catch (e) {
      debugPrint('Sarvam STT error: $e');
    }
    return '';
  }

  /// Converts text to Base64 encoded audio string using Sarvam AI TTS API.
  static Future<String> textToSpeech({
    required String text,
    required String languageCode,
  }) async {
    if (!hasApiKey) return '';

    final String langCode = _getSarvamLangCode(languageCode);
    final url = Uri.parse('https://api.sarvam.ai/text-to-speech');

    // Use speaker voices appropriate for selected language
    String speaker = 'aditya';
    if (langCode == 'hi-IN') speaker = 'ritu';
    else if (langCode == 'ta-IN') speaker = 'shreya';

    final body = {
      'text': text,
      'speaker': speaker,
      'model': 'bulbul:v3',
      'target_language_code': langCode,
      'pace': 1.0,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'api-subscription-key': _apiKey,
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['audio'] as String?) ?? '';
      }
    } catch (e) {
      debugPrint('Sarvam TTS error: $e');
    }
    return '';
  }

  /// Play audio via Sarvam response (Base64) or Browser speech synthesis fallback.
  static void speak(String text, String languageCode, {String? base64Audio}) {
    if (!kIsWeb) return;

    try {
      if (base64Audio != null && base64Audio.isNotEmpty) {
        platform.playBase64Audio(base64Audio);
      } else {
        platform.speakText(text, languageCode);
      }
    } catch (e) {
      debugPrint('Speech playback failed: $e');
    }
  }

  /// Stop any currently playing audio or speech synthesis.
  static void stopSpeaking() {
    if (!kIsWeb) return;

    try {
      platform.stopAllAudio();
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  /// Start browser microphone recording.
  static void startRecording() {
    if (!kIsWeb) return;
    try {
      platform.startRecording();
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  /// Stop browser microphone recording.
  static void stopRecording() {
    if (!kIsWeb) return;
    try {
      platform.stopRecording();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }
}
