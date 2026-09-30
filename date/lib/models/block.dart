import 'package:cloud_firestore/cloud_firestore.dart';

class Block {
  final String blockedUid;
  final DateTime? createdAt;

  const Block({required this.blockedUid, this.createdAt});

  factory Block.fromMap(Map<String, dynamic> map) {
    return Block(
      blockedUid: map['blockedUid'] as String,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blockedUid': blockedUid,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
