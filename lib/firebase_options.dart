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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDEYw7A7kyleURxqLFGarqifXG9Bzbsyk4',
    appId: '1:331362046998:web:bce8f42c493e65c9025137',
    messagingSenderId: '331362046998',
    projectId: 'ismailtex-f070d',
    authDomain: 'ismailtex-f070d.firebaseapp.com',
    storageBucket: 'ismailtex-f070d.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDEYw7A7kyleURxqLFGarqifXG9Bzbsyk4',
    appId: '1:331362046998:android:65b49a4beb457e17025137',
    messagingSenderId: '331362046998',
    projectId: 'ismailtex-f070d',
    storageBucket: 'ismailtex-f070d.firebasestorage.app',
  );
}
