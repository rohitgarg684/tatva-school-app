import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';
import '../models/student_model.dart';

class StudentRepository extends BaseRepository {
  CollectionReference get _students => db.collection('students');

  Future<StudentModel?> addStudent(StudentModel model) async {
    try {
      final ref = await _students.add(model.toMap());
      return StudentModel(
        id: ref.id,
        name: model.name,
        rollNumber: model.rollNumber,
        grade: model.grade,
        section: model.section,
        parentName: model.parentName,
        parentPhone: model.parentPhone,
        classIds: model.classIds,
        enrolledBy: model.enrolledBy,
      );
    } catch (_) {
      return null;
    }
  }

  Future<StudentModel?> getStudent(String id) async {
    try {
      final doc = await _students.doc(id).get();
      return doc.exists ? StudentModel.fromFirestore(doc) : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<StudentModel>> getAllStudents() async {
    try {
      final snap =
          await _students.orderBy('name', descending: false).get();
      return snap.docs.map((d) => StudentModel.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<StudentModel>> getStudentsByClass(String classId) async {
    try {
      final snap = await _students
          .where('classIds', arrayContains: classId)
          .orderBy('name')
          .get();
      return snap.docs.map((d) => StudentModel.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<StudentModel>> searchStudents(String query) async {
    if (query.trim().isEmpty) return getAllStudents();
    try {
      final lower = query.trim().toLowerCase();
      final all = await getAllStudents();
      return all
          .where((s) =>
              s.name.toLowerCase().contains(lower) ||
              s.rollNumber.toLowerCase().contains(lower))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> updateStudent(String id, Map<String, dynamic> data) {
    return _students.doc(id).update(data);
  }

  Future<void> addClassToStudent(String studentId, String classId) {
    return _students.doc(studentId).update({
      'classIds': FieldValue.arrayUnion([classId]),
    });
  }

  Future<void> deleteStudent(String id) {
    return _students.doc(id).delete();
  }
}
