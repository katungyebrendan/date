import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match.dart';
import '../services/match_service.dart';
import 'user_providers.dart';

final matchServiceProvider = Provider<MatchService>((ref) {
  return MatchService(ref.watch(firestoreProvider));
});

final matchesListProvider = StreamProvider.autoDispose<List<MatchModel>>((ref) {
  final authUser = ref.watch(currentAppUserProvider).valueOrNull;
  if (authUser == null) return Stream.value(<MatchModel>[]);
  return ref.watch(matchServiceProvider).watchMyMatches(authUser.uid);
});

final matchByIdProvider = StreamProvider.autoDispose.family<MatchModel?, String>((ref, matchId) {
  return ref.watch(matchServiceProvider).watchMatch(matchId);
});
