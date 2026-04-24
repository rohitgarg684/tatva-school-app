import '../models/behavior_point.dart';
import '../models/behavior_category.dart';
import '../models/activity_event.dart';
import '../repositories/behavior_repository.dart';
import 'activity_service.dart';

class BehaviorService {
  final BehaviorRepository _repo;
  final ActivityService _activitySvc;

  BehaviorService({
    BehaviorRepository? repo,
    ActivityService? activitySvc,
  })  : _repo = repo ?? BehaviorRepository(),
        _activitySvc = activitySvc ?? ActivityService();

  Future<bool> awardPoint({
    required String studentUid,
    required String studentName,
    required String classId,
    required String categoryId,
    required bool isPositive,
    required String awardedBy,
    required String awardedByName,
    String note = '',
  }) async {
    final point = BehaviorPoint(
      studentUid: studentUid,
      studentName: studentName,
      classId: classId,
      categoryId: categoryId,
      points: isPositive ? 1 : -1,
      awardedBy: awardedBy,
      awardedByName: awardedByName,
      note: note,
    );

    final id = await _repo.add(point);
    if (id == null) return false;

    final cat = BehaviorCategory.fromId(categoryId);
    await _activitySvc.log(ActivityEvent(
      type: ActivityType.behaviorPoint,
      actorUid: awardedBy,
      actorName: awardedByName,
      targetUid: studentUid,
      classId: classId,
      title: '${isPositive ? '+1' : '-1'} ${cat.name}',
      body: '$awardedByName gave $studentName ${isPositive ? 'a' : 'a negative'} point for ${cat.name}',
    ));

    return true;
  }

  Future<List<BehaviorPoint>> getStudentPoints(String studentUid) {
    return _repo.fetchByStudent(studentUid);
  }

  Future<List<BehaviorPoint>> getClassPoints(String classId) {
    return _repo.fetchByClass(classId);
  }

  /// Computes total score for a student from their behavior points.
  int computeScore(List<BehaviorPoint> points) {
    return points.fold(0, (sum, p) => sum + p.points);
  }

  /// Groups points by category for summary display.
  Map<String, int> summarizeByCategory(List<BehaviorPoint> points) {
    final map = <String, int>{};
    for (final p in points) {
      map.update(p.categoryId, (v) => v + p.points, ifAbsent: () => p.points);
    }
    return map;
  }
}
