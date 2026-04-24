import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';
import '../models/grade_model.dart';

class GradeRepository extends BaseRepository {
  CollectionReference get _grades => db.collection('grades');

  Future<bool> enterGrade(GradeModel grade) async {
    try {
      final existing = await _grades
          .where('studentUid', isEqualTo: grade.studentUid)
          .where('classId', isEqualTo: grade.classId)
          .where('assessmentName', isEqualTo: grade.assessmentName)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.update({
          'score': grade.score,
          'total': grade.total,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _grades.add(grade.toMap());
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<QuerySnapshot> getStudentGrades(String studentUid) {
    return _grades
        .where('studentUid', isEqualTo: studentUid)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getClassGrades(String classId) {
    return _grades
        .where('classId', isEqualTo: classId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<List<GradeModel>> fetchStudentGrades(String studentUid) async {
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

  Future<List<GradeModel>> fetchClassGrades(String classId) async {
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

  Future<List<GradeModel>> fetchAll() async {
    try {
      final snap = await _grades
          .orderBy('createdAt', descending: true)
          .limit(500)
          .get();
      return snap.docs.map((d) => GradeModel.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }
}
