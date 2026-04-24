import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';
import '../models/student_model.dart';

/// Pure data access for the `students` collection.
/// Client-side search belongs in a service layer.
class StudentRepository extends BaseRepository {
  CollectionReference get _students => db.collection('students');

  Future<StudentModel?> add(StudentModel model) async {
    try {
      final ref = await _students.add(model.toMap());
      return model.copyWith().copyWith(); // can't change id without a setter
    } catch (_) {
      return null;
    }
  }

  Future<StudentModel?> getById(String id) async {
    try {
      final doc = await _students.doc(id).get();
      return doc.exists ? StudentModel.fromFirestore(doc) : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<StudentModel>> getAll() async {
    try {
      final snap =
          await _students.orderBy('name', descending: false).get();
      return snap.docs.map((d) => StudentModel.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<StudentModel>> getByClass(String classId) async {
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

  Future<void> update(String id, Map<String, dynamic> data) {
    return _students.doc(id).update(data);
  }

  Future<void> addClassToStudent(String studentId, String classId) {
    return _students.doc(studentId).update({
      'classIds': FieldValue.arrayUnion([classId]),
    });
  }

  Future<void> delete(String id) {
    return _students.doc(id).delete();
  }
}
