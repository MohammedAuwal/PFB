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

  // Only apply system UI overlay on non-web platforms
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

  // ── Step 2 (Web only): Consume any pending Google redirect result ─────────
  //
  // WHAT HAPPENS:
  //   When the user clicks "Continue with Google", we call
  //   signInWithRedirect(). The browser leaves the app, goes to Google,
  //   the user picks their account, and Google sends the browser BACK to
  //   your app URL (phlakesfabric.web.app).
  //
  // THE PROBLEM:
  //   On return, your Flutter app cold-boots from scratch. FirebaseAuth
  //   has the credential stored in IndexedDB/sessionStorage, but it is
  //   NOT yet applied to currentUser. It only gets applied AFTER you call
  //   getRedirectResult(). If you don't call it, currentUser stays null,
  //   SplashScreen routes the user as a guest, and the sign-in appears to
  //   have failed.
  //
  // THE FIX:
  //   Call getRedirectResult() HERE — before runApp() — so that by the
  //   time SplashScreen reads FirebaseAuth.instance.currentUser the user
  //   is fully authenticated and routing works correctly.
  if (startupError == null && kIsWeb) {
    try {
      final result =
          await FirebaseAuth.instance.getRedirectResult();

      if (kDebugMode) {
        if (result.user != null) {
          debugPrint(
            '🔐 main() | ✅ Google redirect sign-in resolved → '
            'uid=${result.user!.uid} '
            'email=${result.user!.email}',
          );
        } else {
          debugPrint(
            '🔐 main() | No pending redirect result '
            '(normal cold start)',
          );
        }
      }
    } catch (e) {
      // This is NOT fatal. It fires on every normal cold start with
      // code 'no-auth-event'. We only log it in debug mode.
      if (kDebugMode) {
        debugPrint('🔐 main() | getRedirectResult info: $e');
      }
      // Do NOT set startupError here — the app must still launch.
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

  // ── Step 5: Launch the app ───────────────────────────────────────────────
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

// ── FCM init for Android/iOS (non-blocking) ───────────────────────────────────
Future<void> _initializeFcmNonBlocking() async {
  try {
    await FcmService.instance
        .initialize()
        .timeout(const Duration(seconds: 20));
  } catch (_) {}
}

// ── FCM init for Web (non-blocking, best-effort) ──────────────────────────────
Future<void> _initializeFcmWebNonBlocking() async {
  try {
    await FcmService.instance
        .initialize()
        .timeout(const Duration(seconds: 20));
  } catch (_) {
    // FCM on web requires HTTPS and a valid VAPID key.
    // Failures here are non-fatal — the app works without push notifications.
  }
}

// ── Startup Error Screen ──────────────────────────────────────────────────────

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