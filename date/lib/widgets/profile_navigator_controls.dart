import 'package:flutter/material.dart';

class ProfileNavigatorControls extends StatelessWidget {
  const ProfileNavigatorControls({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    required this.onPrevious,
    required this.onNext,
    this.onRefresh,
  });

  final int currentIndex;
  final int totalCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${currentIndex + 1}/$totalCount',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundControlButton(
              onPressed: onPrevious,
              icon: Icons.arrow_back,
              tooltip: 'Previous profile',
            ),
            const SizedBox(width: 20),
            _RoundControlButton(
              onPressed: onRefresh,
              icon: Icons.refresh,
              tooltip: 'Refresh profiles',
            ),
            const SizedBox(width: 20),
            _RoundControlButton(
              onPressed: onNext,
              icon: Icons.arrow_forward,
              tooltip: 'Next profile',
              highlight: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundControlButton extends StatelessWidget {
  const _RoundControlButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.highlight = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: enabled ? 3 : 0,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 66,
            height: 66,
            child: Icon(
              icon,
              color: !enabled
                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                  : (highlight ? colorScheme.primary : colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}