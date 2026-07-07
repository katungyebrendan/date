import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_user.dart';
import '../providers/user_providers.dart';
import '../routing/route_paths.dart';
import '../utils/age_calculator.dart';
import 'safety_menu_button.dart';

/// The profile card shown on Discover, Matches and Likes: circular photo,
/// name/age, call/WhatsApp/chat actions and view/like counters. Bumps
/// [person]'s view counter once per time it's shown.
class PersonCard extends ConsumerStatefulWidget {
  const PersonCard({
    super.key,
    required this.person,
    required this.currentUid,
    this.matchId,
    this.onLike,
  });

  final AppUser person;
  final String currentUid;

  /// When set, the chat button opens this match's thread directly. When
  /// null (no match yet, e.g. on Discover/Likes), it prompts to match first.
  final String? matchId;

  /// Called when the heart button is tapped. Null hides the like action
  /// (e.g. a Matches card, where you've already liked each other).
  final VoidCallback? onLike;

  @override
  ConsumerState<PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends ConsumerState<PersonCard> {
  @override
  void initState() {
    super.initState();
    if (widget.person.uid != widget.currentUid) {
      ref.read(userRepositoryProvider).incrementViewCount(widget.person.uid).ignore();
    }
  }

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: widget.person.phoneNumber);
    await launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    final digits = widget.person.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _chat() {
    final matchId = widget.matchId;
    if (matchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Match with ${widget.person.displayName} to start chatting')),
      );
      return;
    }
    context.push(RoutePaths.chatThreadPath(matchId));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final person = widget.person;
    final photoUrl = person.photoUrls.isNotEmpty ? person.photoUrls.first : null;
    final age = person.birthdate != null ? AgeCalculator.ageFromBirthdate(person.birthdate!) : null;
    final hasPhone = person.phoneNumber.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () => context.push(RoutePaths.viewProfilePath(person.uid)),
                  child: Container(
                    width: 176,
                    height: 176,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.4)],
                      ),
                    ),
                    child: ClipOval(
                      child: photoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(Icons.person, size: 72, color: colorScheme.onSurfaceVariant),
                              ),
                            )
                          : Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(Icons.person, size: 72, color: colorScheme.onSurfaceVariant),
                            ),
                    ),
                  ),
                ),
                if (person.uid != widget.currentUid)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Material(
                      color: colorScheme.surface,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: SafetyMenuButton(
                        myUid: widget.currentUid,
                        targetUid: person.uid,
                        targetName: person.displayName,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              age != null ? '${person.displayName}, $age' : person.displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (hasPhone) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      'Call/WhatsApp: ${person.phoneNumber}',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CircleIconButton(
                  icon: Icons.favorite,
                  color: colorScheme.primary,
                  onPressed: widget.onLike,
                ),
                _CircleIconButton(
                  icon: Icons.call,
                  color: Colors.blue,
                  onPressed: hasPhone ? _call : null,
                ),
                _CircleIconButton(
                  icon: Icons.chat,
                  color: Colors.green,
                  onPressed: hasPhone ? _whatsapp : null,
                ),
                _CircleIconButton(
                  icon: Icons.forum,
                  color: colorScheme.secondary,
                  onPressed: _chat,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${person.viewCount}', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                const SizedBox(width: 16),
                Icon(Icons.favorite, size: 16, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text('${person.likeCount}', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tap photo to view full profile',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.color, required this.onPressed});

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: color.withValues(alpha: enabled ? 0.12 : 0.05),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: enabled ? color : color.withValues(alpha: 0.3), size: 22),
        ),
      ),
    );
  }
}
