import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/match.dart';
import '../../providers/match_providers.dart';
import '../../providers/user_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/profile_navigator_controls.dart';
import 'widgets/match_person_card.dart';

class MatchesListScreen extends ConsumerStatefulWidget {
  const MatchesListScreen({super.key});

  @override
  ConsumerState<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends ConsumerState<MatchesListScreen> {
  int _currentIndex = 0;

  void _goPrevious() {
    if (_currentIndex <= 0) return;
    setState(() => _currentIndex--);
  }

  void _goNext(int totalCount) {
    if (_currentIndex >= totalCount - 1) return;
    setState(() => _currentIndex++);
  }

  @override
  Widget build(BuildContext context) {
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

          if (_currentIndex >= matches.length && matches.isNotEmpty) {
            _currentIndex = matches.length - 1;
          }

          if (matches.isEmpty) {
            _currentIndex = 0;
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

          final MatchModel match = matches[_currentIndex];
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: MatchPersonCard(match: match, myUid: myUid),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ProfileNavigatorControls(
                  currentIndex: _currentIndex,
                  totalCount: matches.length,
                  onPrevious: _currentIndex > 0 ? _goPrevious : null,
                  onNext: _currentIndex < matches.length - 1 ? () => _goNext(matches.length) : null,
                  onRefresh: () => ref.invalidate(matchesListProvider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
