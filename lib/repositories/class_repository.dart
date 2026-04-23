import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';
import '../models/class_model.dart';

class ClassRepository extends BaseRepository {
  CollectionReference get _classes => db.collection('classes');

  Future<ClassModel?> createClass(ClassModel model) async {
    try {
      final ref = await _classes.add(model.toMap());
      return ClassModel(
        id: ref.id,
        name: model.name,
        subject: model.subject,
        teacherUid: model.teacherUid,
        teacherName: model.teacherName,
        teacherEmail: model.teacherEmail,
        classCode: model.classCode,
      );
    } catch (_) {
      return null;
    }
  }

  Stream<QuerySnapshot> getTeacherClasses(String teacherUid) {
    return _classes.where('teacherUid', isEqualTo: teacherUid).snapshots();
  }

  Future<ClassModel?> findByCode(String classCode) async {
    final query = await _classes
        .where('classCode', isEqualTo: classCode.trim().toUpperCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return ClassModel.fromFirestore(query.docs.first);
  }

  Future<bool> isCodeUnique(String code) async {
    final query =
        await _classes.where('classCode', isEqualTo: code).limit(1).get();
    return query.docs.isEmpty;
  }

  Future<void> addStudentToClass(String classId, String studentUid) {
    return _classes.doc(classId).update({
      'studentUids': FieldValue.arrayUnion([studentUid]),
    });
  }

  Future<void> addParentToClass(String classId, String parentUid) {
    return _classes.doc(classId).update({
      'parentUids': FieldValue.arrayUnion([parentUid]),
    });
  }

  Future<ClassModel?> getClass(String classId) async {
    try {
      final doc = await _classes.doc(classId).get();
      return doc.exists ? ClassModel.fromFirestore(doc) : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<ClassModel>> getClassesByIds(List<String> classIds) async {
    if (classIds.isEmpty) return [];
    try {
      final docs = await Future.wait(
        classIds.map((id) => _classes.doc(id).get()),
      );
      return docs
          .where((doc) => doc.exists)
          .map((doc) => ClassModel.fromFirestore(doc))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
