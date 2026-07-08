// lib/services/sarvam_service_stub.dart
// Stub implementations for non-web platforms (Android, iOS, desktop).
// These are no-ops since native voice is not yet wired up.

void playBase64Audio(String base64Str) {}
void speakText(String text, String languageCode) {}
void stopAllAudio() {}
void startRecording() {}
void stopRecording() {}
