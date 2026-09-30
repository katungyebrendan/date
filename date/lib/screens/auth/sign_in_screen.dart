import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../providers/auth_providers.dart';

/// Shown once a user has accepted the data usage policy but isn't signed in
/// yet. Google/Apple are the only entry points — see `AuthService` for why
/// anonymous auth was dropped: a real identity lets accounts survive a
/// reinstall instead of being lost.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _loading = false;
  String? _errorMessage;

  Future<void> _signIn(Future<void> Function() signInMethod) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await signInMethod();
      // On success, the router reacts to the auth state change and
      // navigates on its own — nothing to do here.
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Couldn't sign in. Please try again.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueWithGoogle() {
    return _signIn(() => ref.read(authServiceProvider).signInWithGoogle());
  }

  Future<void> _continueWithApple() {
    return _signIn(() => ref.read(authServiceProvider).signInWithApple());
  }

  @override
  Widget build(BuildContext context) {
    final showAppleButton = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome to Velo',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Find your perfect cycling match',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _continueWithGoogle,
                  icon: const Icon(Icons.account_circle_outlined),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
                if (showAppleButton) ...[
                  const SizedBox(height: 12),
                  SignInWithAppleButton(
                    onPressed: _loading ? null : _continueWithApple,
                    height: 48,
                  ),
                ],
                if (_loading) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
