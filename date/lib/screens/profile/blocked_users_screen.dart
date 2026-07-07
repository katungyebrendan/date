import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../providers/safety_providers.dart';
import '../../providers/user_providers.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  Future<void> _unblock(BuildContext context, WidgetRef ref, AppUser user) async {
    final myUid = ref.read(currentAppUserProvider).valueOrNull?.uid;
    if (myUid == null) return;

    await ref.read(safetyServiceProvider).unblockUser(uid: myUid, blockedUid: user.uid);
    ref.invalidate(blockedUsersProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unblocked ${user.displayName}.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: blockedAsync.when(
        loading: () => const LoadingView(),
        error: (error, stack) => ErrorView(
          message: 'Could not load blocked users.\n$error',
          onRetry: () => ref.invalidate(blockedUsersProvider),
        ),
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      "You haven't blocked anyone.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: AppAvatar(photoUrl: user.photoUrls.isNotEmpty ? user.photoUrls.first : null),
                title: Text(user.displayName.isNotEmpty ? user.displayName : 'Unknown user'),
                trailing: OutlinedButton(
                  onPressed: () => _unblock(context, ref, user),
                  child: const Text('Unblock'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
