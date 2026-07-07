import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';

class MatchService {
  MatchService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _matches => _firestore.collection('matches');

  Stream<List<MatchModel>> watchMyMatches(String uid) {
    return _matches
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(MatchModel.fromDoc).toList());
  }

  Stream<MatchModel?> watchMatch(String matchId) {
    return _matches.doc(matchId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return MatchModel.fromDoc(doc);
    });
  }
}
