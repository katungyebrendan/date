import 'package:flutter/material.dart';
import '../../../models/app_user.dart';
import '../../../widgets/app_avatar.dart';

class MatchCelebrationDialog extends StatelessWidget {
  const MatchCelebrationDialog({super.key, required this.me, required this.match});

  final AppUser me;
  final AppUser match;

  static Future<void> show(BuildContext context, {required AppUser me, required AppUser match}) {
    return showDialog(
      context: context,
      builder: (context) => MatchCelebrationDialog(me: me, match: match),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, color: Theme.of(context).colorScheme.primary, size: 48),
            const SizedBox(height: 12),
            Text("It's a Match!", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'You and ${match.displayName} liked each other',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppAvatar(photoUrl: me.photoUrls.isNotEmpty ? me.photoUrls.first : null, radius: 36),
                const SizedBox(width: 12),
                AppAvatar(photoUrl: match.photoUrls.isNotEmpty ? match.photoUrls.first : null, radius: 36),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Swiping'),
            ),
          ],
        ),
      ),
    );
  }
}
