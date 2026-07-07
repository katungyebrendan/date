import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/match.dart';
import '../../providers/match_providers.dart';
import '../../providers/user_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'widgets/match_person_card.dart';

class MatchesListScreen extends ConsumerWidget {
  const MatchesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesListProvider);
    final myUid = ref.watch(currentAppUserProvider).valueOrNull?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: matchesAsync.when(
        loading: () => const LoadingView(),
        error: (error, stack) => ErrorView(
          message: 'Could not load matches.\n$error',
          onRetry: () => ref.invalidate(matchesListProvider),
        ),
        data: (matches) {
          if (myUid == null) return const LoadingView();
          if (matches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      "No matches yet.\nKeep swiping to find your match!",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final MatchModel match = matches[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: MatchPersonCard(match: match, myUid: myUid),
              );
            },
          );
        },
      ),
    );
  }
}
