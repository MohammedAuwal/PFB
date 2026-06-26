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

  // ── NEW: Call this once on app start (web only) ──────────────────────────
  // Reads the OAuth credential that Firebase saved in session storage
  // after the Google redirect completes.  Must be awaited before routing.
  Future<User?> getRedirectResultIfAny() async {
    if (!kIsWeb) return null;

    try {
      if (kDebugMode) {
        debugPrint(
            '🔐 Phlakes Fabric | Checking for pending redirect result…');
      }

      final result = await _firebaseAuth
          .getRedirectResult()
          .timeout(const Duration(seconds: 10));

      final user = result.user;

      if (user != null) {
        if (kDebugMode) {
          debugPrint(
              '🔐 Phlakes Fabric | Redirect result resolved → uid=${user.uid}');
        }

        try {
          await FcmService.instance.syncTokenForCurrentUser();
        } catch (_) {}
      }

      return user;
    } on FirebaseAuthException catch (e) {
      // Translate to AuthFailure so callers can surface a message.
      if (kDebugMode) {
        debugPrint(
            '🔐 Phlakes Fabric | getRedirectResult FirebaseAuthException: '
            'code=${e.code}');
      }
      // Only rethrow meaningful errors; an empty result is not an error.
      if (e.code != 'no-auth-event') {
        throw AuthFailure(_mapFirebaseError(e.code, e.message));
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 Phlakes Fabric | getRedirectResult unknown error: $e');
      }
      // Non-fatal – just means no pending redirect.
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

  Future<User?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        debugPrint(
            '🔐 Phlakes Fabric | Google Sign-In: starting (kIsWeb=$kIsWeb)');
      }

      UserCredential userCredential;

      // ── WEB ──────────────────────────────────────────────────────────────
      // Use signInWithRedirect instead of signInWithPopup.
      //
      // WHY:
      //   • signInWithPopup on many browsers (Safari, Firefox, Chrome on
      //     mobile, strict cookie policies) silently falls back to a redirect
      //     flow anyway, but the app never calls getRedirectResult(), so the
      //     credential is lost and the page looks like it crashed.
      //   • signInWithRedirect is universally supported and the result is
      //     reliably captured via getRedirectResult() which we now call in
      //     SplashScreen before routing.
      //
      // FLOW:
      //   1. signInWithRedirect  →  browser leaves the app
      //   2. Google OAuth completes  →  browser returns to app
      //   3. SplashScreen calls getRedirectResultIfAny()
      //   4. User is signed in, routing proceeds normally
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        provider.addScope('email');
        provider.addScope('profile');

        // This call navigates the browser away.  It does NOT return a
        // UserCredential here – the result is read by getRedirectResultIfAny()
        // after the browser returns to the app.
        await _firebaseAuth.signInWithRedirect(provider);

        // We will never reach this line during the current page lifecycle.
        // Return null so the caller knows to wait for the redirect result.
        return null;
      }

      // ── ANDROID ──────────────────────────────────────────────────────────
      else {
        final GoogleSignInAccount? googleUser =
            await _googleSignIn.signIn();

        if (googleUser == null) {
          throw AuthFailure('Google sign-in was cancelled.');
        }

        if (kDebugMode) {
          debugPrint(
              '🔐 Phlakes Fabric | Google Sign-In: account selected '
              '${googleUser.email}');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        if (kDebugMode) {
          debugPrint(
            '🔐 Phlakes Fabric | Google Sign-In: '
            'idToken=${(googleAuth.idToken ?? '').isNotEmpty}, '
            'accessToken=${(googleAuth.accessToken ?? '').isNotEmpty}',
          );
        }

        if ((googleAuth.idToken ?? '').isEmpty) {
          throw AuthFailure(
            'Google sign-in failed. No ID token returned. '
            'Verify SHA-1 fingerprint is registered in Firebase Console '
            'for com.pfb.app',
          );
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential =
            await _firebaseAuth.signInWithCredential(credential);

        final user = userCredential.user;
        if (user == null) {
          throw AuthFailure(
              'Google sign-in failed. Please try again.');
        }

        await FcmService.instance.syncTokenForCurrentUser();

        if (kDebugMode) {
          debugPrint(
              '🔐 Phlakes Fabric | Google Sign-In: success uid=${user.uid}');
        }

        return user;
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 Phlakes Fabric | FirebaseAuthException: '
            'code=${e.code}, message=${e.message}');
      }
      throw AuthFailure(_mapFirebaseError(e.code, e.message));
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 Phlakes Fabric | PlatformException: '
            'code=${e.code}, message=${e.message}');
      }
      throw AuthFailure(_mapGooglePlatformError(e));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      if (kDebugMode) {
        debugPrint('🔐 Phlakes Fabric | Unknown error: $e');
      }
      throw AuthFailure('Google Sign-In failed. Please try again.');
    }
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
      debugPrint('🔐 Phlakes Fabric | User signed out');
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
        return 'Popup blocked. Allow popups and try again.';
      default:
        return message ?? 'Authentication failed. Please try again.';
    }
  }
}