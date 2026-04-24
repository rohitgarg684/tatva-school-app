import '../models/user_model.dart';
import '../models/user_role.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import 'class_service.dart';

class AuthService {
  final AuthRepository _authRepo;
  final UserRepository _userRepo;
  final ClassService _classSvc;

  AuthService({
    AuthRepository? authRepo,
    UserRepository? userRepo,
    ClassService? classSvc,
  })  : _authRepo = authRepo ?? AuthRepository(),
        _userRepo = userRepo ?? UserRepository(),
        _classSvc = classSvc ?? ClassService();

  Future<({UserModel user, UserRole role})?> signIn({
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

    final user = await _userRepo.getUser(cred.user!.uid);
    if (user == null) throw UserNotFoundException();

    return (user: user, role: user.role);
  }

  /// Registers a new user, sends verification email, saves to Firestore,
  /// optionally joins a class, then signs out (user must verify before login).
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

    final user = UserModel(
      uid: uid,
      name: name,
      email: email,
      role: role,
    );
    await _userRepo.createUser(user);

    // Delegate class-joining to ClassService (no duplication)
    String? classWarning;
    if ((role == UserRole.student || role == UserRole.parent) &&
        classCode != null &&
        classCode.isNotEmpty) {
      classWarning = await _classSvc.joinClassByCode(
        classCode: classCode,
        role: role,
        childName: childName,
      );
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
