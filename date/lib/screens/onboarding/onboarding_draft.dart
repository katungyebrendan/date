import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/gender.dart';
import '../../models/relationship_intent.dart';

/// Mutable in-progress state for the onboarding wizard, shared across steps
/// via a single ChangeNotifier-free holder passed down the widget tree.
class OnboardingDraft {
  String displayName = '';
  DateTime? birthdate;
  Gender? gender;
  Set<Gender> interestedIn = {};
  String bio = '';
  final List<File> photos = [];
  String city = '';
  GeoPoint? location;
  Set<String> interests = {};
  RelationshipIntent? intent;
}
