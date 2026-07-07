class AgeCalculator {
  AgeCalculator._();

  static const int minimumAge = 18;

  static int ageFromBirthdate(DateTime birthdate, {DateTime? now}) {
    final today = now ?? DateTime.now();
    int age = today.year - birthdate.year;
    final hasHadBirthdayThisYear = (today.month > birthdate.month) ||
        (today.month == birthdate.month && today.day >= birthdate.day);
    if (!hasHadBirthdayThisYear) age--;
    return age;
  }

  static bool isAtLeastMinimumAge(DateTime birthdate, {DateTime? now}) {
    return ageFromBirthdate(birthdate, now: now) >= minimumAge;
  }

  /// Returns the [earliest, latest] birthdate bounds for someone whose age
  /// falls within [minAge, maxAge] as of [now]. `earliest` is the birthdate of
  /// the oldest allowed person, `latest` is the birthdate of the youngest.
  static (DateTime earliest, DateTime latest) ageRangeToBirthdateRange(
    int minAge,
    int maxAge, {
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final latest = DateTime(today.year - minAge, today.month, today.day);
    final earliest = DateTime(today.year - maxAge - 1, today.month, today.day + 1);
    return (earliest, latest);
  }
}
