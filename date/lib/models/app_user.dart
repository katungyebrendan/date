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
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      birthdate: (map['birthdate'] as Timestamp?)?.toDate(),
      gender: map['gender'] != null ? GenderCodec.fromValue(map['gender'] as String) : null,
      interestedIn: ((map['interestedIn'] as List?) ?? const [])
          .map((v) => GenderCodec.fromValue(v as String))
          .toSet(),
      bio: map['bio'] as String? ?? '',
      photoUrls: List<String>.from((map['photoUrls'] as List?) ?? const []),
      city: map['city'] as String? ?? '',
      ageRangeMin: (map['ageRangeMin'] as num?)?.toInt() ?? 18,
      ageRangeMax: (map['ageRangeMax'] as num?)?.toInt() ?? 55,
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      lastActive: (map['lastActive'] as Timestamp?)?.toDate(),
      viewCount: (map['viewCount'] as num?)?.toInt() ?? 0,
      likeCount: (map['likeCount'] as num?)?.toInt() ?? 0,
      interests: List<String>.from((map['interests'] as List?) ?? const []),
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
}
