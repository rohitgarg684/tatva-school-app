import '../models/user_role.dart';
import '../repositories/auth_repository.dart';
import 'api_service.dart';

class AuthService {
  final AuthRepository _authRepo;
  final ApiService _api;

  AuthService({
    AuthRepository? authRepo,
    ApiService? api,
  })  : _authRepo = authRepo ?? AuthRepository(),
        _api = api ?? ApiService();

  Future<({String uid, UserRole role})?> signIn({
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

    try {
      await _api.syncClaims();
    } catch (_) {}

    final tokenResult = await cred.user!.getIdTokenResult(true);
    final roleStr = tokenResult.claims?['role'] as String?;
    if (roleStr == null) throw UserNotFoundException();

    final role = UserRole.fromString(roleStr);
    return (uid: cred.user!.uid, role: role);
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
}

class UnverifiedEmailException implements Exception {
  @override
  String toString() => 'Please verify your email first. Check your inbox.';
}

class UserNotFoundException implements Exception {
  @override
  String toString() => 'User profile not found.';
}
