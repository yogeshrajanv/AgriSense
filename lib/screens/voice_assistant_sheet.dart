// lib/screens/voice_assistant_sheet.dart
// Global AI farming voice assistant bottom sheet.
// Uses Gemini for reasoning + Sarvam AI STT & TTS integration with browser fallbacks.
// Supports English, Hindi, Tamil, Telugu, Marathi.
// All platform-specific calls go through SarvamService (which uses conditional imports).

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/farmer_context.dart';
import '../services/gemini_service.dart';
import '../services/sarvam_service.dart';

// Web-only JS interop for recording callbacks
import 'voice_sheet_stub.dart'
    if (dart.library.html) 'voice_sheet_web.dart' as voice_web;

enum VoiceState { idle, listening, processing, responded }

class VoiceAssistantSheet extends StatefulWidget {
  final FarmSnapshot farmSnapshot;
  final bool isHindi;
  final Function(String action, {Map<String, dynamic>? params}) onAction;

  const VoiceAssistantSheet({
    super.key,
    required this.farmSnapshot,
    required this.isHindi,
    required this.onAction,
  });

  @override
  State<VoiceAssistantSheet> createState() => _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends State<VoiceAssistantSheet>
    with TickerProviderStateMixin {
  VoiceState _state = VoiceState.idle;
  String _recognizedText = '';
  String _aiAnswer = '';
  Map<String, dynamic> _aiResponse = {};
  String _selectedLanguage = 'en';
  bool _pendingConfirmation = false;

  // Text input fallback
  final TextEditingController _typedInputCtrl = TextEditingController();
  bool _showTypingInput = false;

  // Wave animation
  late AnimationController _waveCtrl;
  late List<Animation<double>> _barAnimations;

  // Audio caching to avoid redundant TTS calls
  String _cachedSpeechBase64 = '';
  String _cachedSpeechText = '';

  // Sample commands based on language
  final Map<String, List<String>> _commandSuggestions = {
    'en': [
      'Should I water today?',
      'Show weather forecast',
      'Check leaf disease',
      'Log harvest',
      'Book an expert',
    ],
    'hi': ['क्या आज सिंचाई करूं?', 'मौसम दिखाओ', 'पत्ते की जांच करो', 'विशेषज्ञ बुलाओ'],
    'ta': ['இன்று நீர் பாய்ச்சலாமா?', 'வானிலை காட்டு', 'இலை நோயை சரிபார்'],
    'te': ['నేడు నీరు పెట్టాలా?', 'వాతావరణం చూపించు', 'ఆకు రోగం తనిఖీ'],
    'mr': ['आज पाणी द्यावे का?', 'हवामान दाखवा', 'पाने तपासा'],
  };

  List<String> get _suggestions =>
      _commandSuggestions[_selectedLanguage] ?? _commandSuggestions['en']!;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.isHindi ? 'hi' : 'en';
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _barAnimations = List.generate(
      5,
      (i) => Tween<double>(begin: 6 + i * 4.0, end: 30 + i * 8.0).animate(
        CurvedAnimation(
          parent: _waveCtrl,
          curve: Interval(i * 0.1, 0.5 + i * 0.1, curve: Curves.easeInOut),
        ),
      ),
    );

    // Register web audio callbacks and auto-start listening
    if (kIsWeb) {
      voice_web.registerAudioCallbacks(
        onEnded: (base64Audio) => _onRecordingEnded(base64Audio),
        onFailed: (err) => _onRecordingFailed(err),
      );
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _startListening();
    });
  }

  @override
  void dispose() {
    SarvamService.stopSpeaking();
    SarvamService.stopRecording();
    _waveCtrl.dispose();
    _typedInputCtrl.dispose();
    super.dispose();
  }

  void _startListening() {
    setState(() {
      _state = VoiceState.listening;
      _recognizedText = '';
      _aiAnswer = '';
      _aiResponse = {};
      _pendingConfirmation = false;
    });
    SarvamService.startRecording();
  }

  void _stopListening() {
    SarvamService.stopRecording();
    // The recording result is delivered via callback _onRecordingEnded
    // If no callback fires within 2 seconds, stay in listening mode
  }

  void _onRecordingEnded(String base64Audio) async {
    if (!mounted) return;
    setState(() => _state = VoiceState.processing);

    final bytes = base64Decode(base64Audio);
    final transcript = await SarvamService.speechToText(
      audioBytes: bytes,
      languageCode: _selectedLanguage,
    );

    if (!mounted) return;
    if (transcript.isNotEmpty) {
      await _processQuery(transcript);
    } else {
      // No transcript — fall back to typing mode
      setState(() {
        _state = VoiceState.listening;
        _showTypingInput = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not transcribe audio. Try typing your question.'),
        ));
      }
    }
  }

  void _onRecordingFailed(String err) {
    debugPrint('Mic recording failed: $err');
    if (!mounted) return;
    setState(() {
      _state = VoiceState.idle;
      _showTypingInput = true;
    });
  }

  Future<void> _processQuery(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _state = VoiceState.processing;
      _recognizedText = query;
      _aiAnswer = '';
      _pendingConfirmation = false;
      _aiResponse = {};
    });

    final response = await GeminiService.askVoiceAssistant(
      userMessage: query,
      farm: widget.farmSnapshot,
      language: _selectedLanguage,
    );

    if (!mounted) return;

    final answer = response['answer'] as String? ??
        "I'm not sure about that. Please try again.";

    setState(() {
      _state = VoiceState.responded;
      _aiAnswer = answer;
      _aiResponse = response;
      _pendingConfirmation = response['confirmationRequired'] as bool? ?? false;
    });

    // Speak the response
    _speakResponse(answer);
  }

  Future<void> _speakResponse(String text) async {
    SarvamService.stopSpeaking();

    if (_cachedSpeechText == text && _cachedSpeechBase64.isNotEmpty) {
      SarvamService.speak(text, _selectedLanguage,
          base64Audio: _cachedSpeechBase64);
      return;
    }

    // Try Sarvam TTS; falls back to browser SpeechSynthesis if no key
    final base64Audio = await SarvamService.textToSpeech(
      text: text,
      languageCode: _selectedLanguage,
    );

    if (!mounted) return;
    _cachedSpeechBase64 = base64Audio;
    _cachedSpeechText = text;
    SarvamService.speak(text, _selectedLanguage, base64Audio: base64Audio);
  }

  void _executeAction() {
    final action = _aiResponse['action'] as String? ?? 'none';
    if (action != 'none') {
      widget.onAction(action, params: _aiResponse);
    }
    Navigator.pop(context);
  }

  void _tapCommand(String cmd) {
    if (_state == VoiceState.listening || _state == VoiceState.idle) {
      SarvamService.stopRecording();
      _processQuery(cmd);
    }
  }

  void _reset() {
    SarvamService.stopSpeaking();
    SarvamService.stopRecording();
    _startListening();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E5E4A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AgriSense Voice Assistant',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1E352C),
                        ),
                      ),
                      Text(
                        'Powered by Gemini + Sarvam AI',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildLanguagePicker(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Content based on state
            if (_state == VoiceState.idle || _state == VoiceState.listening)
              _buildListeningWidget()
            else if (_state == VoiceState.processing)
              _buildProcessingWidget()
            else
              _buildResponseWidget(),

            // Demo mode notice
            if (!GeminiService.hasApiKey)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.orange),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Running in demo mode. Set GEMINI_API_KEY for live AI responses.',
                          style: TextStyle(fontSize: 11, color: Colors.deepOrange),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagePicker() {
    const langs = {
      'en': '🇬🇧 EN',
      'hi': '🇮🇳 HI',
      'ta': 'தமிழ்',
      'te': 'తెలుగు',
      'mr': 'मराठी',
    };
    return PopupMenuButton<String>(
      initialValue: _selectedLanguage,
      tooltip: 'Change language',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (val) {
        setState(() => _selectedLanguage = val);
        _reset();
      },
      itemBuilder: (_) => langs.entries
          .map((e) => PopupMenuItem(
                value: e.key,
                child: Text(e.value, style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFD8F3E5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate, size: 14, color: Color(0xFF1E5E4A)),
            const SizedBox(width: 4),
            Text(
              langs[_selectedLanguage] ?? 'EN',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E5E4A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningWidget() {
    final isListening = _state == VoiceState.listening;
    return Column(
      children: [
        // Waveform animation
        AnimatedBuilder(
          animation: _waveCtrl,
          builder: (ctx, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(
              5,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 5,
                height: isListening ? _barAnimations[i].value : 8,
                decoration: BoxDecoration(
                  color: isListening
                      ? const Color(0xFF1E5E4A)
                      : const Color(0xFFD8F3E5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          isListening
              ? 'Listening… tap to stop recording'
              : 'Tap mic to speak',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isListening
                ? const Color(0xFF1E5E4A)
                : Colors.grey,
          ),
        ),
        const SizedBox(height: 16),

        // Mic / Stop button
        GestureDetector(
          onTap: isListening ? _stopListening : _startListening,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isListening
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
              border: Border.all(
                color: isListening
                    ? const Color(0xFF1E5E4A)
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Icon(
              isListening ? Icons.stop_rounded : Icons.mic,
              color: const Color(0xFF1E5E4A),
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Text input toggle
        if (!_showTypingInput)
          TextButton.icon(
            onPressed: () => setState(() => _showTypingInput = true),
            icon: const Icon(Icons.keyboard_alt_outlined,
                size: 16, color: Color(0xFF1E5E4A)),
            label: const Text(
              'Type instead',
              style: TextStyle(color: Color(0xFF1E5E4A), fontSize: 12),
            ),
          )
        else
          _buildTypingInput(),

        const SizedBox(height: 16),

        // Suggestion chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions
              .map((s) => ActionChip(
                    label: Text(
                      s,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF1E5E4A)),
                    ),
                    backgroundColor: const Color(0xFFF0F6F3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    onPressed: () => _tapCommand(s),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTypingInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _typedInputCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Type your farming question…',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              filled: true,
              fillColor: const Color(0xFFFBFBFB),
            ),
            onSubmitted: (val) {
              _processQuery(val);
              _typedInputCtrl.clear();
            },
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            _processQuery(_typedInputCtrl.text);
            _typedInputCtrl.clear();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E5E4A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            elevation: 0,
          ),
          child: const Icon(Icons.send, size: 18),
        ),
      ],
    );
  }

  Widget _buildProcessingWidget() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F6F3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 16, color: Color(0xFF1E5E4A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"$_recognizedText"',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E352C),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF1E5E4A),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Understanding your farm…',
              style: TextStyle(
                  color: Color(0xFF1E5E4A), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildResponseWidget() {
    final action = _aiResponse['action'] as String? ?? 'none';
    final actionLabel = _aiResponse['actionLabel'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Farmer's question bubble
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '"$_recognizedText"',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // AI answer card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E5E4A), Color(0xFF2D8A6B)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.eco, color: Colors.white70, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'AgriSense AI',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _aiAnswer,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _speakResponse(_aiAnswer),
                    icon: const Icon(Icons.volume_up,
                        color: Colors.white, size: 16),
                    label: const Text('Replay',
                        style:
                            TextStyle(color: Colors.white, fontSize: 12)),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30)),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => SarvamService.stopSpeaking(),
                    icon: const Icon(Icons.volume_off,
                        color: Colors.white70, size: 16),
                    label: const Text('Stop',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Confirmation card (when action needs explicit confirm)
        if (_pendingConfirmation &&
            (_aiResponse['confirmationMessage'] as String? ?? '').isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _aiResponse['confirmationMessage']?.toString() ?? '',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _executeAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E5E4A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Confirm',
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _reset,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Action button row
        Row(
          children: [
            if (action != 'none' &&
                actionLabel.isNotEmpty &&
                !_pendingConfirmation)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _executeAction,
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  label: Text(
                    actionLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5E4A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                ),
              ),
            if (action != 'none' &&
                actionLabel.isNotEmpty &&
                !_pendingConfirmation)
              const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh,
                    size: 16, color: Color(0xFF1E5E4A)),
                label: const Text(
                  'Ask Again',
                  style: TextStyle(color: Color(0xFF1E5E4A), fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1E5E4A)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
