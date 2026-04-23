import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class BaseRepository {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  String get currentUid {
    final user = auth.currentUser;
    if (user == null) {
      throw StateError('Repository called with no authenticated user.');
    }
    return user.uid;
  }
}
