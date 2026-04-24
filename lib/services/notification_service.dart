import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/user_repository.dart';

/// Handles in-app notification records stored in Firestore.
/// Each user has a sub-collection of notifications.
/// FCM token management is handled here; actual push delivery
/// uses Firebase Cloud Functions (server-side, not in-app).
class NotificationService {
  final FirebaseFirestore _db;
  final UserRepository _userRepo;

  NotificationService({
    FirebaseFirestore? db,
    UserRepository? userRepo,
  })  : _db = db ?? FirebaseFirestore.instance,
        _userRepo = userRepo ?? UserRepository();

  CollectionReference _userNotifications(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  /// Saves or updates the FCM token for a user.
  Future<void> saveToken(String uid, String token) async {
    await _userRepo.updateUser(uid, {'fcmToken': token});
  }

  /// Writes an in-app notification to a user's notifications sub-collection.
  Future<void> send({
    required String recipientUid,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic> data = const {},
  }) async {
    await _userNotifications(recipientUid).add({
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sends a notification to all members of a list (e.g., class parents).
  Future<void> sendToMany({
    required List<String> recipientUids,
    required String title,
    required String body,
    String type = 'general',
  }) async {
    for (final uid in recipientUids) {
      await send(recipientUid: uid, title: title, body: body, type: type);
    }
  }

  /// Fetches unread notifications for a user.
  Future<List<Map<String, dynamic>>> getUnread(String uid) async {
    try {
      final snap = await _userNotifications(uid)
          .where('read', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snap.docs
          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Marks a notification as read.
  Future<void> markRead(String uid, String notificationId) {
    return _userNotifications(uid).doc(notificationId).update({'read': true});
  }

  /// Marks all notifications as read.
  Future<void> markAllRead(String uid) async {
    final snap = await _userNotifications(uid)
        .where('read', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.update({'read': true});
    }
  }
}
