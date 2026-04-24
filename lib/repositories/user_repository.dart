import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class UserRepository extends BaseRepository {
  CollectionReference get _users => db.collection('users');

  Future<void> createUser(UserModel user) {
    return _users.doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser([String? uid]) async {
    try {
      final doc = await _users.doc(uid ?? currentUid).get();
      return doc.exists ? UserModel.fromFirestore(doc) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    return _users.doc(uid).update(data);
  }

  Future<void> saveFcmToken(String token) {
    return _users.doc(currentUid).update({'fcmToken': token});
  }

  Stream<QuerySnapshot> getUsersByRole(UserRole role) {
    return _users.where('role', isEqualTo: role.label).snapshots();
  }

  Future<List<UserModel>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    try {
      final docs = await Future.wait(
        uids.map((uid) => _users.doc(uid).get()),
      );
      return docs
          .where((doc) => doc.exists)
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<UserModel>> getAllByRole(UserRole role) async {
    try {
      final snap =
          await _users.where('role', isEqualTo: role.label).get();
      return snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> countByRole(UserRole role) async {
    try {
      final snap =
          await _users.where('role', isEqualTo: role.label).get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }
}
