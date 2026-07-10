import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../providers/discovery_providers.dart';
import '../../providers/user_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'widgets/match_celebration_dialog.dart';
import 'widgets/swipe_action_buttons.dart';
import 'widgets/swipe_card_stack.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final _controller = CardSwiperController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
    AppUser me,
    List<AppUser> candidates,
  ) async {
    final target = candidates[previousIndex];
    final liked = direction == CardSwiperDirection.right || direction == CardSwiperDirection.top;
    final superLike = direction == CardSwiperDirection.top;

    try {
      final result = await ref.read(swipeServiceProvider).recordSwipe(
            meUid: me.uid,
            targetUid: target.uid,
            liked: liked,
            superLike: superLike,
          );

      if (result.isMatch && mounted) {
        await MatchCelebrationDialog.show(context, me: me, match: target);
      }
      return true;
    } catch (e) {
      // Returning false tells CardSwiper to animate the card back into
      // place instead of leaving it stuck off-screen — without this, an
      // uncaught error here breaks the package's internal reset and the
      // card just vanishes with no way to recover it.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't record that. Please try again.")),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidatesAsync = ref.watch(candidatesProvider);
    final meAsync = ref.watch(currentAppUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: SafeArea(
        child: candidatesAsync.when(
          loading: () => const LoadingView(),
          error: (error, stack) => ErrorView(
            message: 'Could not load candidates.\n$error',
            onRetry: () => ref.invalidate(candidatesProvider),
          ),
          data: (candidates) {
            final me = meAsync.valueOrNull;
            if (me == null) return const LoadingView();
            if (candidates.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        'No one new nearby right now.\nCheck back later!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(candidatesProvider),
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SwipeCardStack(
                      candidates: candidates,
                      currentUid: me.uid,
                      controller: _controller,
                      onSwipe: (previousIndex, currentIndex, direction) =>
                          _onSwipe(previousIndex, currentIndex, direction, me, candidates),
                      onEnd: () => ref.invalidate(candidatesProvider),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: SwipeActionButtons(controller: _controller),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
