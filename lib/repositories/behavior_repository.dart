import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';
import '../models/behavior_point.dart';

class BehaviorRepository extends BaseRepository {
  CollectionReference get _points => db.collection('behavior_points');

  Future<String?> add(BehaviorPoint point) async {
    try {
      final ref = await _points.add(point.toMap());
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  Future<List<BehaviorPoint>> fetchByStudent(String studentUid,
      {int limit = 100}) async {
    try {
      final snap = await _points
          .where('studentUid', isEqualTo: studentUid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => BehaviorPoint.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<BehaviorPoint>> fetchByClass(String classId,
      {int limit = 200}) async {
    try {
      final snap = await _points
          .where('classId', isEqualTo: classId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => BehaviorPoint.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<BehaviorPoint>> fetchByClassAndDate(
      String classId, String date) async {
    try {
      final start = DateTime.parse(date);
      final end = start.add(const Duration(days: 1));
      final snap = await _points
          .where('classId', isEqualTo: classId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => BehaviorPoint.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> delete(String id) => _points.doc(id).delete();
}
