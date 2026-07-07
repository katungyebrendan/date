import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String id;
  final List<String> participants;
  final DateTime? createdAt;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;

  const MatchModel({
    required this.id,
    required this.participants,
    this.createdAt,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageAt,
  });

  factory MatchModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const {};
    return MatchModel(
      id: doc.id,
      participants: List<String>.from((map['participants'] as List?) ?? const []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      lastMessage: map['lastMessage'] as String?,
      lastMessageSenderId: map['lastMessageSenderId'] as String?,
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }

  String otherParticipant(String myUid) {
    return participants.firstWhere((uid) => uid != myUid, orElse: () => '');
  }

  /// Deterministic match id: sorted uid pair joined by underscore.
  static String idFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
