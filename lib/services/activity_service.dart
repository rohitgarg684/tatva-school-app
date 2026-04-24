import '../models/activity_event.dart';
import '../repositories/activity_repository.dart';

class ActivityService {
  final ActivityRepository _repo;

  ActivityService({ActivityRepository? repo})
      : _repo = repo ?? ActivityRepository();

  Future<void> log(ActivityEvent event) async {
    await _repo.add(event);
  }

  Future<List<ActivityEvent>> getClassFeed(String classId, {int limit = 50}) {
    return _repo.fetchByClass(classId, limit: limit);
  }

  Future<List<ActivityEvent>> getUserFeed(String uid, {int limit = 50}) {
    return _repo.fetchByUser(uid, limit: limit);
  }

  Future<List<ActivityEvent>> getSchoolFeed({int limit = 50}) {
    return _repo.fetchGlobal(limit: limit);
  }
}
