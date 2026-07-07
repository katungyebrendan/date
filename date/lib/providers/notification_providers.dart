import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_notification_service.dart';
import 'auth_providers.dart';
import 'user_providers.dart';

/// Keeps a live listener on incoming likes and pushes a local notification
/// when a new like is received while the app is running.
final likesNotificationListenerProvider = Provider<void>((ref) {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? likesSub;
  String? activeUid;
  final seenLikeKeys = <String>{};
  var hydrated = false;

  Future<void> startListening(User user) async {
    if (activeUid == user.uid && likesSub != null) return;

    await likesSub?.cancel();
    activeUid = user.uid;
    hydrated = false;
    seenLikeKeys.clear();

    await LocalNotificationService.instance.ensureInitialized();

    likesSub = ref
        .read(firestoreProvider)
        .collectionGroup('swipes')
        .where('targetUid', isEqualTo: user.uid)
        .where('liked', isEqualTo: true)
        .snapshots()
        .listen((snapshot) async {
      if (!hydrated) {
        for (final doc in snapshot.docs) {
          final admirerUid = doc.reference.parent.parent?.id;
          if (admirerUid != null) {
            seenLikeKeys.add('$admirerUid:${doc.id}');
          }
        }
        hydrated = true;
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;

        final admirerUid = change.doc.reference.parent.parent?.id;
        if (admirerUid == null) continue;

        final likeKey = '$admirerUid:${change.doc.id}';
        if (!seenLikeKeys.add(likeKey)) continue;

        final admirer = await ref.read(userRepositoryProvider).getUser(admirerUid);
        final body = admirer?.displayName.isNotEmpty == true
            ? '${admirer!.displayName} liked you.'
            : 'Someone liked you.';
        await LocalNotificationService.instance.showLikeNotification(body: body);
      }
    });
  }

  ref.listen<AsyncValue<User?>>(authStateChangesProvider, (_, next) {
    next.whenData((user) async {
      if (user == null) {
        await likesSub?.cancel();
        likesSub = null;
        activeUid = null;
        hydrated = false;
        seenLikeKeys.clear();
      } else {
        await startListening(user);
      }
    });
  }, fireImmediately: true);

  ref.onDispose(() {
    likesSub?.cancel();
  });
});