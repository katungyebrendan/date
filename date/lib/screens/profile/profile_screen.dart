import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/relationship_intent.dart';
import '../../providers/match_providers.dart';
import '../../providers/user_providers.dart';
import '../../routing/route_paths.dart';
import '../../utils/age_calculator.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentAppUserProvider);
    final matchCount = ref.watch(matchesListProvider).valueOrNull?.length ?? 0;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const LoadingView(),
        error: (error, stack) => ErrorView(message: 'Could not load your profile.\n$error'),
        data: (user) {
          if (user == null) return const LoadingView();
          final age = user.birthdate != null ? AgeCalculator.ageFromBirthdate(user.birthdate!) : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.4)],
                    ),
                  ),
                  child: AppAvatar(
                    photoUrl: user.photoUrls.isNotEmpty ? user.photoUrls.first : null,
                    radius: 64,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  age != null ? '${user.displayName}, $age' : user.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (user.city.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(user.city, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ],
                if (user.intent != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Looking for ${user.intent!.label}',
                          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
                if (user.bio.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(user.bio, textAlign: TextAlign.center),
                ],
                if (user.interests.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.interests_outlined, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Interests', style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: user.interests.map((interest) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [colorScheme.primary, colorScheme.secondary],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  interest,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatColumn(
                          icon: Icons.visibility_outlined,
                          iconColor: colorScheme.onSurfaceVariant,
                          value: user.viewCount,
                          label: 'Views',
                        ),
                        _StatColumn(
                          icon: Icons.favorite,
                          iconColor: colorScheme.primary,
                          value: user.likeCount,
                          label: 'Likes',
                        ),
                        _StatColumn(
                          icon: Icons.people_alt_outlined,
                          iconColor: Colors.green,
                          value: matchCount,
                          label: 'Matches',
                        ),
                      ],
                    ),
                  ),
                ),
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
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push(RoutePaths.editProfile),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(height: 6),
        Text('$value', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
