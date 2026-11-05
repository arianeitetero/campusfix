import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _users = (firestore ?? FirebaseFirestore.instance).collection('users');

  final CollectionReference<Map<String, dynamic>> _users;

  Stream<AppUser?> watch(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);

  /// Creates the profile if it is missing, e.g. when registration was
  /// interrupted between creating the auth account and writing the profile.
  Future<void> ensureProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    final ref = _users.doc(uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set(AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      role: UserRole.student,
    ).toNewUserMap());
  }
}
