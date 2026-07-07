import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class SwipeActionButtons extends StatelessWidget {
  const SwipeActionButtons({super.key, required this.controller});

  final CardSwiperController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.close,
          color: colorScheme.error,
          size: 56,
          onPressed: () => controller.swipe(CardSwiperDirection.left),
        ),
        _ActionButton(
          icon: Icons.star,
          color: Colors.amber.shade700,
          size: 44,
          onPressed: () => controller.swipe(CardSwiperDirection.top),
        ),
        _ActionButton(
          icon: Icons.favorite,
          color: colorScheme.primary,
          size: 56,
          onPressed: () => controller.swipe(CardSwiperDirection.right),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: color, size: size * 0.45),
        ),
      ),
    );
  }
}
