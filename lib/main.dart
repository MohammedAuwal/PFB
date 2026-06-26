import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pfb/app.dart';
import 'package:pfb/services/fcm_service.dart';
import 'package:pfb/services/local_notification_service.dart';
import 'package:pfb/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    final errorStr = e.toString().toLowerCase();
    if (!errorStr.contains('duplicate-app') &&
        !errorStr.contains('already exists')) {
      rethrow;
    }
  }

  try {
    await FcmService.instance.handleBackgroundMessage(message);
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0B0B0B),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0B0B0B),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  Object? startupError;
  StackTrace? startupStack;

  // ── Step 1: Initialize Firebase ──────────────────────────────────────────
  try {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 12));
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (!errorStr.contains('duplicate-app') &&
          !errorStr.contains('already exists')) {
        rethrow;
      }
    }
  } catch (e, st) {
    startupError = Exception('Firebase init failed: $e');
    startupStack = st;
  }

  // ── Step 2 (Web only): Set persistence then check auth state ─────────────
  //
  // We now use signInWithPopup (not redirect) so there is no cross-origin
  // sessionStorage problem. However we still call getRedirectResult() once
  // as a safety net in case an old redirect from a previous app version is
  // still pending in the browser.
  //
  // More importantly: on web, FirebaseAuth restores the signed-in user from
  // IndexedDB asynchronously. We must wait for authStateChanges to emit
  // at least one event before SplashScreen reads currentUser, otherwise
  // currentUser is null on first render even for a user who was already
  // logged in before closing the tab.
  if (startupError == null && kIsWeb) {
    try {
      // Set LOCAL persistence so the user stays logged in across
      // browser sessions (tabs closing, phone sleeping, etc.)
      await FirebaseAuth.instance
          .setPersistence(Persistence.LOCAL);

      if (kDebugMode) {
        debugPrint('🔐 main() | Web persistence set to LOCAL');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔐 main() | setPersistence error (non-fatal): $e');
      }
    }

    // Safety net: consume any pending redirect result from old code paths
    try {
      final result =
          await FirebaseAuth.instance.getRedirectResult();
      if (result.user != null && kDebugMode) {
        debugPrint(
            '🔐 main() | Safety-net redirect result: '
            'uid=${result.user!.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 main() | getRedirectResult (safety-net): $e');
      }
    }

    // Wait for Firebase to restore auth state from IndexedDB.
    // This is the KEY fix for "user appears logged out on first render":
    // authStateChanges always emits null first, then the real user.
    // We wait for the FIRST non-loading emission (up to 5 seconds).
    try {
      await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint(
                '🔐 main() | authStateChanges timeout — '
                'proceeding as guest');
          }
          return null;
        },
      );

      if (kDebugMode) {
        final u = FirebaseAuth.instance.currentUser;
        debugPrint(
            '🔐 main() | Auth state resolved → '
            '${u != null ? 'uid=${u.uid}' : 'guest'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 main() | authStateChanges error (non-fatal): $e');
      }
    }
  }

  // ── Step 3: Register FCM background handler (non-web only) ───────────────
  if (startupError == null && !kIsWeb) {
    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    } catch (e, st) {
      startupError =
          Exception('FCM background registration failed: $e');
      startupStack = st;
    }
  }

  // ── Step 4: Initialize local notifications (non-web only) ────────────────
  if (startupError == null && !kIsWeb) {
    try {
      await LocalNotificationService.instance
          .initialize()
          .timeout(const Duration(seconds: 8));
    } catch (e, st) {
      startupError =
          Exception('Local notification init failed: $e');
      startupStack = st;
    }
  }

  // ── Step 5: Launch ───────────────────────────────────────────────────────
  runApp(
    startupError == null
        ? const IftApp()
        : StartupErrorApp(
            error: startupError!,
            stackTrace: startupStack,
          ),
  );

  if (startupError == null && !kIsWeb) {
    unawaited(_initializeFcmNonBlocking());
  }

  if (startupError == null && kIsWeb) {
    unawaited(_initializeFcmWebNonBlocking());
  }
}

Future<void> _initializeFcmNonBlocking() async {
  try {
    await FcmService.instance
        .initialize()
        .timeout(const Duration(seconds: 20));
  } catch (_) {}
}

Future<void> _initializeFcmWebNonBlocking() async {
  try {
    await FcmService.instance
        .initialize()
        .timeout(const Duration(seconds: 20));
  } catch (_) {}
}

class StartupErrorApp extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;

  const StartupErrorApp({
    super.key,
    required this.error,
    this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0B0B0B),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFD4AF37),
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'App failed to start',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      '$error',
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}