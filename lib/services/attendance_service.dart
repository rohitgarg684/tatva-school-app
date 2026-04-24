import '../models/attendance_record.dart';
import '../models/attendance_status.dart';
import '../models/activity_event.dart';
import '../repositories/attendance_repository.dart';
import 'activity_service.dart';

class AttendanceService {
  final AttendanceRepository _repo;
  final ActivityService _activitySvc;

  AttendanceService({
    AttendanceRepository? repo,
    ActivityService? activitySvc,
  })  : _repo = repo ?? AttendanceRepository(),
        _activitySvc = activitySvc ?? ActivityService();

  /// Marks attendance for a single student. Upserts by student+date.
  Future<bool> markAttendance({
    required String studentUid,
    required String studentName,
    required String classId,
    required String date,
    required AttendanceStatus status,
    required String markedBy,
  }) async {
    final record = AttendanceRecord(
      studentUid: studentUid,
      studentName: studentName,
      classId: classId,
      date: date,
      status: status,
      markedBy: markedBy,
    );

    final id = await _repo.mark(record);
    return id != null;
  }

  /// Marks attendance for an entire class at once.
  Future<void> markClassAttendance({
    required String classId,
    required String date,
    required Map<String, AttendanceStatus> studentStatuses,
    required Map<String, String> studentNames,
    required String markedBy,
    required String markedByName,
  }) async {
    for (final entry in studentStatuses.entries) {
      await markAttendance(
        studentUid: entry.key,
        studentName: studentNames[entry.key] ?? '',
        classId: classId,
        date: date,
        status: entry.value,
        markedBy: markedBy,
      );
    }

    final present =
        studentStatuses.values.where((s) => s == AttendanceStatus.present).length;
    final total = studentStatuses.length;

    await _activitySvc.log(ActivityEvent(
      type: ActivityType.attendance,
      actorUid: markedBy,
      actorName: markedByName,
      classId: classId,
      title: 'Attendance marked: $present/$total present',
      body: '$markedByName marked attendance for $date',
    ));
  }

  Future<List<AttendanceRecord>> getClassAttendance(
      String classId, String date) {
    return _repo.fetchByClassAndDate(classId, date);
  }

  Future<List<AttendanceRecord>> getStudentAttendance(String studentUid) {
    return _repo.fetchByStudent(studentUid);
  }

  Future<List<AttendanceRecord>> getStudentAttendanceInRange(
      String studentUid, String startDate, String endDate) {
    return _repo.fetchByStudentInRange(studentUid, startDate, endDate);
  }

  /// Computes attendance summary from records.
  ({int present, int absent, int tardy, int total}) computeSummary(
      List<AttendanceRecord> records) {
    int present = 0, absent = 0, tardy = 0;
    for (final r in records) {
      switch (r.status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.tardy:
          tardy++;
          break;
      }
    }
    return (present: present, absent: absent, tardy: tardy, total: records.length);
  }
}
