import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;
  String? get currentUid => currentUser?.uid;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendEmailVerification() async {
    await currentUser?.sendEmailVerification();
  }

  Future<void> sendPasswordReset({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }
}
