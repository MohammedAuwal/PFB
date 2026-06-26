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
        _googleSignIn = googleSignIn ?? GoogleSignIn(
          // ✅ Configure for Phlakes Fabric
          scopes: ['email', 'profile'],
          serverClientId: '1089917254734-tfkid7lmbe20tr9p6u459bvil8qssm7v.apps.googleusercontent.com',
        );

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// Error message from the last redirect sign-in attempt (web only).
  /// The login page can read and display this, then call
  /// [clearRedirectError] to clear it.
  static String? pendingRedirectError;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // ────────────────────────────────────────────────────────────────────────────
  // REDIRECT RESULT HANDLING (web)
  // ────────────────────────────────────────────────────────────────────────────

  /// Processes any pending redirect-based Google Sign-In result on web.
  ///
  /// **MUST be called during app bootstrap** (e.g. splash screen) before
  /// checking [currentUser].  On web, after `signInWithRedirect` navigates
  /// the browser to Google and back, this method retrieves the credential
  /// that Firebase Auth stored in the redirect callback URL.
  ///
  /// - If a redirect sign-in succeeded, the [User] is returned and FCM is
  ///   synced.
  /// - If there was no pending redirect (normal app launch), returns `null`.
  /// - If the redirect sign-in failed, the error is stored in
  ///   [pendingRedirectError] and `null` is returned (no exception thrown
  ///   so bootstrap can continue to the login page).
  Future<User?> handleRedirectResult() async {
    if (!kIsWeb) return null;

    try {
      final UserCredential? userCredential =
          await _firebaseAuth.getRedirectResult();

      final user = userCredential?.user;

      if (user != null) {
        await FcmService.instance.syncTokenForCurrentUser();
        if (kDebugMode) {
          debugPrint(
            '🔐 Phlakes Fabric | Redirect result: success uid=${user.uid}',
          );
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '🔐 Phlakes Fabric | Redirect FirebaseAuthException: '
          'code=${e.code}, message=${e.message}',
        );
      }
      pendingRedirectError = _mapFirebaseError(e.code, e.message);
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔐 Phlakes Fabric | Redirect result error: $e');
      }
      pendingRedirectError = 'Google Sign-In redirect failed. Please try again.';
      return null;
    }
  }

  /// Clears [pendingRedirectError]. Call this from the login page after
  /// displaying the error to the user.
  static void clearRedirectError() {
    pendingRedirectError = null;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // EMAIL / PASSWORD
  // ────────────────────────────────────────────────────────────────────────────

  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
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
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
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

  // ────────────────────────────────────────────────────────────────────────────
  // GOOGLE SIGN-IN
  // ────────────────────────────────────────────────────────────────────────────

  Future<User?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        debugPrint(
          '🔐 Phlakes Fabric | Google Sign-In: starting (kIsWeb=$kIsWeb)',
        );
      }

      // ── WEB: Use redirect flow (reliable on all browsers) ────────────────
      //  signInWithRedirect navigates the entire page to Google.
      //  It returns void because the current page context is destroyed.
      //  When the user returns, handleRedirectResult() (called during
      //  bootstrap in the splash screen) processes the credential via
      //  getRedirectResult().
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        provider.addScope('email');
        provider.addScope('profile');

        // This returns void — the browser navigates away.
        await _firebaseAuth.signInWithRedirect(provider);

        // If we reach here the redirect didn't navigate away (rare edge
        // case). Check currentUser as a fallback.
        final user = _firebaseAuth.currentUser;
        if (user != null) {
          await FcmService.instance.syncTokenForCurrentUser();
          if (kDebugMode) {
            debugPrint(
              '🔐 Phlakes Fabric | Google Sign-In (no-redirect path): '
              'success uid=${user.uid}',
            );
          }
        }
        return user;
      }

      // ── ANDROID: Use google_sign_in then exchange token ─────────────────
      else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          throw AuthFailure('Google sign-in was cancelled.');
        }

        if (kDebugMode) {
          debugPrint(
            '🔐 Phlakes Fabric | Google Sign-In: account selected '
            '${googleUser.email}',
          );
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

        final userCredential =
            await _firebaseAuth.signInWithCredential(credential);

        final user = userCredential.user;
        if (user == null) {
          throw AuthFailure('Google sign-in failed. Please try again.');
        }

        await FcmService.instance.syncTokenForCurrentUser();

        if (kDebugMode) {
          debugPrint(
            '🔐 Phlakes Fabric | Google Sign-In: success uid=${user.uid}',
          );
        }

        return user;
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '🔐 Phlakes Fabric | FirebaseAuthException: '
          'code=${e.code}, message=${e.message}',
        );
      }
      throw AuthFailure(_mapFirebaseError(e.code, e.message));
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '🔐 Phlakes Fabric | PlatformException: '
          'code=${e.code}, message=${e.message}',
        );
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

  // ────────────────────────────────────────────────────────────────────────────
  // SIGN OUT
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await FcmService.instance.removeCurrentDeviceTokenForCurrentUser();
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

  // ────────────────────────────────────────────────────────────────────────────
  // ERROR MAPPING
  // ────────────────────────────────────────────────────────────────────────────

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