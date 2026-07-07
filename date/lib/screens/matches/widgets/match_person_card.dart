import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/match.dart';
import '../../../providers/user_providers.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/loading_view.dart';
import '../../../widgets/person_card.dart';

/// Resolves a [MatchModel]'s other participant and renders them as a
/// [PersonCard], wired so the chat button opens this match's thread
/// directly (a match already exists, so there's no like action).
class MatchPersonCard extends ConsumerWidget {
  const MatchPersonCard({super.key, required this.match, required this.myUid});

  final MatchModel match;
  final String myUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUid = match.otherParticipant(myUid);
    final otherUserAsync = ref.watch(userByIdProvider(otherUid));

    return otherUserAsync.when(
      loading: () => const LoadingView(),
      error: (error, stack) => const ErrorView(message: 'Could not load this match.'),
      data: (otherUser) {
        if (otherUser == null) return const ErrorView(message: 'This user is no longer available.');
        return PersonCard(
          person: otherUser,
          currentUid: myUid,
          matchId: match.id,
        );
      },
    );
  }
}
