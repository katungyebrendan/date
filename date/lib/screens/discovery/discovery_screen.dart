import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../providers/discovery_providers.dart';
import '../../providers/user_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/person_card.dart';
import '../../widgets/profile_navigator_controls.dart';
import 'widgets/match_celebration_dialog.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  int _currentIndex = 0;
  final Set<String> _decidedUids = <String>{};
  bool _savingDecision = false;

  void _refreshDeck() {
    if (mounted) {
      setState(() {
        _currentIndex = 0;
        _decidedUids.clear();
      });
    }
    ref.invalidate(candidatesProvider);
  }

  void _goPrevious() {
    if (_currentIndex <= 0) return;
    setState(() => _currentIndex--);
  }

  void _goNext(int totalCount) {
    if (_currentIndex >= totalCount - 1) return;
    setState(() => _currentIndex++);
  }

  Future<void> _recordDecision({
    required AppUser me,
    required AppUser target,
    required bool liked,
    bool superLike = false,
  }) async {
    if (_savingDecision || _decidedUids.contains(target.uid)) return;

    setState(() => _savingDecision = true);

    try {
      final result = await ref
          .read(swipeServiceProvider)
          .recordSwipe(
            meUid: me.uid,
            targetUid: target.uid,
            liked: liked,
            superLike: superLike,
          );

      if (!mounted) return;
      setState(() => _decidedUids.add(target.uid));

      if (result.isMatch && mounted) {
        await MatchCelebrationDialog.show(context, me: me, match: target);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't record that. Please try again."),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingDecision = false);
      }
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
              if (_currentIndex != 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() => _currentIndex = 0);
                });
              }
              if (_decidedUids.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(_decidedUids.clear);
                });
              }
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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

            final safeIndex = _currentIndex < candidates.length
                ? _currentIndex
                : candidates.length - 1;
            if (safeIndex != _currentIndex) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _currentIndex = safeIndex);
              });
            }

            final current = candidates[safeIndex];
            final alreadyDecided = _decidedUids.contains(current.uid);

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: PersonCard(
                      person: current,
                      currentUid: me.uid,
                      onLike: (alreadyDecided || _savingDecision)
                          ? null
                          : () async {
                              await _recordDecision(
                                me: me,
                                target: current,
                                liked: true,
                              );
                              if (!mounted) return;
                              _goNext(candidates.length);
                            },
                    ),
                  ),
                ),
                ProfileNavigatorControls(
                  currentIndex: safeIndex,
                  totalCount: candidates.length,
                  onPrevious: safeIndex > 0 ? _goPrevious : null,
                  onNext: safeIndex < candidates.length - 1
                      ? () => _goNext(candidates.length)
                      : null,
                  onRefresh: _refreshDeck,
                ),
                const SizedBox(height: 18),
                if (alreadyDecided)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Decision saved for this profile. Use arrows to browse.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
