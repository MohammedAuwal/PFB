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
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

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
      throw AuthFailure('Login failed. Please try again.');
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
      throw AuthFailure('Registration failed. Please try again.');
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        debugPrint('Google Sign-In: starting');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthFailure('Google sign-in was cancelled.');
      }

      if (kDebugMode) {
        debugPrint('Google Sign-In: account selected ${googleUser.email}');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (kDebugMode) {
        debugPrint(
          'Google Sign-In: idToken exists=${(googleAuth.idToken ?? '').isNotEmpty}, accessToken exists=${(googleAuth.accessToken ?? '').isNotEmpty}',
        );
      }

      if ((googleAuth.idToken ?? '').isEmpty) {
        throw AuthFailure(
          'Google sign-in failed because no ID token was returned. This usually means Firebase/Google OAuth Android configuration is incorrect.',
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
        throw AuthFailure(
          'Google sign-in failed. Firebase did not return a user.',
        );
      }

      await FcmService.instance.syncTokenForCurrentUser();

      if (kDebugMode) {
        debugPrint('Google Sign-In: success uid=${user.uid}');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Google Sign-In FirebaseAuthException: code=${e.code}, message=${e.message}',
        );
      }
      throw AuthFailure(_mapFirebaseError(e.code, e.message));
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Google Sign-In PlatformException: code=${e.code}, message=${e.message}, details=${e.details}',
        );
      }

      throw AuthFailure(_mapGooglePlatformError(e));
    } catch (e) {
      if (e is AuthFailure) rethrow;

      if (kDebugMode) {
        debugPrint('Google Sign-In unknown error: $e');
      }

      throw AuthFailure('Google Sign-In failed. Details: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await FcmService.instance.removeCurrentDeviceTokenForCurrentUser();
    } catch (_) {}

    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await _firebaseAuth.signOut();
  }

  String _mapGooglePlatformError(PlatformException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    final details = (e.details ?? '').toString().toLowerCase();

    final combined = '$code $message $details';

    if (combined.contains('10') ||
        combined.contains('developer_error') ||
        combined.contains('sign_in_failed')) {
      return 'Google Sign-In configuration error on Android. Check Firebase Google provider, package name, SHA-1, SHA-256, and google-services.json.';
    }

    if (combined.contains('network_error')) {
      return 'Network error during Google sign-in. Please check your internet connection.';
    }

    if (combined.contains('sign_in_canceled') ||
        combined.contains('canceled') ||
        combined.contains('cancelled')) {
      return 'Google sign-in was cancelled.';
    }

    if (combined.contains('12500')) {
      return 'Google Sign-In failed due to OAuth configuration. Verify SHA fingerprints and Firebase Auth Google provider.';
    }

    if (combined.contains('12501')) {
      return 'Google sign-in was cancelled.';
    }

    if (combined.contains('12502')) {
      return 'Google sign-in is already in progress. Please wait and try again.';
    }

    return 'Google Sign-In failed. Platform error: code=${e.code}, message=${e.message}, details=${e.details}';
  }

  String _mapFirebaseError(String code, String? message) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'account-exists-with-different-credential':
        return 'This email is already linked to another sign-in method. Sign in with that method first.';
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled in Firebase Authentication.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return message ?? 'Authentication failed. Please try again.';
    }
  }
}
