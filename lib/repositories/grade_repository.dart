import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';
import '../models/grade_model.dart';

/// Pure data access for the `grades` collection.
/// Business logic (upsert, aggregation) belongs in GradeService.
class GradeRepository extends BaseRepository {
  CollectionReference get _grades => db.collection('grades');

  Future<String?> add(GradeModel grade) async {
    try {
      final ref = await _grades.add(grade.toMap());
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    try {
      await _grades.doc(id).update(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<GradeModel>> findByStudentClassAssessment({
    required String studentUid,
    required String classId,
    required String assessmentName,
  }) async {
    try {
      final snap = await _grades
          .where('studentUid', isEqualTo: studentUid)
          .where('classId', isEqualTo: classId)
          .where('assessmentName', isEqualTo: assessmentName)
          .limit(1)
          .get();
      return snap.docs.map((d) => GradeModel.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<GradeModel>> fetchByStudent(String studentUid) async {
    try {
      final snap = await _grades
          .where('studentUid', isEqualTo: studentUid)
          .orderBy('createdAt', descending: false)
          .get();
      return snap.docs.map((d) => GradeModel.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<GradeModel>> fetchByClass(String classId) async {
    try {
      final snap = await _grades
          .where('classId', isEqualTo: classId)
          .orderBy('createdAt', descending: false)
          .get();
      return snap.docs.map((d) => GradeModel.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<GradeModel>> fetchAll({int limit = 500}) async {
    try {
      final snap = await _grades
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => GradeModel.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }
}
