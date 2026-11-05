import 'package:firebase_auth/firebase_auth.dart';

/// Thrown by [AuthService] with a message that is safe to show to users.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Thin wrapper over Firebase Authentication that turns Firebase error codes
/// into readable messages.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _guard(() => _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ));
    final user = cred.user!;
    await user.updateDisplayName(name.trim());
    await user.sendEmailVerification();
    return user;
  }

  Future<void> signIn({required String email, required String password}) =>
      _guard(() => _auth.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          ));

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  Future<void> resendVerification() =>
      _guard(() async => _auth.currentUser?.sendEmailVerification());

  /// Reloads the user from Firebase and, once verified, refreshes the ID
  /// token so security rules see `email_verified == true` immediately.
  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshed = _auth.currentUser;
    if (refreshed?.emailVerified ?? false) {
      await refreshed!.getIdToken(true);
      return true;
    }
    return false;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    }
  }

  static String _messageFor(String code) => switch (code) {
        'invalid-email' => 'That email address is not valid.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Incorrect email or password.',
        'email-already-in-use' => 'An account already exists for that email.',
        'weak-password' => 'Choose a stronger password.',
        'too-many-requests' =>
          'Too many attempts. Wait a moment and try again.',
        'network-request-failed' => 'No internet connection.',
        _ => 'Something went wrong ($code). Please try again.',
      };
}
