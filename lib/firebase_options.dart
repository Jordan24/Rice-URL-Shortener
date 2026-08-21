import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Supports compilation overrides via `--dart-define` (e.g. `--dart-define=FIREBASE_PROJECT_ID=my-project`)
/// while providing standard production defaults.
class DefaultFirebaseOptions {
  static const String _apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyRiceUniversityPlaceholderKey1912',
  );

  static const String _authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'rice-url-shortener.firebaseapp.com',
  );

  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'rice-url-shortener',
  );

  static const String _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'rice-url-shortener.appspot.com',
  );

  static const String _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '123456789012',
  );

  static const String _appId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:123456789012:web:abcdef1234567890',
  );

  /// Helper to check if Firebase is configured with placeholder values
  static bool get isPlaceholderConfig =>
      _apiKey == 'AIzaSyRiceUniversityPlaceholderKey1912' ||
      _apiKey.isEmpty ||
      _apiKey.startsWith('AIzaSyRiceUniversityPlaceholder');

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    authDomain: _authDomain,
    storageBucket: _storageBucket,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: 'edu.rice.urlshortener',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: 'edu.rice.urlshortener',
  );
}
