import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';
import '../models/homework_model.dart';

class HomeworkRepository extends BaseRepository {
  CollectionReference get _homework => db.collection('homework');

  Future<HomeworkModel?> create(HomeworkModel model) async {
    try {
      final ref = await _homework.add(model.toMap());
      return HomeworkModel(
        id: ref.id,
        title: model.title,
        description: model.description,
        subject: model.subject,
        classId: model.classId,
        className: model.className,
        teacherUid: model.teacherUid,
        teacherName: model.teacherName,
        dueDate: model.dueDate,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<HomeworkModel>> getByClass(String classId) async {
    try {
      final snap = await _homework
          .where('classId', isEqualTo: classId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => HomeworkModel.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<HomeworkModel>> getByTeacher(String teacherUid) async {
    try {
      final snap = await _homework
          .where('teacherUid', isEqualTo: teacherUid)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => HomeworkModel.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> markSubmitted(String homeworkId, String studentUid) {
    return _homework.doc(homeworkId).update({
      'submittedBy': FieldValue.arrayUnion([studentUid]),
    });
  }

  Future<void> deleteHomework(String id) => _homework.doc(id).delete();
}
