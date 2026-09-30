import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../providers/discovery_providers.dart';
import '../../providers/user_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/person_card.dart';
import '../../widgets/profile_navigator_controls.dart';
import '../discovery/widgets/match_celebration_dialog.dart';

/// People who liked the current user, mirroring the Discover/Matches card
/// design. Liking someone back here either forms a match (celebrated with
/// the same dialog as swiping) or just records the like.
class LikesListScreen extends ConsumerStatefulWidget {
  const LikesListScreen({super.key});

  @override
  ConsumerState<LikesListScreen> createState() => _LikesListScreenState();
}

class _LikesListScreenState extends ConsumerState<LikesListScreen> {
  int _currentIndex = 0;
  final Set<String> _likedBackUids = <String>{};
  bool _likingBack = false;

  void _goPrevious() {
    if (_currentIndex <= 0) return;
    setState(() => _currentIndex--);
  }

  void _goNext(int totalCount) {
    if (_currentIndex >= totalCount - 1) return;
    setState(() => _currentIndex++);
  }

  Future<void> _likeBack(BuildContext context, String myUid, AppUser admirer) async {
    if (_likingBack || _likedBackUids.contains(admirer.uid)) return;

    setState(() => _likingBack = true);
    final me = ref.read(currentAppUserProvider).valueOrNull;
    final result = await ref.read(swipeServiceProvider).recordSwipe(
          meUid: myUid,
          targetUid: admirer.uid,
          liked: true,
        );

    if (!mounted) return;
    setState(() {
      _likingBack = false;
      _likedBackUids.add(admirer.uid);
    });

    if (result.isMatch && context.mounted && me != null) {
      await MatchCelebrationDialog.show(context, me: me, match: admirer);
    }
  }

  @override
  Widget build(BuildContext context) {
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

          if (_currentIndex >= admirers.length && admirers.isNotEmpty) {
            _currentIndex = admirers.length - 1;
          }

          if (admirers.isEmpty) {
            _currentIndex = 0;
            _likedBackUids.clear();
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

          final admirer = admirers[_currentIndex];
          final alreadyLikedBack = _likedBackUids.contains(admirer.uid);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: PersonCard(
                    person: admirer,
                    currentUid: myUid,
                    onLike: (alreadyLikedBack || _likingBack)
                        ? null
                        : () => _likeBack(context, myUid, admirer),
                  ),
                ),
              ),
              if (alreadyLikedBack)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Liked back already. Use arrows to browse.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ProfileNavigatorControls(
                  currentIndex: _currentIndex,
                  totalCount: admirers.length,
                  onPrevious: _currentIndex > 0 ? _goPrevious : null,
                  onNext: _currentIndex < admirers.length - 1 ? () => _goNext(admirers.length) : null,
                  onRefresh: () => ref.invalidate(admirersProvider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
