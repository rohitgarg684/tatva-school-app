import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';
import '../models/activity_event.dart';

class ActivityRepository extends BaseRepository {
  CollectionReference get _activities => db.collection('activities');

  Future<String?> add(ActivityEvent event) async {
    try {
      final ref = await _activities.add(event.toMap());
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  Future<List<ActivityEvent>> fetchByClass(String classId,
      {int limit = 50}) async {
    try {
      final snap = await _activities
          .where('classId', isEqualTo: classId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => ActivityEvent.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ActivityEvent>> fetchByUser(String uid,
      {int limit = 50}) async {
    try {
      final snap = await _activities
          .where('targetUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => ActivityEvent.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ActivityEvent>> fetchGlobal({int limit = 50}) async {
    try {
      final snap = await _activities
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => ActivityEvent.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }
}
