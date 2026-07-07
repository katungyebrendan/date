import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/swipe_service.dart';
import 'user_providers.dart';

final swipeServiceProvider = Provider<SwipeService>((ref) {
  return SwipeService(ref.watch(firestoreProvider));
});

/// Fetches a fresh batch of discovery candidates for the current user.
/// autoDispose + no `.family` args: re-invoke via `ref.refresh` after the
/// deck is exhausted or the user's preferences change.
final candidatesProvider = FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final me = await ref.watch(currentAppUserProvider.future);
  if (me == null) return [];
  return ref.watch(swipeServiceProvider).fetchCandidates(me);
});

/// Users who liked the current user but haven't been swiped back on yet,
/// shown in the Likes tab.
final admirersProvider = FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final me = await ref.watch(currentAppUserProvider.future);
  if (me == null) return [];
  return ref.watch(swipeServiceProvider).fetchAdmirers(me.uid);
});
