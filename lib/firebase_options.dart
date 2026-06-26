import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Project: Phlakes Fabric (phlakesfabric)
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;

      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  // ── Web ────────────────────────────────────────────────────────────────────
  // From: phlakesfabric.web.app / phlakesfabric.firebaseapp.com
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyC-wnlmBUr8c1kny07uB5jGqdwGq5-GIDc',
    appId:             '1:1089917254734:web:2a98e9d43bf45e964a571f',
    messagingSenderId: '1089917254734',
    projectId:         'phlakesfabric',
    authDomain:        'phlakesfabric.firebaseapp.com',
    storageBucket:     'phlakesfabric.firebasestorage.app',
  );

  // ── Android ────────────────────────────────────────────────────────────────
  // Package: com.pfb.app
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyC-wnlmBUr8c1kny07uB5jGqdwGq5-GIDc',
    appId:             '1:1089917254734:android:d791dca74fb3e77e4a571f',
    messagingSenderId: '1089917254734',
    projectId:         'phlakesfabric',
    storageBucket:     'phlakesfabric.firebasestorage.app',
  );
}