import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import 'storage_service.dart';

class UserRepository {
  UserRepository(this._firestore, this._storageService);

  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  Stream<AppUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromDoc(doc);
    });
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  Future<void> createUserDoc(AppUser user) {
    return _users.doc(user.uid).set(user.toCreateMap());
  }

  CollectionReference<Map<String, dynamic>> get _phoneNumbers =>
      _firestore.collection('phoneNumbers');

  /// Atomically claims [phoneNumber] for [uid]. Returns false if it's already
  /// claimed by a different account, so the same WhatsApp number can't be
  /// used to create two profiles.
  Future<bool> reservePhoneNumber({required String uid, required String phoneNumber}) {
    final ref = _phoneNumbers.doc(phoneNumber);
    return _firestore.runTransaction<bool>((tx) async {
      final doc = await tx.get(ref);
      if (doc.exists && doc.data()?['uid'] != uid) {
        return false;
      }
      tx.set(ref, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
      return true;
    });
  }

  /// Frees a claimed phone number, e.g. when its owner's account is deleted.
  Future<void> releasePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return Future.value();
    return _phoneNumbers.doc(phoneNumber).delete();
  }

  Future<void> completeOnboarding(AppUser fullProfile) {
    final payload = <String, dynamic>{
      'uid': fullProfile.uid,
      ...fullProfile.toOnboardingMap(),
      'lastActive': FieldValue.serverTimestamp(),
    };
    if (fullProfile.phoneNumber.isNotEmpty) {
      payload['phoneNumber'] = fullProfile.phoneNumber;
    }

    // Use an upsert so onboarding still succeeds if the initial user doc write
    // was interrupted and the profile document does not exist yet.
    return _users.doc(fullProfile.uid).set(payload, SetOptions(merge: true));
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> patch) {
    return _users.doc(uid).update(patch);
  }

  /// Bumps the profile-view counter shown on candidate/match/like cards.
  /// Firestore rules only allow this exact single-field +1 write from a
  /// non-owner, so it can't be folded into [updateProfile].
  Future<void> incrementViewCount(String uid) {
    return _users.doc(uid).update({'viewCount': FieldValue.increment(1)});
  }

  /// Removes the user's profile document and uploaded photos. Does not
  /// delete the underlying Firebase Auth account — that requires a
  /// re-authentication flow, which is a stretch item beyond MVP scope.
  Future<void> deleteAccount(String uid, List<String> photoUrls, {String phoneNumber = ''}) async {
    for (final url in photoUrls) {
      await _storageService.deletePhoto(uid, url);
    }
    await releasePhoneNumber(phoneNumber);
    await _users.doc(uid).delete();
  }
}
