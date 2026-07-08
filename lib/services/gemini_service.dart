// lib/services/gemini_service.dart
// Handles all Gemini API calls: crop image diagnosis + voice assistant responses.
// Falls back gracefully to mock responses when API key is absent or request fails.

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/farmer_context.dart';

class GeminiService {
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Read API key from environment (set at compile time via --dart-define or similar).
  /// Never hardcoded. Returns empty string if not set.
  static String get _apiKey => const String.fromEnvironment('VITE_GEMINI_API_KEY', defaultValue: '') != ''
      ? const String.fromEnvironment('VITE_GEMINI_API_KEY')
      : const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static bool get hasApiKey => _apiKey.isNotEmpty;

  // ─────────────────────────────────────────────────────────────────────────
  // CROP IMAGE DIAGNOSIS
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> diagnoseCropImage({
    required String base64Image,
    required FarmSnapshot farm,
    String mimeType = 'image/jpeg',
  }) async {
    if (!hasApiKey) {
      await Future.delayed(const Duration(milliseconds: 1800));
      return _mockDiagnosis(farm);
    }

    final prompt = '''
You are an expert agronomist AI. Analyze this crop leaf image and provide a structured JSON diagnosis.

${farm.toAIContext()}

Return ONLY valid JSON with this exact structure (no markdown, no extra text):
{
  "crop": "detected crop name",
  "disease": "disease or issue name, or 'Healthy' if none",
  "confidence": 87,
  "severity": "Low | Medium | High | None",
  "symptoms": "brief description of visible symptoms",
  "causes": "likely causes of the issue",
  "immediateAction": "what to do right now",
  "treatment": "recommended treatment",
  "irrigationAdvice": "irrigation recommendation based on farm context",
  "fertilizerAdvice": "fertilizer recommendation based on NPK levels",
  "preventionTips": "future prevention tips",
  "expertRecommended": true,
  "isDemo": false
}
''';

    try {
      final body = {
        'contents': [
          {
            'parts': [
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image,
                }
              },
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 1024,
        }
      };

      final response = await http
          .post(
            Uri.parse('$_endpoint?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        // Strip possible markdown code fences
        final cleaned = text.replaceAll(RegExp(r'```json|```', multiLine: true), '').trim();
        final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
        parsed['isDemo'] = false;
        return parsed;
      } else {
        return _mockDiagnosis(farm);
      }
    } catch (e) {
      return _mockDiagnosis(farm);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VOICE ASSISTANT — TEXT CHAT
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> askVoiceAssistant({
    required String userMessage,
    required FarmSnapshot farm,
    String language = 'en',
  }) async {
    if (!hasApiKey) {
      await Future.delayed(const Duration(milliseconds: 900));
      return _mockVoiceResponse(userMessage, farm);
    }

    final langInstruction = _langInstruction(language);

    final prompt = '''
You are AgriSense — an AI farming assistant for Indian farmers. $langInstruction

${farm.toAIContext()}

Farmer's message: "$userMessage"

Respond with ONLY valid JSON (no markdown):
{
  "answer": "Your helpful farming answer here (2-3 sentences max)",
  "action": "navigate_weather | navigate_crops | navigate_expert | navigate_home | navigate_advice | start_diagnosis | log_harvest | book_expert | irrigate_confirm | fertilizer_confirm | configure_parameters | change_language_hi | change_language_en | change_language_ta | change_language_te | change_language_mr | none",
  "actionLabel": "Human readable label for action button, or empty string",
  "confirmationRequired": false,
  "confirmationMessage": ""
}

Action rules:
- If user mentions weather/rain → navigate_weather
- If user mentions crops/harvest → navigate_crops  
- If user mentions leaf/disease/scan → start_diagnosis
- If user mentions expert/visit/book → book_expert
- If user asks about irrigation/water → irrigate_confirm (if soil moisture < 40) or none
- If user asks about fertilizer → fertilizer_confirm if NPK deficient, else none
- If user asks to log harvest → log_harvest
- If user wants to change language to Hindi → change_language_hi
- If user wants to change language to English → change_language_en
- If user wants to change language to Tamil → change_language_ta
- If user wants to change language to Telugu → change_language_te
- If user wants to change language to Marathi → change_language_mr
- If user wants to configure parameters or modify settings → configure_parameters
- Otherwise → none
''';

    try {
      final body = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'maxOutputTokens': 512,
        }
      };

      final response = await http
          .post(
            Uri.parse('$_endpoint?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        final cleaned = text.replaceAll(RegExp(r'```json|```', multiLine: true), '').trim();
        return jsonDecode(cleaned) as Map<String, dynamic>;
      } else {
        return _mockVoiceResponse(userMessage, farm);
      }
    } catch (e) {
      return _mockVoiceResponse(userMessage, farm);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOCK FALLBACKS
  // ─────────────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _mockDiagnosis(FarmSnapshot farm) {
    final rng = Random();
    final diseases = [
      {
        'disease': 'Early Blight',
        'symptoms': 'Concentric ring lesions on older leaves with yellow halos.',
        'treatment': 'Apply copper-based fungicide at 2g/L. Remove infected leaves.',
      },
      {
        'disease': 'Powdery Mildew',
        'symptoms': 'White powdery coating on upper leaf surfaces.',
        'treatment': 'Spray potassium bicarbonate solution or neem oil.',
      },
      {
        'disease': 'Leaf Spot (Cercospora)',
        'symptoms': 'Small brown circular spots with grey centers.',
        'treatment': 'Apply Mancozeb 75 WP at 2.5g/L. Ensure good air circulation.',
      },
    ];
    final d = diseases[rng.nextInt(diseases.length)];
    return {
      'crop': farm.primaryCropName,
      'disease': d['disease'],
      'confidence': 72 + rng.nextInt(20),
      'severity': 'Medium',
      'symptoms': d['symptoms'],
      'causes': 'Fungal pathogen favored by high humidity and leaf wetness.',
      'immediateAction': 'Isolate affected plants. Reduce overhead irrigation.',
      'treatment': d['treatment'],
      'irrigationAdvice': farm.irrigationAdvice,
      'fertilizerAdvice': farm.fertilizerAdvice,
      'preventionTips': 'Use resistant varieties, practice crop rotation, maintain plant spacing.',
      'expertRecommended': true,
      'isDemo': true,
    };
  }

  static Map<String, dynamic> _mockVoiceResponse(String msg, FarmSnapshot farm) {
    final lower = msg.toLowerCase();

    if (lower.contains('language') || lower.contains('lang') || lower.contains('भाषा') || lower.contains('बोलो')) {
      if (lower.contains('hindi') || lower.contains('हिंदी') || lower.contains('hi')) {
        return {
          'answer': 'Sure, switching language to Hindi.',
          'action': 'change_language_hi',
          'actionLabel': 'Switch to Hindi',
          'confirmationRequired': true,
          'confirmationMessage': 'Change language to Hindi?',
        };
      }
      if (lower.contains('english') || lower.contains('अंग्रेजी') || lower.contains('en')) {
        return {
          'answer': 'Sure, switching language to English.',
          'action': 'change_language_en',
          'actionLabel': 'Switch to English',
          'confirmationRequired': true,
          'confirmationMessage': 'Change language to English?',
        };
      }
      if (lower.contains('tamil') || lower.contains('तमिल') || lower.contains('ta') || lower.contains('தமிழ்')) {
        return {
          'answer': 'Sure, switching language to Tamil.',
          'action': 'change_language_ta',
          'actionLabel': 'Switch to Tamil',
          'confirmationRequired': true,
          'confirmationMessage': 'Change language to Tamil?',
        };
      }
      if (lower.contains('telugu') || lower.contains('तेलुगु') || lower.contains('te') || lower.contains('తెలుగు')) {
        return {
          'answer': 'Sure, switching language to Telugu.',
          'action': 'change_language_te',
          'actionLabel': 'Switch to Telugu',
          'confirmationRequired': true,
          'confirmationMessage': 'Change language to Telugu?',
        };
      }
      if (lower.contains('marathi') || lower.contains('मराठी') || lower.contains('mr')) {
        return {
          'answer': 'Sure, switching language to Marathi.',
          'action': 'change_language_mr',
          'actionLabel': 'Switch to Marathi',
          'confirmationRequired': true,
          'confirmationMessage': 'Change language to Marathi?',
        };
      }
    }
    if (lower.contains('parameter') || lower.contains('configure') || lower.contains('set') || lower.contains('adjust') || lower.contains('बदले') || lower.contains('सेटिंग')) {
      return {
        'answer': 'Opening the simulation panel to configure farm parameters.',
        'action': 'configure_parameters',
        'actionLabel': 'Configure Parameters',
        'confirmationRequired': false,
        'confirmationMessage': '',
      };
    }
    if (lower.contains('water') || lower.contains('irrigat')) {
      return {
        'answer': farm.irrigationAdvice,
        'action': farm.soilMoisture < 45 ? 'irrigate_confirm' : 'none',
        'actionLabel': farm.soilMoisture < 45 ? 'Schedule Irrigation' : '',
        'confirmationRequired': farm.soilMoisture < 45,
        'confirmationMessage': 'Log irrigation event for today?',
      };
    }
    if (lower.contains('fertiliz') || lower.contains('npk') || lower.contains('nutrient')) {
      return {
        'answer': farm.fertilizerAdvice,
        'action': 'fertilizer_confirm',
        'actionLabel': 'Apply Fertilizer',
        'confirmationRequired': false,
        'confirmationMessage': '',
      };
    }
    if (lower.contains('weather') || lower.contains('rain')) {
      return {
        'answer': 'Current conditions at ${farm.location}: ${farm.temperature.round()}°C, ${farm.humidity.round()}% humidity, ${farm.rainfallChance.round()}% chance of rain today.',
        'action': 'navigate_weather',
        'actionLabel': 'View Weather',
        'confirmationRequired': false,
        'confirmationMessage': '',
      };
    }
    if (lower.contains('leaf') || lower.contains('disease') || lower.contains('scan')) {
      return {
        'answer': 'I\'ll open the crop scanner so you can capture a leaf image for AI diagnosis.',
        'action': 'start_diagnosis',
        'actionLabel': 'Open Scanner',
        'confirmationRequired': false,
        'confirmationMessage': '',
      };
    }
    if (lower.contains('harvest') || lower.contains('log')) {
      return {
        'answer': 'I\'ll open the harvest logging form for you.',
        'action': 'log_harvest',
        'actionLabel': 'Log Harvest',
        'confirmationRequired': false,
        'confirmationMessage': '',
      };
    }
    if (lower.contains('expert') || lower.contains('book') || lower.contains('visit')) {
      return {
        'answer': 'Connecting you to Rythu Seva Kendra expert booking service.',
        'action': 'book_expert',
        'actionLabel': 'Book Visit',
        'confirmationRequired': false,
        'confirmationMessage': '',
      };
    }
    if (lower.contains('crop')) {
      return {
        'answer': 'Your active crop is ${farm.primaryCropName} at ${farm.primaryCropGrowthStage} stage.',
        'action': 'navigate_crops',
        'actionLabel': 'View Crops',
        'confirmationRequired': false,
        'confirmationMessage': '',
      };
    }

    return {
      'answer': 'Your farm is currently at ${farm.temperature.round()}°C with ${farm.soilMoisture.round()}% soil moisture. ${farm.urgentAlertMessage.isNotEmpty ? farm.urgentAlertMessage : 'All parameters look normal.'}',
      'action': 'none',
      'actionLabel': '',
      'confirmationRequired': false,
      'confirmationMessage': '',
    };
  }

  static String _langInstruction(String lang) {
    switch (lang) {
      case 'hi': return 'Please respond in simple Hindi language.';
      case 'ta': return 'Please respond in Tamil language.';
      case 'te': return 'Please respond in Telugu language.';
      case 'mr': return 'Please respond in Marathi language.';
      default:   return 'Please respond in clear, simple English suitable for farmers.';
    }
  }
}
