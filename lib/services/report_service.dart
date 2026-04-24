import '../models/weekly_report.dart';
import '../models/attendance_status.dart';
import 'behavior_service.dart';
import 'attendance_service.dart';
import 'grade_service.dart';
import '../repositories/homework_repository.dart';

/// Generates on-demand reports (not stored in Firestore).
class ReportService {
  final BehaviorService _behaviorSvc;
  final AttendanceService _attendanceSvc;
  final GradeService _gradeSvc;
  final HomeworkRepository _hwRepo;

  ReportService({
    BehaviorService? behaviorSvc,
    AttendanceService? attendanceSvc,
    GradeService? gradeSvc,
    HomeworkRepository? hwRepo,
  })  : _behaviorSvc = behaviorSvc ?? BehaviorService(),
        _attendanceSvc = attendanceSvc ?? AttendanceService(),
        _gradeSvc = gradeSvc ?? GradeService(),
        _hwRepo = hwRepo ?? HomeworkRepository();

  /// Generates a weekly report for a student.
  Future<WeeklyReport> generateWeeklyReport({
    required String studentUid,
    required String studentName,
    required String className,
    required List<String> classIds,
    required String weekStart,
    required String weekEnd,
  }) async {
    // Behavior
    final points = await _behaviorSvc.getStudentPoints(studentUid);
    final weekPoints = points.where((p) {
      if (p.createdAt == null) return false;
      final d = p.createdAt!.toIso8601String().substring(0, 10);
      return d.compareTo(weekStart) >= 0 && d.compareTo(weekEnd) <= 0;
    }).toList();
    final positive = weekPoints.where((p) => p.isPositive).length;
    final negative = weekPoints.where((p) => !p.isPositive).length;
    final topCats = _behaviorSvc.summarizeByCategory(weekPoints);

    // Attendance
    final attendance = await _attendanceSvc.getStudentAttendanceInRange(
        studentUid, weekStart, weekEnd);
    final attSummary = _attendanceSvc.computeSummary(attendance);

    // Homework
    int hwComplete = 0, hwTotal = 0;
    for (final cid in classIds) {
      final hws = await _hwRepo.getByClass(cid);
      for (final hw in hws) {
        hwTotal++;
        if (hw.isSubmittedBy(studentUid)) hwComplete++;
      }
    }

    // Grades
    final grades = await _gradeSvc.getStudentGrades(studentUid);
    final avg = _gradeSvc.computeOverallAverage(grades);

    return WeeklyReport(
      studentName: studentName,
      className: className,
      weekLabel: '$weekStart to $weekEnd',
      behaviorPointsTotal: positive - negative,
      positivePoints: positive,
      negativePoints: negative,
      topCategories: topCats,
      daysPresent: attSummary.present,
      daysAbsent: attSummary.absent,
      daysTardy: attSummary.tardy,
      totalSchoolDays: attSummary.total > 0 ? attSummary.total : 5,
      homeworkCompleted: hwComplete,
      homeworkTotal: hwTotal,
      gradeAverage: avg,
    );
  }

  /// Generates a CSV string of the weekly report for export.
  String exportToCsv(WeeklyReport report) {
    final buf = StringBuffer();
    buf.writeln('Weekly Report for ${report.studentName}');
    buf.writeln('Class,${report.className}');
    buf.writeln('Week,${report.weekLabel}');
    buf.writeln('');
    buf.writeln('Section,Metric,Value');
    buf.writeln('Behavior,Total Points,${report.behaviorPointsTotal}');
    buf.writeln('Behavior,Positive,${report.positivePoints}');
    buf.writeln('Behavior,Negative,${report.negativePoints}');
    buf.writeln('Attendance,Present,${report.daysPresent}');
    buf.writeln('Attendance,Absent,${report.daysAbsent}');
    buf.writeln('Attendance,Tardy,${report.daysTardy}');
    buf.writeln(
        'Attendance,Rate,${report.attendanceRate.toStringAsFixed(1)}%');
    buf.writeln('Homework,Completed,${report.homeworkCompleted}');
    buf.writeln('Homework,Total,${report.homeworkTotal}');
    buf.writeln(
        'Homework,Rate,${report.homeworkCompletionRate.toStringAsFixed(1)}%');
    buf.writeln('Grades,Average,${report.gradeAverage.toStringAsFixed(1)}%');
    return buf.toString();
  }
}
