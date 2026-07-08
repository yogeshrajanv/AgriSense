// lib/screens/voice_sheet_web.dart
// Web-specific JS callback registration for audio recording.
// Only compiled on web targets.

// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void registerAudioCallbacks({
  required void Function(String base64Audio) onEnded,
  required void Function(String error) onFailed,
}) {
  js.context['onAudioRecordingEnded'] = js.allowInterop((String base64Audio) {
    onEnded(base64Audio);
  });

  js.context['onAudioRecordingFailed'] = js.allowInterop((String error) {
    onFailed(error);
  });
}
