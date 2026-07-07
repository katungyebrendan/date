import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../providers/discovery_providers.dart';
import '../../providers/user_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/person_card.dart';
import '../discovery/widgets/match_celebration_dialog.dart';

/// People who liked the current user, mirroring the Discover/Matches card
/// design. Liking someone back here either forms a match (celebrated with
/// the same dialog as swiping) or just records the like.
class LikesListScreen extends ConsumerWidget {
  const LikesListScreen({super.key});

  Future<void> _likeBack(BuildContext context, WidgetRef ref, String myUid, AppUser admirer) async {
    final me = ref.read(currentAppUserProvider).valueOrNull;
    final result = await ref.read(swipeServiceProvider).recordSwipe(
          meUid: myUid,
          targetUid: admirer.uid,
          liked: true,
        );
    ref.invalidate(admirersProvider);
    if (result.isMatch && context.mounted && me != null) {
      await MatchCelebrationDialog.show(context, me: me, match: admirer);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admirersAsync = ref.watch(admirersProvider);
    final myUid = ref.watch(currentAppUserProvider).valueOrNull?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Likes')),
      body: admirersAsync.when(
        loading: () => const LoadingView(),
        error: (error, stack) => ErrorView(
          message: 'Could not load your likes.\n$error',
          onRetry: () => ref.invalidate(admirersProvider),
        ),
        data: (admirers) {
          if (myUid == null) return const LoadingView();
          if (admirers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      'No likes yet.\nPeople who like you will show up here!',
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
            itemCount: admirers.length,
            itemBuilder: (context, index) {
              final admirer = admirers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PersonCard(
                  person: admirer,
                  currentUid: myUid,
                  onLike: () => _likeBack(context, ref, myUid, admirer),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
