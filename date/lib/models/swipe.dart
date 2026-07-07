import 'package:cloud_firestore/cloud_firestore.dart';

class Swipe {
  final String targetUid;
  final bool liked;
  final bool superLike;
  final DateTime? createdAt;

  const Swipe({
    required this.targetUid,
    required this.liked,
    this.superLike = false,
    this.createdAt,
  });

  factory Swipe.fromMap(Map<String, dynamic> map) {
    return Swipe(
      targetUid: map['targetUid'] as String,
      liked: map['liked'] as bool? ?? false,
      superLike: map['superLike'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetUid': targetUid,
      'liked': liked,
      'superLike': superLike,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

enum SwipeOutcome { matched, noMatch }

class SwipeResult {
  final SwipeOutcome outcome;
  final String? matchId;

  const SwipeResult._(this.outcome, this.matchId);

  factory SwipeResult.matched(String matchId) => SwipeResult._(SwipeOutcome.matched, matchId);
  factory SwipeResult.noMatch() => const SwipeResult._(SwipeOutcome.noMatch, null);

  bool get isMatch => outcome == SwipeOutcome.matched;
}
