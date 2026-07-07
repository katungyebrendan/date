import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/gender.dart';
import '../models/match.dart';
import '../models/swipe.dart';
import '../utils/age_calculator.dart';

class SwipeService {
  SwipeService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _matches => _firestore.collection('matches');

  /// Candidate discovery query. Filters by mutual gender preference and the
  /// viewer's age-range preference. Excludes self and already-swiped users
  /// client-side, since Firestore can't combine those exclusions cleanly
  /// with the range/array-contains filters above. NOTE: for large user
  /// bases, the client-side `whereNotIn` 10-item limit and the
  /// already-swiped-uid filtering below become a scaling bottleneck; a
  /// production version should push this to a Cloud Function or a search
  /// index (e.g. Algolia) instead.
  Future<List<AppUser>> fetchCandidates(AppUser me) async {
    if (me.gender == null || me.interestedIn.isEmpty) return [];

    final (earliest, latest) = AgeCalculator.ageRangeToBirthdateRange(
      me.ageRangeMin,
      me.ageRangeMax,
    );

    Query<Map<String, dynamic>> query = _users
        .where('interestedIn', arrayContains: me.gender!.value)
        .where('gender', whereIn: me.interestedIn.map((g) => g.value).toList())
        .where('birthdate', isGreaterThanOrEqualTo: Timestamp.fromDate(earliest))
        .where('birthdate', isLessThanOrEqualTo: Timestamp.fromDate(latest))
        .where('onboardingComplete', isEqualTo: true)
        .limit(50);

    final snapshot = await query.get();
    final alreadySwiped = await _swipedUids(me.uid);

    final candidates = snapshot.docs
        .map(AppUser.fromDoc)
        .where((u) => u.uid != me.uid && !alreadySwiped.contains(u.uid))
        .toList();

    // Surface people who share more of the viewer's interests first, to
    // help find better matches; Firestore can't rank by array overlap
    // itself since `interestedIn` already uses the query's one allowed
    // array-contains filter.
    final myInterests = me.interests.toSet();
    candidates.sort((a, b) {
      final sharedA = a.interests.where(myInterests.contains).length;
      final sharedB = b.interests.where(myInterests.contains).length;
      return sharedB.compareTo(sharedA);
    });

    return candidates;
  }

  Future<Set<String>> _swipedUids(String uid) async {
    final snapshot = await _users.doc(uid).collection('swipes').get();
    return snapshot.docs.map((d) => d.id).toSet();
  }

  /// Users who liked [myUid] but haven't been swiped on back yet (the
  /// "Likes" tab). Uses a collection-group query across every user's
  /// `swipes` subcollection: each admirer's like is stored as
  /// `users/{admirerUid}/swipes/{myUid}`, so the parent doc's uid is the
  /// admirer.
  Future<List<AppUser>> fetchAdmirers(String myUid) async {
    final snapshot = await _firestore
        .collectionGroup('swipes')
        .where('targetUid', isEqualTo: myUid)
        .where('liked', isEqualTo: true)
        .get();

    final alreadySwiped = await _swipedUids(myUid);
    final admirerUids = snapshot.docs
        .map((doc) => doc.reference.parent.parent!.id)
        .where((uid) => uid != myUid && !alreadySwiped.contains(uid))
        .toSet();
    if (admirerUids.isEmpty) return [];

    final docs = await Future.wait(admirerUids.map((uid) => _users.doc(uid).get()));
    return docs.where((doc) => doc.exists).map(AppUser.fromDoc).toList();
  }

  Future<SwipeResult> recordSwipe({
    required String meUid,
    required String targetUid,
    required bool liked,
    bool superLike = false,
  }) async {
    final mySwipeRef = _users.doc(meUid).collection('swipes').doc(targetUid);
    final theirSwipeRef = _users.doc(targetUid).collection('swipes').doc(meUid);
    final matchId = MatchModel.idFor(meUid, targetUid);
    final matchRef = _matches.doc(matchId);

    return _firestore.runTransaction<SwipeResult>((transaction) async {
      final theirSwipeDoc = liked ? await transaction.get(theirSwipeRef) : null;

      transaction.set(
        mySwipeRef,
        Swipe(targetUid: targetUid, liked: liked, superLike: superLike).toMap(),
      );

      if (liked) {
        transaction.update(_users.doc(targetUid), {'likeCount': FieldValue.increment(1)});
      }

      final mutualLike = liked && theirSwipeDoc != null && theirSwipeDoc.exists
          ? (Swipe.fromMap(theirSwipeDoc.data()!).liked)
          : false;

      if (mutualLike) {
        transaction.set(matchRef, {
          'participants': [meUid, targetUid]..sort(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': null,
          'lastMessageSenderId': null,
          'lastMessageAt': null,
        });
        return SwipeResult.matched(matchId);
      }
      return SwipeResult.noMatch();
    });
  }
}
