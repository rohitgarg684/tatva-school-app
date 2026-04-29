import 'user_role.dart';

class SocialSignInResult {
  final String uid;
  final UserRole? role;
  final bool isNewUser;
  final String? displayName;
  final String? email;

  SocialSignInResult({
    required this.uid,
    required this.role,
    required this.isNewUser,
    this.displayName,
    this.email,
  });
}
