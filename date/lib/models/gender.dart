enum Gender { male, female }

extension GenderCodec on Gender {
  String get value => name;

  String get label {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
    }
  }

  static Gender fromValue(String value) {
    switch (value) {
      case 'male':
      case 'man':
        return Gender.male;
      case 'female':
      case 'woman':
        return Gender.female;
      default:
        return Gender.female;
    }
  }
}
