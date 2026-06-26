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
  //
  // CRITICAL: authDomain must be the domain your app is actually served
  // from — NOT the default firebaseapp.com domain.
  //
  // WHY THIS MATTERS:
  //   After signInWithRedirect(), Google OAuth returns the browser to
  //   __/auth/handler on your authDomain. Firebase then reads the
  //   pending credential from sessionStorage and finalises the sign-in.
  //   sessionStorage is ORIGIN-SCOPED by the browser. If authDomain is
  //   phlakesfabric.firebaseapp.com but your app is served from
  //   phlakesfabric.web.app, the credential is written to one origin
  //   and read from another — the browser blocks it and the credential
  //   is silently lost, making it look like sign-in failed.
  //
  //   Setting authDomain to phlakesfabric.web.app ensures the entire
  //   OAuth round-trip happens on the same origin your Flutter app runs
  //   on, so sessionStorage is preserved end-to-end.
  //
  // REQUIRED FIREBASE CONSOLE ACTION:
  //   Authentication → Settings → Authorized domains
  //   Make sure BOTH entries exist:
  //     • phlakesfabric.firebaseapp.com  (default, keep it)
  //     • phlakesfabric.web.app          (add this if missing)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyC-wnlmBUr8c1kny07uB5jGqdwGq5-GIDc',
    appId:             '1:1089917254734:web::2a98e9d43bf45e964a571f',
    messagingSenderId: '1089917254734',
    projectId:         'phlakesfabric',
    authDomain:        'phlakesfabric.web.app', // ← CHANGED
    storageBucket:     'phlakesfabric.firebasestorage.app',
  );

  // ── Android ────────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyC-wnlmBUr8c1kny07uB5jGqdwGq5-GIDc',
    appId:             '1:1089917254734:android:d791dca74fb3e77e4a571f',
    messagingSenderId: '1089917254734',
    projectId:         'phlakesfabric',
    storageBucket:     'phlakesfabric.firebasestorage.app',
  );
}