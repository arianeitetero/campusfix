import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  student,
  staff;

  static UserRole fromName(String? name) =>
      name == staff.name ? staff : student;
}

/// Profile stored at `users/{uid}`. The role is never set by the client
/// beyond the default `student`; staff are promoted in the Firebase console
/// (see firestore.rules).
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.createdAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime? createdAt;

  bool get isStaff => role == UserRole.staff;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: UserRole.fromName(data['role'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toNewUserMap() => {
        'email': email,
        'displayName': displayName,
        'role': UserRole.student.name,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
