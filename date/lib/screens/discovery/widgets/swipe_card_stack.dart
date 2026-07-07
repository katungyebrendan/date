import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter/material.dart';
import '../../../models/app_user.dart';
import '../../../widgets/person_card.dart';

class SwipeCardStack extends StatelessWidget {
  const SwipeCardStack({
    super.key,
    required this.candidates,
    required this.currentUid,
    required this.controller,
    required this.onSwipe,
    required this.onEnd,
  });

  final List<AppUser> candidates;
  final String currentUid;
  final CardSwiperController controller;
  final CardSwiperOnSwipe onSwipe;
  final CardSwiperOnEnd onEnd;

  @override
  Widget build(BuildContext context) {
    return CardSwiper(
      controller: controller,
      cardsCount: candidates.length,
      numberOfCardsDisplayed: candidates.length > 1 ? 2 : 1,
      isLoop: false,
      allowedSwipeDirection: const AllowedSwipeDirection.only(up: true, left: true, right: true),
      onSwipe: onSwipe,
      onEnd: onEnd,
      cardBuilder: (context, index, horizontalOffset, verticalOffset) {
        // CardSwiper gives each card the full stack area; PersonCard is
        // content-sized like a list tile, so center it (with room to
        // scroll on short screens) rather than let it stretch/top-align.
        return Center(
          child: SingleChildScrollView(
            child: PersonCard(
              person: candidates[index],
              currentUid: currentUid,
              onLike: () => controller.swipe(CardSwiperDirection.right),
            ),
          ),
        );
      },
    );
  }
}
