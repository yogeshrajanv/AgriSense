// lib/services/sarvam_service_web.dart
// Web-specific implementations using dart:js interop.
// Only compiled on web targets.

// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void playBase64Audio(String base64Str) {
  try {
    js.context.callMethod('playBase64Audio', [base64Str]);
  } catch (_) {}
}

void speakText(String text, String languageCode) {
  try {
    js.context.callMethod('speakText', [text, languageCode]);
  } catch (_) {}
}

void stopAllAudio() {
  try {
    js.context.callMethod('stopBase64Audio');
    js.context.callMethod('stopSpeakingText');
  } catch (_) {}
}

void startRecording() {
  try {
    js.context.callMethod('startRecordingAudio');
  } catch (_) {}
}

void stopRecording() {
  try {
    js.context.callMethod('stopRecordingAudio');
  } catch (_) {}
}
