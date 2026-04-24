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

  /// Loads homework across multiple classes in a single Firestore query.
  Future<List<HomeworkModel>> getForClasses(List<String> classIds) {
    return _repo.getByClasses(classIds);
  }

  Future<void> markSubmitted({
    required String homeworkId,
    required String studentUid,
  }) {
    return _repo.markSubmitted(homeworkId, studentUid);
  }
}
