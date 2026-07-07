import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_providers.dart';
import '../../providers/match_providers.dart';
import '../../providers/user_providers.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/safety_menu_button.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_composer.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(currentAppUserProvider).valueOrNull?.uid;
    final matchAsync = ref.watch(matchByIdProvider(widget.matchId));
    final messagesAsync = ref.watch(messagesProvider(widget.matchId));

    final otherUid = matchAsync.valueOrNull?.otherParticipant(myUid ?? '');
    final otherUserAsync = otherUid != null ? ref.watch(userByIdProvider(otherUid)) : null;
    final otherUser = otherUserAsync?.valueOrNull;

    if (myUid != null && otherUid != null) {
      messagesAsync.whenData((messages) {
        final chatService = ref.read(chatServiceProvider);
        for (final message in messages) {
          if (message.senderId != myUid && !message.readBy.contains(myUid)) {
            chatService.markRead(widget.matchId, message.id, myUid);
          }
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AppAvatar(photoUrl: otherUser?.photoUrls.isNotEmpty == true ? otherUser!.photoUrls.first : null, radius: 18),
            const SizedBox(width: 12),
            Text(otherUser?.displayName.isNotEmpty == true ? otherUser!.displayName : 'Chat'),
          ],
        ),
        actions: [
          if (myUid != null && otherUid != null)
            SafetyMenuButton(
              myUid: myUid,
              targetUid: otherUid,
              targetName: otherUser?.displayName.isNotEmpty == true ? otherUser!.displayName : 'this user',
              onBlocked: () => Navigator.of(context).pop(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const LoadingView(),
              error: (error, stack) => ErrorView(message: 'Could not load messages.\n$error'),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hello!',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final isMine = message.senderId == myUid;
                    final isRead = otherUid != null && message.readBy.contains(otherUid);
                    return MessageBubble(message: message, isMine: isMine, isRead: isRead);
                  },
                );
              },
            ),
          ),
          MessageComposer(
            onSend: (text) async {
              if (myUid == null) return;
              await ref.read(chatServiceProvider).sendMessage(
                    matchId: widget.matchId,
                    senderId: myUid,
                    text: text,
                  );
            },
          ),
        ],
      ),
    );
  }
}
