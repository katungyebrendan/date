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
/// [person]'s view counter when the full profile is opened.
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
  late int _displayLikeCount;
  late int _displayViewCount;
  bool _likeHandledForCurrentProfile = false;
  bool _viewHandledForCurrentProfile = false;

  @override
  void initState() {
    super.initState();
    _displayLikeCount = widget.person.likeCount;
    _displayViewCount = widget.person.viewCount;
  }

  @override
  void didUpdateWidget(covariant PersonCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final profileChanged = oldWidget.person.uid != widget.person.uid;
    final serverLikeCountChanged = oldWidget.person.likeCount != widget.person.likeCount;
    final serverViewCountChanged = oldWidget.person.viewCount != widget.person.viewCount;
    if (profileChanged || serverLikeCountChanged) {
      _displayLikeCount = widget.person.likeCount;
    }
    if (profileChanged || serverViewCountChanged) {
      _displayViewCount = widget.person.viewCount;
    }
    if (profileChanged) {
      _likeHandledForCurrentProfile = false;
      _viewHandledForCurrentProfile = false;
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
    context.push(RoutePaths.chatThreadPath(widget.matchId!));
  }

  Future<void> _openProfile() async {
    if (widget.person.uid != widget.currentUid && !_viewHandledForCurrentProfile) {
      setState(() {
        _viewHandledForCurrentProfile = true;
        _displayViewCount += 1;
      });
      ref.read(userRepositoryProvider).incrementViewCount(widget.person.uid).ignore();
    }

    await context.push(RoutePaths.viewProfilePath(widget.person.uid));
  }

  void _handleLikeTap() {
    final onLike = widget.onLike;
    if (onLike == null || _likeHandledForCurrentProfile) return;

    setState(() {
      _likeHandledForCurrentProfile = true;
      _displayLikeCount += 1;
    });

    onLike();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final person = widget.person;
    final photoUrl = person.photoUrls.isNotEmpty ? person.photoUrls.first : null;
    final age = person.birthdate != null ? AgeCalculator.ageFromBirthdate(person.birthdate!) : null;
    final hasPhone = person.phoneNumber.isNotEmpty;
    final displayName = person.displayName.trim().isNotEmpty
      ? person.displayName.trim()
      : (person.email.isNotEmpty ? person.email.split('@').first : 'Member');
    final displayCity = person.city.trim().isNotEmpty ? person.city.trim() : 'City not added yet';
    final displayBio = person.bio.trim().isNotEmpty
      ? person.bio.trim()
      : 'This member has not added a bio yet.';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: _openProfile,
                  child: Container(
                    width: 156,
                    height: 156,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFFFF7A45)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: photoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(Icons.person, size: 64, color: colorScheme.onSurfaceVariant),
                              ),
                            )
                          : Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(Icons.person, size: 64, color: colorScheme.onSurfaceVariant),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'BOOST',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (person.uid != widget.currentUid)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Material(
                      color: colorScheme.surface,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: SafetyMenuButton(
                        myUid: widget.currentUid,
                        targetUid: person.uid,
                        targetName: displayName,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              age != null ? '$displayName, $age' : displayName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (hasPhone)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFBFE8CF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.call, size: 16, color: Color(0xFF22A060)),
                    const SizedBox(width: 8),
                    Text(
                      'Call/WhatsApp: ${person.phoneNumber}',
                      style: const TextStyle(color: Color(0xFF22A060), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              )
            else
              Text(
                displayCity,
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatPill(
                  icon: Icons.visibility_outlined,
                  value: '$_displayViewCount',
                  color: colorScheme.onSurfaceVariant,
                  background: colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(width: 10),
                _StatPill(
                  icon: Icons.favorite_border,
                  value: '$_displayLikeCount',
                  color: colorScheme.primary,
                  background: colorScheme.primary.withValues(alpha: 0.08),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CircleIconButton(
                  icon: Icons.favorite_border,
                  color: const Color(0xFFE53935),
                  onPressed: _handleLikeTap,
                ),
                const SizedBox(width: 18),
                _CircleIconButton(
                  icon: Icons.call,
                  color: const Color(0xFF1E88E5),
                  onPressed: hasPhone ? _call : null,
                ),
                const SizedBox(width: 18),
                _CircleIconButton(
                  icon: Icons.chat,
                  color: const Color(0xFF22A060),
                  onPressed: hasPhone ? _whatsapp : null,
                ),
                if (widget.matchId != null) ...[
                  const SizedBox(width: 18),
                  _CircleIconButton(
                    icon: Icons.forum,
                    color: colorScheme.secondary,
                    onPressed: _chat,
                  ),
                ],
              ],
            ),
            if (displayBio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                displayBio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Tap to view full profile',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
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
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: enabled ? 2 : 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: enabled ? color : color.withValues(alpha: 0.3), size: 38),
        ),
      ),
    );
  }
}
