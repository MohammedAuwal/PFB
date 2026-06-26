import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pfb/services/fcm_service.dart';

class AuthFailure implements Exception {
  final String message;
  AuthFailure(this.message);

  @override
  String toString() => message;
}

class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
              serverClientId:
                  '1089917254734-tfkid7lmbe20tr9p6u459bvil8qssm7v.apps.googleusercontent.com',
            );

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  // ── Web-only: check for any pending redirect result ───────────────────────
  // Still kept for safety but popup is now the primary web flow.
  Future<User?> getRedirectResultIfAny() async {
    if (!kIsWeb) return null;
    try {
      final result = await _firebaseAuth
          .getRedirectResult()
          .timeout(const Duration(seconds: 10));
      final user = result.user;
      if (user != null) {
        if (kDebugMode) {
          debugPrint(
              '🔐 PhlakesFabric | Redirect result found → '
              'uid=${user.uid}');
        }
        try {
          await FcmService.instance.syncTokenForCurrentUser();
        } catch (_) {}
      }
      return user;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔐 PhlakesFabric | getRedirectResult: $e');
      }
      return null;
    }
  }

  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await FcmService.instance.syncTokenForCurrentUser();
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e.code, e.message));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure('Sign in failed. Please try again.');
    }
  }

  Future<User?> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await FcmService.instance.syncTokenForCurrentUser();
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e.code, e.message));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure('Account creation failed. Please try again.');
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  //
  // WEB STRATEGY — signInWithPopup with authStateChanges fallback:
  //
  //   Flutter Web's signInWithRedirect always routes through
  //   firebaseapp.com/__/auth/handler regardless of your authDomain
  //   setting. When the browser returns to web.app, the credential
  //   written to sessionStorage at firebaseapp.com is inaccessible
  //   (different origin → browser blocks it). Sign-in silently fails.
  //
  //   signInWithPopup keeps everything in the SAME browser tab origin.
  //   The popup opens, OAuth completes, the credential is handed back
  //   directly to the Flutter app — no cross-origin sessionStorage issue.
  //
  //   The popup may be blocked by some mobile browsers. We handle that
  //   with a clear user-facing message and a fallback path.
  Future<User?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        debugPrint(
            '🔐 PhlakesFabric | Google Sign-In start '
            '(kIsWeb=$kIsWeb)');
      }

      // ── WEB: signInWithPopup ────────────────────────────────────
      if (kIsWeb) {
        return await _signInWithGooglePopupWeb();
      }

      // ── ANDROID: google_sign_in package ────────────────────────
      return await _signInWithGoogleAndroid();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 PhlakesFabric | FirebaseAuthException: '
            'code=${e.code} message=${e.message}');
      }
      throw AuthFailure(_mapFirebaseError(e.code, e.message));
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 PhlakesFabric | PlatformException: '
            'code=${e.code} message=${e.message}');
      }
      throw AuthFailure(_mapGooglePlatformError(e));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      if (kDebugMode) {
        debugPrint('🔐 PhlakesFabric | Unknown error: $e');
      }
      throw AuthFailure('Google Sign-In failed. Please try again.');
    }
  }

  // ── Web popup implementation ──────────────────────────────────────────────
  Future<User?> _signInWithGooglePopupWeb() async {
    final provider = GoogleAuthProvider();
    provider.setCustomParameters({'prompt': 'select_account'});
    provider.addScope('email');
    provider.addScope('profile');

    try {
      // Attempt 1: popup
      if (kDebugMode) {
        debugPrint(
            '🔐 PhlakesFabric | Web: trying signInWithPopup…');
      }

      final userCredential =
          await _firebaseAuth.signInWithPopup(provider);

      final user = userCredential.user;
      if (user == null) {
        throw AuthFailure(
            'Google sign-in failed. Please try again.');
      }

      if (kDebugMode) {
        debugPrint(
            '🔐 PhlakesFabric | Popup success uid=${user.uid}');
      }

      try {
        await FcmService.instance.syncTokenForCurrentUser();
      } catch (_) {}

      return user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 PhlakesFabric | Popup FirebaseAuthException: '
            'code=${e.code}');
      }

      // popup-blocked or popup-closed — these are expected on some
      // mobile browsers (Samsung Internet, in-app browsers, etc.)
      if (e.code == 'popup-blocked') {
        throw AuthFailure(
          'Pop-up blocked by your browser.\n\n'
          'Please allow pop-ups for phlakesfabric.web.app '
          'in your browser settings, then try again.\n\n'
          'On Chrome: tap the address bar → "Pop-ups blocked" → Allow.',
        );
      }

      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        throw AuthFailure('Google sign-in was cancelled.');
      }

      // web-context-cancelled fires on some mobile browsers when the
      // popup opens a new tab instead of a floating window and the
      // user is returned. In that case, check authStateChanges —
      // Firebase may have already signed the user in.
      if (e.code == 'web-context-cancelled' ||
          e.code == 'web-context-already-presented') {
        if (kDebugMode) {
          debugPrint(
              '🔐 PhlakesFabric | web-context issue — '
              'checking currentUser as fallback…');
        }
        // Give Firebase a moment to settle
        await Future.delayed(const Duration(milliseconds: 800));
        final fallbackUser = _firebaseAuth.currentUser;
        if (fallbackUser != null) {
          if (kDebugMode) {
            debugPrint(
                '🔐 PhlakesFabric | Fallback success '
                'uid=${fallbackUser.uid}');
          }
          try {
            await FcmService.instance.syncTokenForCurrentUser();
          } catch (_) {}
          return fallbackUser;
        }
        throw AuthFailure(
            'Google sign-in failed. Please try again.');
      }

      rethrow;
    }
  }

  // ── Android native implementation ─────────────────────────────────────────
  Future<User?> _signInWithGoogleAndroid() async {
    final GoogleSignInAccount? googleUser =
        await _googleSignIn.signIn();

    if (googleUser == null) {
      throw AuthFailure('Google sign-in was cancelled.');
    }

    if (kDebugMode) {
      debugPrint(
          '🔐 PhlakesFabric | Android account selected: '
          '${googleUser.email}');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    if ((googleAuth.idToken ?? '').isEmpty) {
      throw AuthFailure(
        'Google sign-in failed: no ID token returned. '
        'Verify SHA-1 fingerprint in Firebase Console for com.pfb.app',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null) {
      throw AuthFailure('Google sign-in failed. Please try again.');
    }

    await FcmService.instance.syncTokenForCurrentUser();

    if (kDebugMode) {
      debugPrint(
          '🔐 PhlakesFabric | Android success uid=${user.uid}');
    }

    return user;
  }

  Future<void> signOut() async {
    try {
      await FcmService.instance
          .removeCurrentDeviceTokenForCurrentUser();
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }

    await _firebaseAuth.signOut();

    if (kDebugMode) {
      debugPrint('🔐 PhlakesFabric | User signed out');
    }
  }

  String _mapGooglePlatformError(PlatformException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    final details = (e.details ?? '').toString().toLowerCase();
    final combined = '$code $message $details';

    if (combined.contains('10') ||
        combined.contains('developer_error') ||
        combined.contains('sign_in_failed')) {
      return 'Google Sign-In configuration error. '
          'Verify SHA-1 fingerprint in Firebase Console.';
    }
    if (combined.contains('network_error')) {
      return 'Network error. Please check your internet connection.';
    }
    if (combined.contains('sign_in_canceled') ||
        combined.contains('canceled') ||
        combined.contains('cancelled')) {
      return 'Google sign-in was cancelled.';
    }
    if (combined.contains('12500')) {
      return 'OAuth configuration error. '
          'Verify SHA fingerprints in Firebase Console.';
    }
    if (combined.contains('12501')) {
      return 'Google sign-in was cancelled.';
    }
    if (combined.contains('12502')) {
      return 'Google sign-in is in progress. Please wait.';
    }
    return 'Google Sign-In failed. Error: ${e.message}';
  }

  String _mapFirebaseError(String code, String? message) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'account-exists-with-different-credential':
        return 'This email uses a different sign-in method.';
      case 'operation-not-allowed':
        return 'Google Sign-In is not enabled. Contact support.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Google sign-in was cancelled.';
      case 'popup-blocked':
        return 'Pop-up blocked. Please allow pop-ups and try again.';
      default:
        return message ?? 'Authentication failed. Please try again.';
    }
  }
}