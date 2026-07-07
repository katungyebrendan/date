import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match.dart';
import '../services/match_service.dart';
import 'safety_providers.dart';
import 'user_providers.dart';

final matchServiceProvider = Provider<MatchService>((ref) {
  return MatchService(ref.watch(firestoreProvider));
});

/// Hides matches with users the current user has blocked. Doesn't hide
/// matches where the *other* participant blocked you — that side just can't
/// message you anymore (enforced in `firestore.rules`), so the thread stays
/// visible with your own message history intact.
final matchesListProvider = StreamProvider.autoDispose<List<MatchModel>>((ref) {
  final authUser = ref.watch(currentAppUserProvider).valueOrNull;
  if (authUser == null) return Stream.value(<MatchModel>[]);
  final blockedUids = ref.watch(blockedUidsProvider).valueOrNull ?? const <String>{};
  return ref.watch(matchServiceProvider).watchMyMatches(authUser.uid).map(
        (matches) => matches
            .where((m) => !blockedUids.contains(m.otherParticipant(authUser.uid)))
            .toList(),
      );
});

final matchByIdProvider = StreamProvider.autoDispose.family<MatchModel?, String>((ref, matchId) {
  return ref.watch(matchServiceProvider).watchMatch(matchId);
});
