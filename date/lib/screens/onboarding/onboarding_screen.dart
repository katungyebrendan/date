import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../providers/storage_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_view.dart';
import 'onboarding_draft.dart';
import 'steps/bio_step.dart';
import 'steps/gender_preference_step.dart';
import 'steps/interests_step.dart';
import 'steps/location_step.dart';
import 'steps/name_birthdate_step.dart';
import 'steps/photos_step.dart';
import 'widgets/onboarding_progress_bar.dart';

const _totalSteps = 6;

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _draft = OnboardingDraft();
  int _step = 0;
  bool _submitting = false;
  String? _error;

  void _next() => setState(() => _step++);
  void _back() => setState(() => _step--);

  Future<void> _finish() async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final storageService = ref.read(storageServiceProvider);
      final photoUrls = <String>[];
      for (final file in _draft.photos) {
        photoUrls.add(await storageService.uploadPhoto(uid, file));
      }

      final current = await ref.read(userRepositoryProvider).getUser(uid);
      final profile = (current ?? AppUser.newAccount(uid: uid)).copyWith(
        displayName: _draft.displayName,
        birthdate: _draft.birthdate,
        gender: _draft.gender,
        interestedIn: _draft.interestedIn,
        bio: _draft.bio,
        photoUrls: photoUrls,
        city: _draft.city,
        interests: _draft.interests.toList(),
        intent: _draft.intent,
      );
      await ref.read(userRepositoryProvider).completeOnboarding(profile);
    } catch (error, stackTrace) {
      debugPrint('Onboarding save failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      var message = 'Something went wrong saving your profile. Please try again.';
      if (error is FirebaseException) {
        if (error.code == 'permission-denied') {
          message = 'Permission denied while saving your profile. Please sign in again and retry.';
        } else if (error.code == 'unavailable') {
          message = 'Network unavailable. Check your connection and try again.';
        }
      }

      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final steps = <Widget>[
      NameBirthdateStep(draft: _draft, onNext: _next),
      GenderPreferenceStep(draft: _draft, onNext: _next),
      BioStep(draft: _draft, onNext: _next),
      InterestsStep(draft: _draft, onNext: _next),
      PhotosStep(draft: _draft, onNext: _next),
      LocationStep(draft: _draft, onFinish: _finish, loading: _submitting),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: _step > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back)
            : null,
        title: const Text('Set up your profile'),
      ),
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFF4F7), Color(0xFFF7F4FF), Color(0xFFF1FBFE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.7)),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Build a profile that feels like you.',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share a few details and we will shape the experience around your vibe.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      OnboardingProgressBar(step: _step, totalSteps: _totalSteps),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  ErrorView(message: _error!),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.65)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SingleChildScrollView(child: steps[_step]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
