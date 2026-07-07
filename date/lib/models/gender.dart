enum Gender { man, woman, nonBinary }

extension GenderCodec on Gender {
  String get value => name;

  String get label {
    switch (this) {
      case Gender.man:
        return 'Man';
      case Gender.woman:
        return 'Woman';
      case Gender.nonBinary:
        return 'Non-binary';
    }
  }

  static Gender fromValue(String value) {
    return Gender.values.firstWhere(
      (g) => g.value == value,
      orElse: () => Gender.nonBinary,
    );
  }
}
