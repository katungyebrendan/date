import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../models/gender.dart';
import '../models/match.dart';
import '../services/match_service.dart';
import '../utils/age_calculator.dart';
import 'safety_providers.dart';
import 'user_providers.dart';

final matchServiceProvider = Provider<MatchService>((ref) {
  return MatchService(ref.watch(firestoreProvider));
});

/// Hides matches with users the current user has blocked. Doesn't hide
/// matches where the *other* participant blocked you — that side just can't
/// message you anymore (enforced in `firestore.rules`), so the thread stays
/// visible with your own message history intact.
final matchesListProvider = StreamProvider.autoDispose<List<MatchModel>>((ref) {
  final me = ref.watch(currentAppUserProvider).valueOrNull;
  if (me == null || me.gender == null) return Stream.value(<MatchModel>[]);

  final oppositeGender = me.gender == Gender.male ? Gender.female : Gender.male;
  final blockedUids = ref.watch(blockedUidsProvider).valueOrNull ?? const <String>{};
  final userRepository = ref.watch(userRepositoryProvider);

  return ref.watch(matchServiceProvider).watchMyMatches(me.uid).asyncMap((matches) async {
    final visible = matches
        .where((m) => !blockedUids.contains(m.otherParticipant(me.uid)))
        .toList();

    final ranked = (await Future.wait(
      visible.map((match) async {
        final otherUid = match.otherParticipant(me.uid);
        if (otherUid.isEmpty) return null;

        final other = await userRepository.getUser(otherUid);
        if (other == null || other.gender != oppositeGender) return null;

        return _RankedMatch(
          match: match,
          intentScore: _intentScore(me, other),
          sharedHobbies: _sharedHobbiesCount(me, other),
          ageScore: _ageScore(me, other),
        );
      }),
    ))
        .whereType<_RankedMatch>()
        .toList();

    ranked.sort((a, b) {
      if (a.intentScore != b.intentScore) {
        return b.intentScore.compareTo(a.intentScore);
      }
      if (a.sharedHobbies != b.sharedHobbies) {
        return b.sharedHobbies.compareTo(a.sharedHobbies);
      }
      if (a.ageScore != b.ageScore) {
        return b.ageScore.compareTo(a.ageScore);
      }

      final aLast = a.match.lastMessageAt ?? a.match.createdAt;
      final bLast = b.match.lastMessageAt ?? b.match.createdAt;
      if (aLast != null && bLast != null) {
        return bLast.compareTo(aLast);
      }
      if (aLast != null) return -1;
      if (bLast != null) return 1;
      return a.match.id.compareTo(b.match.id);
    });

    return ranked.map((entry) => entry.match).toList();
  });
});

final matchByIdProvider = StreamProvider.autoDispose.family<MatchModel?, String>((ref, matchId) {
  return ref.watch(matchServiceProvider).watchMatch(matchId);
});

int _intentScore(AppUser me, AppUser other) {
  if (me.intent == null || other.intent == null) return 0;
  return me.intent == other.intent ? 1 : 0;
}

int _sharedHobbiesCount(AppUser me, AppUser other) {
  final mine = me.interests.toSet();
  return other.interests.where(mine.contains).length;
}

int _ageScore(AppUser me, AppUser other) {
  if (other.birthdate == null) return 0;

  final age = AgeCalculator.ageFromBirthdate(other.birthdate!);
  final inRange = age >= me.ageRangeMin && age <= me.ageRangeMax;
  if (inRange) {
    final midpoint = (me.ageRangeMin + me.ageRangeMax) / 2;
    final distanceToMidpoint = (age - midpoint).abs();
    return 100 - distanceToMidpoint.round();
  }

  final distanceToNearestBound = age < me.ageRangeMin
      ? me.ageRangeMin - age
      : age - me.ageRangeMax;
  return -distanceToNearestBound;
}

class _RankedMatch {
  const _RankedMatch({
    required this.match,
    required this.intentScore,
    required this.sharedHobbies,
    required this.ageScore,
  });

  final MatchModel match;
  final int intentScore;
  final int sharedHobbies;
  final int ageScore;
}
