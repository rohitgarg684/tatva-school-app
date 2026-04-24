import '../models/homework_model.dart';
import '../repositories/homework_repository.dart';

class HomeworkService {
  final HomeworkRepository _repo;

  HomeworkService({HomeworkRepository? repo})
      : _repo = repo ?? HomeworkRepository();

  Future<HomeworkModel?> create(HomeworkModel model) {
    return _repo.create(model);
  }

  Future<List<HomeworkModel>> getByClass(String classId) {
    return _repo.getByClass(classId);
  }

  Future<List<HomeworkModel>> getByTeacher(String teacherUid) {
    return _repo.getByTeacher(teacherUid);
  }

  /// Loads homework across multiple classes (for students enrolled in several).
  Future<List<HomeworkModel>> getForClasses(List<String> classIds) async {
    final all = <HomeworkModel>[];
    for (final cid in classIds) {
      all.addAll(await _repo.getByClass(cid));
    }
    return all;
  }

  Future<void> markSubmitted({
    required String homeworkId,
    required String studentUid,
  }) {
    return _repo.markSubmitted(homeworkId, studentUid);
  }
}
