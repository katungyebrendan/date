import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/block.dart';
import '../models/report.dart';
import '../models/report_reason.dart';

class SafetyService {
  SafetyService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _reports => _firestore.collection('reports');

  CollectionReference<Map<String, dynamic>> _blocks(String uid) {
    return _users.doc(uid).collection('blocks');
  }

  /// Uids that [uid] has blocked. Doc id is the blocked user's uid, matching
  /// the `swipes` subcollection convention.
  Stream<Set<String>> watchBlockedUids(String uid) {
    return _blocks(uid).snapshots().map((snapshot) => snapshot.docs.map((d) => d.id).toSet());
  }

  Future<void> blockUser({required String uid, required String blockedUid}) {
    return _blocks(uid).doc(blockedUid).set(Block(blockedUid: blockedUid).toMap());
  }

  Future<void> unblockUser({required String uid, required String blockedUid}) {
    return _blocks(uid).doc(blockedUid).delete();
  }

  /// Uids that have blocked [uid], found via a collection-group query across
  /// every user's `blocks` subcollection (each block duplicates `blockedUid`
  /// into its map data for exactly this query, mirroring how `swipes`
  /// duplicates `targetUid`).
  Future<Set<String>> fetchBlockedByUids(String uid) async {
    final snapshot =
        await _firestore.collectionGroup('blocks').where('blockedUid', isEqualTo: uid).get();
    return snapshot.docs.map((doc) => doc.reference.parent.parent!.id).toSet();
  }

  /// Full profiles of the users [uid] has blocked, for the "Blocked users"
  /// settings screen.
  Future<List<AppUser>> fetchBlockedUsers(String uid) async {
    final snapshot = await _blocks(uid).get();
    final blockedUids = snapshot.docs.map((d) => d.id).toList();
    if (blockedUids.isEmpty) return [];

    final docs = await Future.wait(blockedUids.map((uid) => _users.doc(uid).get()));
    return docs.where((doc) => doc.exists).map(AppUser.fromDoc).toList();
  }

  Future<void> reportUser({
    required String reporterUid,
    required String reportedUid,
    required ReportReason reason,
    String details = '',
  }) {
    return _reports.add(
      Report(reporterUid: reporterUid, reportedUid: reportedUid, reason: reason, details: details)
          .toMap(),
    );
  }
}
