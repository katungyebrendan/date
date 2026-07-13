import 'package:cloud_firestore/cloud_firestore.dart';
import 'gender.dart';
import 'relationship_intent.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String phoneNumber;
  final DateTime? birthdate;
  final Gender? gender;
  final Set<Gender> interestedIn;
  final String bio;
  final List<String> photoUrls;
  final String city;
  final GeoPoint? location;
  final int ageRangeMin;
  final int ageRangeMax;
  final bool onboardingComplete;
  final DateTime? createdAt;
  final DateTime? lastActive;
  final int viewCount;
  final int likeCount;
  final List<String> interests;
  final RelationshipIntent? intent;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.phoneNumber = '',
    this.birthdate,
    this.gender,
    this.interestedIn = const {},
    this.bio = '',
    this.photoUrls = const [],
    this.city = '',
    this.location,
    this.ageRangeMin = 18,
    this.ageRangeMax = 55,
    this.onboardingComplete = false,
    this.createdAt,
    this.lastActive,
    this.viewCount = 0,
    this.likeCount = 0,
    this.interests = const [],
    this.intent,
  });

  factory AppUser.newAccount({required String uid}) {
    return AppUser(uid: uid, email: '');
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final resolvedDisplayName = _firstNonEmptyString([
      map['displayName'],
      map['name'],
      map['fullName'],
      map['username'],
    ]);
    final resolvedPhoneNumber = _firstNonEmptyString([
      map['phoneNumber'],
      map['phone'],
      map['mobile'],
    ]);
    final resolvedBio = _firstNonEmptyString([
      map['bio'],
      map['about'],
      map['aboutMe'],
      map['description'],
    ]);
    final resolvedCity = _firstNonEmptyString([
      map['city'],
      map['town'],
      map['locationName'],
      map['addressCity'],
    ]);
    final resolvedPhotoUrls = _stringListFromAny([
      map['photoUrls'],
      map['photos'],
      map['images'],
      map['gallery'],
    ]);
    final resolvedInterests = _stringListFromAny([
      map['interests'],
      map['hobbies'],
      map['tags'],
    ]);

    final singlePhotoUrl = _firstNonEmptyString([
      map['photoUrl'],
      map['avatarUrl'],
      map['imageUrl'],
      map['profileImageUrl'],
    ]);
    if (singlePhotoUrl.isNotEmpty && !resolvedPhotoUrls.contains(singlePhotoUrl)) {
      resolvedPhotoUrls.insert(0, singlePhotoUrl);
    }

    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: resolvedDisplayName,
      phoneNumber: resolvedPhoneNumber,
      birthdate: (map['birthdate'] as Timestamp?)?.toDate(),
      gender: map['gender'] != null ? GenderCodec.fromValue(map['gender'] as String) : null,
      interestedIn: ((map['interestedIn'] as List?) ?? const [])
          .map((v) => GenderCodec.fromValue(v as String))
          .toSet(),
      bio: resolvedBio,
      photoUrls: resolvedPhotoUrls,
      city: resolvedCity,
      location: map['location'] as GeoPoint?,
      ageRangeMin: (map['ageRangeMin'] as num?)?.toInt() ?? 18,
      ageRangeMax: (map['ageRangeMax'] as num?)?.toInt() ?? 55,
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      lastActive: (map['lastActive'] as Timestamp?)?.toDate(),
      viewCount: (map['viewCount'] as num?)?.toInt() ?? 0,
      likeCount: (map['likeCount'] as num?)?.toInt() ?? 0,
      interests: resolvedInterests,
      intent: map['intent'] != null ? RelationshipIntentCodec.fromValue(map['intent'] as String) : null,
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AppUser.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'birthdate': birthdate != null ? Timestamp.fromDate(birthdate!) : null,
      'gender': gender?.value,
      'city': city,
      'location': location,
      'photoUrls': photoUrls,
      'interestedIn': interestedIn.map((g) => g.value).toList(),
      'onboardingComplete': onboardingComplete,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toOnboardingMap() {
    return {
      'displayName': displayName,
      'birthdate': birthdate != null ? Timestamp.fromDate(birthdate!) : null,
      'gender': gender?.value,
      'interestedIn': interestedIn.map((g) => g.value).toList(),
      'bio': bio,
      'photoUrls': photoUrls,
      'city': city,
      'location': location,
      'ageRangeMin': ageRangeMin,
      'ageRangeMax': ageRangeMax,
      'onboardingComplete': true,
      'interests': interests,
      'intent': intent?.value,
    };
  }

  AppUser copyWith({
    String? displayName,
    String? phoneNumber,
    DateTime? birthdate,
    Gender? gender,
    Set<Gender>? interestedIn,
    String? bio,
    List<String>? photoUrls,
    String? city,
    GeoPoint? location,
    int? ageRangeMin,
    int? ageRangeMax,
    bool? onboardingComplete,
    List<String>? interests,
    RelationshipIntent? intent,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthdate: birthdate ?? this.birthdate,
      gender: gender ?? this.gender,
      interestedIn: interestedIn ?? this.interestedIn,
      bio: bio ?? this.bio,
      photoUrls: photoUrls ?? this.photoUrls,
      city: city ?? this.city,
      location: location ?? this.location,
      ageRangeMin: ageRangeMin ?? this.ageRangeMin,
      ageRangeMax: ageRangeMax ?? this.ageRangeMax,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt,
      lastActive: lastActive,
      viewCount: viewCount,
      likeCount: likeCount,
      interests: interests ?? this.interests,
      intent: intent ?? this.intent,
    );
  }

  static String _firstNonEmptyString(List<Object?> values) {
    for (final value in values) {
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
    }
    return '';
  }

  static List<String> _stringListFromAny(List<Object?> values) {
    for (final value in values) {
      if (value is List) {
        final result = value
            .whereType<String>()
            .map((entry) => entry.trim())
            .where((entry) => entry.isNotEmpty)
            .toList();
        if (result.isNotEmpty) return result;
      }
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) return [trimmed];
      }
    }
    return <String>[];
  }
}
