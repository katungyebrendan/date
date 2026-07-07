import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/safety_service.dart';
import 'user_providers.dart';

final safetyServiceProvider = Provider<SafetyService>((ref) {
  return SafetyService(ref.watch(firestoreProvider));
});

/// Uids the current user has blocked. Drives discovery/matches filtering and
/// the "Blocked users" settings screen's live state.
final blockedUidsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final uid = ref.watch(currentAppUserProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(<String>{});
  return ref.watch(safetyServiceProvider).watchBlockedUids(uid);
});

/// Full profiles of users the current user has blocked, for the "Blocked
/// users" settings screen.
final blockedUsersProvider = FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final uid = ref.watch(currentAppUserProvider).valueOrNull?.uid;
  if (uid == null) return [];
  return ref.watch(safetyServiceProvider).fetchBlockedUsers(uid);
});
