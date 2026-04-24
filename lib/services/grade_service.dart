import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grade_model.dart';
import '../repositories/grade_repository.dart';

class GradeService {
  final GradeRepository _repo;

  GradeService({GradeRepository? repo}) : _repo = repo ?? GradeRepository();

  /// Upsert: updates existing grade or creates a new one.
  Future<bool> enterGrade(GradeModel grade) async {
    final existing = await _repo.findByStudentClassAssessment(
      studentUid: grade.studentUid,
      classId: grade.classId,
      assessmentName: grade.assessmentName,
    );

    if (existing.isNotEmpty) {
      return _repo.update(existing.first.id, {
        'score': grade.score,
        'total': grade.total,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      return (await _repo.add(grade)) != null;
    }
  }

  Future<List<GradeModel>> getStudentGrades(String studentUid) {
    return _repo.fetchByStudent(studentUid);
  }

  Future<List<GradeModel>> getClassGrades(String classId) {
    return _repo.fetchByClass(classId);
  }

  Future<List<GradeModel>> getAllGrades() {
    return _repo.fetchAll();
  }

  /// Computes per-subject averages from a list of grades.
  Map<String, double> computeSubjectAverages(List<GradeModel> grades) {
    final map = <String, List<double>>{};
    for (final g in grades) {
      map.putIfAbsent(g.subject, () => []).add(g.percentage);
    }
    return map.map((subject, pcts) =>
        MapEntry(subject, pcts.reduce((a, b) => a + b) / pcts.length));
  }

  /// Computes overall average percentage across all grades.
  double computeOverallAverage(List<GradeModel> grades) {
    if (grades.isEmpty) return 0;
    return grades.map((g) => g.percentage).reduce((a, b) => a + b) /
        grades.length;
  }
}
