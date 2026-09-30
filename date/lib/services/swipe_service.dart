import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/app_user.dart';
import '../models/gender.dart';
import '../models/match.dart';
import '../models/swipe.dart';
import '../utils/age_calculator.dart';

class SwipeService {
  SwipeService(this._firestore);

  static const _nearbyPriorityRadiusKm = 40.0;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection('matches');

  /// Candidate discovery query. Filters by mutual gender preference and the
  /// viewer's age-range preference. Excludes self and already-swiped users
  /// client-side, since Firestore can't combine those exclusions cleanly
  /// with the range/array-contains filters above. NOTE: for large user
  /// bases, the client-side `whereNotIn` 10-item limit and the
  /// already-swiped-uid filtering below become a scaling bottleneck; a
  /// production version should push this to a Cloud Function or a search
  /// index (e.g. Algolia) instead.
  Future<List<AppUser>> fetchCandidates(AppUser me) async {
    final preferredGenders = me.interestedIn.isEmpty
        ? Gender.values.toSet()
        : me.interestedIn;

    final (earliest, latest) = AgeCalculator.ageRangeToBirthdateRange(
      me.ageRangeMin,
      me.ageRangeMax,
    );

    final alreadySwiped = await _swipedUids(me.uid);
    final blocked = await _blockedUids(me.uid);
    final strictExcluded = {...alreadySwiped, ...blocked};
    final meDoc = await _users.doc(me.uid).get();
    final meGeoPoint = _extractGeoPoint(meDoc.data());

    // Strict query keeps the intended matching logic when full preference data
    // exists. If it yields no results, fall back to a broader onboarding query.
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = const [];
    if (me.gender != null) {
      final strictSnapshot = await _users
          .where('interestedIn', arrayContains: me.gender!.value)
          .where(
            'birthdate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(earliest),
          )
          .where('birthdate', isLessThanOrEqualTo: Timestamp.fromDate(latest))
          .where('onboardingComplete', isEqualTo: true)
          .limit(50)
          .get();
      docs = strictSnapshot.docs;
    }

    var candidates = _mapAndFilterCandidates(
      docs: docs,
      me: me,
      meGeoPoint: meGeoPoint,
      excluded: strictExcluded,
      preferredGenders: preferredGenders,
      requireMutualInterest: true,
      enforceAgeRange: true,
    );

    if (candidates.isEmpty) {
      final fallbackSnapshot = await _users
          .where('onboardingComplete', isEqualTo: true)
          .limit(80)
          .get();
      candidates = _mapAndFilterCandidates(
        docs: fallbackSnapshot.docs,
        me: me,
        meGeoPoint: meGeoPoint,
        excluded: strictExcluded,
        preferredGenders: preferredGenders,
        requireMutualInterest: me.gender != null,
        enforceAgeRange: true,
      );

      // If no unseen profiles remain, allow resurfacing previously swiped
      // profiles on manual refresh while still respecting block lists.
      if (candidates.isEmpty) {
        candidates = _mapAndFilterCandidates(
          docs: fallbackSnapshot.docs,
          me: me,
          meGeoPoint: meGeoPoint,
          excluded: blocked,
          preferredGenders: preferredGenders,
          requireMutualInterest: me.gender != null,
          enforceAgeRange: true,
        );
      }
    }

    // Prioritize nearby people first (<=40km), then shared interests,
    // then shorter distance when both users have geolocation coordinates.
    final myInterests = me.interests.toSet();
    candidates.sort((a, b) {
      final aNearby =
          a.distanceKm != null && a.distanceKm! <= _nearbyPriorityRadiusKm;
      final bNearby =
          b.distanceKm != null && b.distanceKm! <= _nearbyPriorityRadiusKm;
      if (aNearby != bNearby) {
        return bNearby ? 1 : -1;
      }

      final sharedA = a.user.interests.where(myInterests.contains).length;
      final sharedB = b.user.interests.where(myInterests.contains).length;
      if (sharedA != sharedB) {
        return sharedB.compareTo(sharedA);
      }

      final aDistance = a.distanceKm;
      final bDistance = b.distanceKm;
      if (aDistance != null && bDistance != null) {
        return aDistance.compareTo(bDistance);
      }
      if (aDistance != null) return -1;
      if (bDistance != null) return 1;

      final byLikeCount = b.user.likeCount.compareTo(a.user.likeCount);
      if (byLikeCount != 0) return byLikeCount;
      return a.user.uid.compareTo(b.user.uid);
    });

    return candidates.map((entry) => entry.user).toList();
  }

  List<_RankedCandidate> _mapAndFilterCandidates({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required AppUser me,
    required GeoPoint? meGeoPoint,
    required Set<String> excluded,
    required Set<Gender> preferredGenders,
    required bool requireMutualInterest,
    required bool enforceAgeRange,
  }) {
    return docs
        .map((doc) {
          final user = AppUser.fromDoc(doc);
          final distanceKm = _distanceKmBetween(
            meGeoPoint,
            _extractGeoPoint(doc.data()),
          );
          return _RankedCandidate(user: user, distanceKm: distanceKm);
        })
        .where((entry) {
          final user = entry.user;
          if (user.uid == me.uid || excluded.contains(user.uid)) return false;

          if (user.gender == null || !preferredGenders.contains(user.gender!)) {
            return false;
          }

          if (requireMutualInterest && me.gender != null) {
            if (user.interestedIn.isNotEmpty &&
                !user.interestedIn.contains(me.gender!)) {
              return false;
            }
          }

          if (enforceAgeRange && user.birthdate != null) {
            final age = AgeCalculator.ageFromBirthdate(user.birthdate!);
            if (age < me.ageRangeMin || age > me.ageRangeMax) {
              return false;
            }
          }

          return true;
        })
        .toList();
  }

  GeoPoint? _extractGeoPoint(Map<String, dynamic>? data) {
    if (data == null) return null;

    final directGeoPoint =
        data['location'] ?? data['geoPoint'] ?? data['coordinates'];
    if (directGeoPoint is GeoPoint) return directGeoPoint;

    if (directGeoPoint is Map<String, dynamic>) {
      final lat = _asDouble(
        directGeoPoint['lat'] ?? directGeoPoint['latitude'],
      );
      final lng = _asDouble(
        directGeoPoint['lng'] ?? directGeoPoint['longitude'],
      );
      if (lat != null && lng != null) return GeoPoint(lat, lng);
    }

    final topLevelLat = _asDouble(data['lat'] ?? data['latitude']);
    final topLevelLng = _asDouble(data['lng'] ?? data['longitude']);
    if (topLevelLat != null && topLevelLng != null) {
      return GeoPoint(topLevelLat, topLevelLng);
    }

    return null;
  }

  double? _distanceKmBetween(GeoPoint? from, GeoPoint? to) {
    if (from == null || to == null) return null;
    final distanceMeters = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    return distanceMeters / 1000;
  }

  double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return null;
  }

  Future<Set<String>> _swipedUids(String uid) async {
    final snapshot = await _users.doc(uid).collection('swipes').get();
    return snapshot.docs.map((d) => d.id).toSet();
  }

  Future<Set<String>> _blockedUids(String uid) async {
    final iBlocked = await _users.doc(uid).collection('blocks').get();
    final blockedMe = await _firestore
        .collectionGroup('blocks')
        .where('blockedUid', isEqualTo: uid)
        .get();

    return {
      ...iBlocked.docs.map((d) => d.id),
      ...blockedMe.docs.map((d) => d.reference.parent.parent!.id),
    };
  }

  /// Uids to hide from discovery/admirers: already-swiped, blocked by [uid],
  /// or blocking [uid]. See `SafetyService` for the `blocks` subcollection
  /// this reads from.
  Future<Set<String>> _excludedUids(String uid) async {
    final alreadySwiped = await _swipedUids(uid);
    final blocked = await _blockedUids(uid);

    return {
      ...alreadySwiped,
      ...blocked,
    };
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

    final excluded = await _excludedUids(myUid);
    final admirerUids = snapshot.docs
        .map((doc) => doc.reference.parent.parent!.id)
        .where((uid) => uid != myUid && !excluded.contains(uid))
        .toSet();
    if (admirerUids.isEmpty) return [];

    final docs = await Future.wait(
      admirerUids.map((uid) => _users.doc(uid).get()),
    );
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
        transaction.update(_users.doc(targetUid), {
          'likeCount': FieldValue.increment(1),
        });
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

class _RankedCandidate {
  const _RankedCandidate({required this.user, required this.distanceKm});

  final AppUser user;
  final double? distanceKm;
}
