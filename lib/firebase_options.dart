// Firebase configuration loaded from compile-time environment variables.
// Do not commit real keys. Pass values via --dart-define or your CI secrets.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const String _apiKey =
      String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
  static const String _appId =
      String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');
  static const String _androidAppId =
      String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: '');
  static const String _iosAppId =
      String.fromEnvironment('FIREBASE_IOS_APP_ID', defaultValue: '');
  static const String _messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');
  static const String _projectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static const String _authDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: '');
  static const String _storageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '');
  static const String _iosBundleId =
      String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: 'com.agrisense.agrisense');

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _authDomain,
        storageBucket: _storageBucket,
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _apiKey,
        appId: _androidAppId.isNotEmpty ? _androidAppId : _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _apiKey,
        appId: _iosAppId.isNotEmpty ? _iosAppId : _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
        iosBundleId: _iosBundleId,
      );

  static FirebaseOptions get macos => ios;

  static FirebaseOptions get windows => FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _authDomain,
        storageBucket: _storageBucket,
      );
}
