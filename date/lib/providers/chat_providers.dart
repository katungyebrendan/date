import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import 'user_providers.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.watch(firestoreProvider));
});

final messagesProvider = StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, matchId) {
  return ref.watch(chatServiceProvider).watchMessages(matchId);
});
