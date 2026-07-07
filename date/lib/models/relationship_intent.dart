enum RelationshipIntent { dating, friendship, casual, longTerm, marriage }

extension RelationshipIntentCodec on RelationshipIntent {
  String get value => name;

  String get label {
    switch (this) {
      case RelationshipIntent.dating:
        return 'Dating';
      case RelationshipIntent.friendship:
        return 'Friendship';
      case RelationshipIntent.casual:
        return 'Sponsorship';
      case RelationshipIntent.longTerm:
        return 'Long-term Relationship';
      case RelationshipIntent.marriage:
        return 'Marriage';
    }
  }

  static RelationshipIntent fromValue(String value) {
    return RelationshipIntent.values.firstWhere(
      (i) => i.value == value,
      orElse: () => RelationshipIntent.dating,
    );
  }
}
