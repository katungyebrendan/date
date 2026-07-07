import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatService {
  ChatService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _messages(String matchId) {
    return _firestore.collection('matches').doc(matchId).collection('messages');
  }

  Stream<List<ChatMessage>> watchMessages(String matchId) {
    return _messages(matchId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ChatMessage.fromDoc).toList());
  }

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final batch = _firestore.batch();
    final messageRef = _messages(matchId).doc();
    batch.set(messageRef, {
      'senderId': senderId,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [senderId],
    });

    final matchRef = _firestore.collection('matches').doc(matchId);
    batch.update(matchRef, {
      'lastMessage': trimmed,
      'lastMessageSenderId': senderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> markRead(String matchId, String messageId, String uid) {
    return _messages(matchId).doc(messageId).update({
      'readBy': FieldValue.arrayUnion([uid]),
    });
  }
}
