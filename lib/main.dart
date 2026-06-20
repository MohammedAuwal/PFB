import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pfb/app.dart';
import 'package:pfb/services/fcm_service.dart';
import 'package:pfb/services/local_notification_service.dart';
import 'package:pfb/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ── CRITICAL: Only initialize if NOT already initialized ───────
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  try {
    await FcmService.instance.handleBackgroundMessage(message);
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0B0B0B),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B0B0B),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  Object? startupError;
  StackTrace? startupStack;

  try {
    // ── CRITICAL: Only initialize if NOT already initialized ─────
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 12));
    }
    // ── If apps.isNotEmpty, Firebase is already init, skip ───────
  } catch (e, st) {
    startupError = Exception('Firebase init failed: $e');
    startupStack = st;
  }

  if (startupError == null) {
    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    } catch (e, st) {
      startupError = Exception('FCM background registration failed: $e');
      startupStack = st;
    }
  }

  if (startupError == null) {
    try {
      await LocalNotificationService.instance
          .initialize()
          .timeout(const Duration(seconds: 8));
    } catch (e, st) {
      startupError = Exception('Local notification init failed: $e');
      startupStack = st;
    }
  }

  runApp(
    startupError == null
        ? const IftApp()
        : StartupErrorApp(
            error: startupError!,
            stackTrace: startupStack,
          ),
  );

  if (startupError == null) {
    unawaited(_initializeFcmNonBlocking());
  }
}

Future<void> _initializeFcmNonBlocking() async {
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