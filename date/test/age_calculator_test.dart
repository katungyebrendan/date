import 'package:flutter_test/flutter_test.dart';
import 'package:kokonyo/utils/age_calculator.dart';

void main() {
  group('AgeCalculator.ageFromBirthdate', () {
    test('calculates age before this year\'s birthday', () {
      final now = DateTime(2026, 3, 1);
      final birthdate = DateTime(2000, 6, 15);
      expect(AgeCalculator.ageFromBirthdate(birthdate, now: now), 25);
    });

    test('calculates age on or after this year\'s birthday', () {
      final now = DateTime(2026, 8, 1);
      final birthdate = DateTime(2000, 6, 15);
      expect(AgeCalculator.ageFromBirthdate(birthdate, now: now), 26);
    });

    test('calculates age exactly on birthday', () {
      final now = DateTime(2026, 6, 15);
      final birthdate = DateTime(2000, 6, 15);
      expect(AgeCalculator.ageFromBirthdate(birthdate, now: now), 26);
    });
  });

  group('AgeCalculator.isAtLeastMinimumAge', () {
    test('rejects someone younger than 18', () {
      final now = DateTime(2026, 1, 1);
      final birthdate = DateTime(2010, 1, 2);
      expect(AgeCalculator.isAtLeastMinimumAge(birthdate, now: now), isFalse);
    });

    test('accepts someone exactly 18', () {
      final now = DateTime(2026, 1, 2);
      final birthdate = DateTime(2008, 1, 2);
      expect(AgeCalculator.isAtLeastMinimumAge(birthdate, now: now), isTrue);
    });
  });

  group('AgeCalculator.ageRangeToBirthdateRange', () {
    test('produces bounds that match ageFromBirthdate at the edges', () {
      final now = DateTime(2026, 7, 4);
      final (earliest, latest) = AgeCalculator.ageRangeToBirthdateRange(25, 35, now: now);

      expect(AgeCalculator.ageFromBirthdate(latest, now: now), 25);
      expect(AgeCalculator.ageFromBirthdate(earliest, now: now), 35);
    });
  });
}
