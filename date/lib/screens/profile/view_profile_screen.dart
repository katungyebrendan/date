import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_providers.dart';
import '../../utils/age_calculator.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

/// Read-only view of another user's profile, opened by tapping a
/// [PersonCard]'s photo on Discover, Matches or Likes.
class ViewProfileScreen extends ConsumerWidget {
  const ViewProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userAsync.when(
        loading: () => const LoadingView(),
        error: (error, stack) => ErrorView(message: 'Could not load this profile.\n$error'),
        data: (user) {
          if (user == null) return const ErrorView(message: 'This profile is no longer available.');
          final age = user.birthdate != null ? AgeCalculator.ageFromBirthdate(user.birthdate!) : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                AppAvatar(
                  photoUrl: user.photoUrls.isNotEmpty ? user.photoUrls.first : null,
                  radius: 72,
                ),
                const SizedBox(height: 16),
                Text(
                  age != null ? '${user.displayName}, $age' : user.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (user.city.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(user.city, style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (user.bio.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(user.bio, textAlign: TextAlign.center),
                ],
                if (user.photoUrls.length > 1) ...[
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: user.photoUrls.length,
                    itemBuilder: (context, index) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(user.photoUrls[index], fit: BoxFit.cover),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
