import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  String? get currentUid => _auth.currentUser?.uid;

  /// Must be awaited exactly once, before the first [signInWithGoogle] call.
  /// Called during app bootstrap in `main.dart`, alongside `Firebase.initializeApp`.
  Future<void> initializeGoogleSignIn() {
    return GoogleSignIn.instance.initialize();
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn.instance.authenticate();
    final credential = GoogleAuthProvider.credential(
      idToken: googleUser.authentication.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Sign in with Apple, iOS/macOS only (see `SignInWithApple.isAvailable()`).
  /// Uses a hashed nonce so the ID token can't be replayed against a
  /// different sign-in attempt.
  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: hashedNonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );
    return _auth.signInWithCredential(oauthCredential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // Also clear the cached Google session so the account picker reappears
    // next time, rather than silently re-signing the same account back in.
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Not signed in with Google (e.g. the account used Apple) — fine.
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }
}
