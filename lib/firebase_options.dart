import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  // ── Web ──────────────────────────────────────────────────────────────────
  //
  // authDomain MUST be phlakesfabric.web.app (not firebaseapp.com).
  //
  // WHY THE FULL CHAIN MUST MATCH:
  //
  //  1. User clicks "Continue with Google"
  //  2. Firebase builds the OAuth URL using authDomain:
  //       https://{authDomain}/__/auth/handler
  //  3. Google sends the browser to accounts.google.com
  //  4. After the user picks their account, Google redirects back to:
  //       https://{authDomain}/__/auth/handler
  //  5. Firebase reads the credential from sessionStorage and
  //     completes the sign-in
  //  6. The browser returns the user to your app
  //
  //  If authDomain is firebaseapp.com but your app runs on web.app,
  //  steps 4-5 happen on a DIFFERENT origin. The browser's same-origin
  //  policy blocks reading sessionStorage across origins → credential lost.
  //
  //  Setting authDomain to web.app + adding the web.app redirect URI
  //  in Google Cloud Console keeps steps 2-6 all on the same origin.
  //
  // REQUIRED GOOGLE CLOUD CONSOLE ACTION (do this ONCE):
  //   https://console.cloud.google.com/apis/credentials?project=phlakesfabric
  //   → Edit "Web client (auto created by Google Service)"
  //   → Authorized redirect URIs → Add:
  //       https://phlakesfabric.web.app/__/auth/handler
  //   → Authorized JavaScript origins → Add:
  //       https://phlakesfabric.web.app
  //   → Save → Wait 5 minutes
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyC-wnlmBUr8c1kny07uB5jGqdwGq5-GIDc',
    appId:             '1:1089917254734:web::2a98e9d43bf45e964a571f',
    messagingSenderId: '1089917254734',
    projectId:         'phlakesfabric',
    authDomain:        'phlakesfabric.web.app',
    storageBucket:     'phlakesfabric.firebasestorage.app',
  );

  // ── Android ───────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyC-wnlmBUr8c1kny07uB5jGqdwGq5-GIDc',
    appId:             '1:1089917254734:android:d791dca74fb3e77e4a571f',
    messagingSenderId: '1089917254734',
    projectId:         'phlakesfabric',
    storageBucket:     'phlakesfabric.firebasestorage.app',
  );
}