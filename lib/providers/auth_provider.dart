import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/validators.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_repository.dart';

enum AuthStatus {
  /// Waiting for Firebase to restore the session or load the profile.
  initializing,
  signedOut,

  /// Signed in, but the ALU email address has not been verified yet.
  unverified,
  signedIn,
}

/// App-wide session state: who is signed in, whether their email is
/// verified, and their Firestore profile (which carries the role).
class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService, required UserRepository userRepository})
      : _auth = authService,
        _users = userRepository {
    _authSub = _auth.authStateChanges().listen(_onAuthUser);
  }

  final AuthService _auth;
  final UserRepository _users;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  AuthStatus _status = AuthStatus.initializing;
  AppUser? _user;
  bool _busy = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isStaff => _user?.isStaff ?? false;
  bool get isBusy => _busy;
  String? get pendingEmail => _auth.currentUser?.email;

  Future<void> _onAuthUser(User? firebaseUser) async {
    await _profileSub?.cancel();
    _profileSub = null;
    _user = null;

    if (firebaseUser == null) {
      _setStatus(AuthStatus.signedOut);
      return;
    }
    // Defence in depth: registration already rejects other domains, but an
    // account created outside the app must not get in either.
    if (!Validators.isAluEmail(firebaseUser.email ?? '')) {
      await _auth.signOut();
      return;
    }
    if (!firebaseUser.emailVerified) {
      _setStatus(AuthStatus.unverified);
      return;
    }

    _setStatus(AuthStatus.initializing);
    try {
      await _users.ensureProfile(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
      );
    } catch (e) {
      debugPrint('ensureProfile failed: $e');
    }
    _profileSub = _users.watch(firebaseUser.uid).listen(
      (profile) {
        _user = profile;
        _setStatus(profile == null ? AuthStatus.initializing : AuthStatus.signedIn);
      },
      onError: (Object e) => debugPrint('profile stream error: $e'),
    );
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  /// Runs an auth action, tracking [isBusy] and returning an error message
  /// for the UI, or null on success.
  Future<String?> _run(Future<void> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      await action();
      return null;
    } on AuthFailure catch (e) {
      return e.message;
    } catch (e) {
      return 'Something went wrong. Please try again.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> signIn(String email, String password) =>
      _run(() => _auth.signIn(email: email, password: password));

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _run(() async {
      final user =
          await _auth.register(name: name, email: email, password: password);
      await _users.ensureProfile(
          uid: user.uid, email: user.email ?? email, displayName: name.trim());
    });
  }

  Future<String?> sendPasswordReset(String email) =>
      _run(() => _auth.sendPasswordReset(email));

  Future<String?> resendVerification() => _run(_auth.resendVerification);

  /// Called from the verification screen. Firebase does not emit an auth
  /// event when a user verifies, so re-evaluate manually.
  Future<bool> checkEmailVerified() async {
    final verified = await _auth.reloadAndCheckVerified();
    if (verified) await _onAuthUser(_auth.currentUser);
    return verified;
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
