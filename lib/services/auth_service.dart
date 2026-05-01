import 'package:firebase_auth/firebase_auth.dart';

import '../models/social_sign_in_result.dart';
import '../models/user_role.dart';
import '../repositories/auth_repository.dart';
import 'api_service.dart';

export '../models/social_sign_in_result.dart';

class AuthService {
  final AuthRepository _authRepo;
  final ApiService _api;

  AuthService({
    AuthRepository? authRepo,
    ApiService? api,
  })  : _authRepo = authRepo ?? AuthRepository(),
        _api = api ?? ApiService();

  Future<({String uid, UserRole role})> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _authRepo.signIn(
      email: email.trim(),
      password: password,
    );

    if (!cred.user!.emailVerified) {
      await _authRepo.signOut();
      throw UnverifiedEmailException();
    }

    final role = await _syncAndResolveRole(cred.user!);
    if (role == null) throw UserNotFoundException();

    return (uid: cred.user!.uid, role: role);
  }

  Future<SocialSignInResult> signInWithGoogle() async {
    final cred = await _authRepo.signInWithGoogle();
    return _handleSocialCredential(cred);
  }

  Future<SocialSignInResult> signInWithApple() async {
    final cred = await _authRepo.signInWithApple();
    return _handleSocialCredential(cred);
  }

  Future<({String uid, UserRole role})> completeSocialProfile({
    required UserRole role,
  }) async {
    final user = _authRepo.currentUser;
    if (user == null) throw UserNotFoundException();

    await _api.createUser(
      uid: user.uid,
      name: user.displayName ?? user.email?.split('@').first ?? 'User',
      email: user.email ?? '',
      role: role.label,
    );

    await _syncAndResolveRole(user);
    return (uid: user.uid, role: role);
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? classCode,
    String? childName,
  }) async {
    final cred = await _authRepo.register(email: email, password: password);
    final uid = cred.user!.uid;

    await cred.user!.sendEmailVerification();

    await _api.createUser(
      uid: uid,
      name: name,
      email: email,
      role: role.label,
    );

    String? classWarning;
    if ((role == UserRole.student || role == UserRole.parent) &&
        classCode != null &&
        classCode.isNotEmpty) {
      try {
        await _api.joinClass(classCode: classCode, childName: childName);
      } catch (e) {
        classWarning = 'Could not join class: $e';
      }
    }

    await _authRepo.signOut();
    return classWarning;
  }

  Future<void> signOut() => _authRepo.signOut();

  Future<void> sendPasswordReset({required String email}) {
    return _authRepo.sendPasswordReset(email: email);
  }

  // ── Private ──────────────────────────────────────────────────────────

  Future<SocialSignInResult> _handleSocialCredential(
    UserCredential cred,
  ) async {
    final user = cred.user!;
    final role = await _syncAndResolveRole(user);

    if (role != null) {
      return SocialSignInResult(
        uid: user.uid,
        role: role,
        isNewUser: false,
      );
    }

    return SocialSignInResult(
      uid: user.uid,
      role: null,
      isNewUser: true,
      displayName: user.displayName,
      email: user.email,
    );
  }

  Future<UserRole?> _syncAndResolveRole(User user) async {
    try {
      await _api.syncClaims();
    } catch (_) {}

    final tokenResult = await user.getIdTokenResult(true);
    final roleStr = tokenResult.claims?['role'] as String?;
    return roleStr != null ? UserRole.fromString(roleStr) : null;
  }
}

class UnverifiedEmailException implements Exception {
  @override
  String toString() => 'Please verify your email first. Check your inbox.';
}

class UserNotFoundException implements Exception {
  @override
  String toString() => 'User profile not found.';
}
