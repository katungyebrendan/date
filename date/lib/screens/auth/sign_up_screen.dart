import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../providers/user_providers.dart';
import '../../routing/route_paths.dart';
import '../../utils/phone_utils.dart';
import '../../utils/validators.dart';
import '../../widgets/primary_button.dart';
import 'widgets/auth_text_field.dart';

/// Creates the account and claims a unique WhatsApp number. Everything else
/// (name, birthdate, gender, bio, interests, photos, location) is collected
/// afterwards by [OnboardingScreen], which the router sends new accounts to.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final phoneNumber = normalizePhoneNumber(_phoneController.text);
    final authService = ref.read(authServiceProvider);
    final userRepository = ref.read(userRepositoryProvider);

    try {
      final credential = await authService.signUpAnonymous();
      final uid = credential.user!.uid;

      final claimed = await userRepository.reservePhoneNumber(
        uid: uid,
        phoneNumber: phoneNumber,
      );
      if (!claimed) {
        await authService.signOut();
        setState(() => _errorMessage = 'This WhatsApp number is already registered to another account.');
        return;
      }

      final newUser = AppUser.newAccount(uid: uid).copyWith(phoneNumber: phoneNumber);
      await userRepository.createUserDoc(newUser);

      if (mounted) context.go(RoutePaths.onboarding);
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Create your account',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  "We'll use this to identify your account. One WhatsApp number can only be used by one profile.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                AuthTextField(
                  controller: _phoneController,
                  label: 'WhatsApp Number',
                  keyboardType: TextInputType.phone,
                  validator: Validators.whatsappNumber,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Continue',
                  onPressed: _submit,
                  loading: _loading,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go(RoutePaths.signIn),
                  child: const Text('Already have an account? Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
