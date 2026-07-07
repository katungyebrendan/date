import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/user_repository.dart';
import 'auth_providers.dart';
import 'storage_providers.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(firestoreProvider), ref.watch(storageServiceProvider));
});

/// Streams the signed-in user's Firestore profile document, or null when
/// signed out or the doc doesn't exist yet (e.g. between sign-up and the
/// initial doc write).
final currentAppUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final firebaseUser = authState.valueOrNull;
  if (firebaseUser == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(firebaseUser.uid);
});

/// Looks up another user's profile by uid, e.g. to render a match/chat
/// participant's name and photo.
final userByIdProvider = FutureProvider.autoDispose.family<AppUser?, String>((ref, uid) {
  return ref.watch(userRepositoryProvider).getUser(uid);
});
