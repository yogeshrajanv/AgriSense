// lib/screens/voice_sheet_stub.dart
// Non-web stub: audio recording callbacks are no-ops.

void registerAudioCallbacks({
  required void Function(String base64Audio) onEnded,
  required void Function(String error) onFailed,
}) {
  // No-op on non-web platforms
}
