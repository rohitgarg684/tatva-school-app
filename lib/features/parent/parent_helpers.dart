import '../../models/attendance_record.dart';
import '../../models/attendance_status.dart';
import '../../models/grade_model.dart';
import '../../models/weekly_report.dart';
import '../../services/dashboard_service.dart';

export '../../shared/utils/activity_helpers.dart' show formatTimeAgo;

typedef UniqueChild = ({int firstIndex, String name});

List<UniqueChild> uniqueChildEntries(List<ChildDashboardData> childrenData) {
  final seen = <String>{};
  final result = <UniqueChild>[];
  for (var i = 0; i < childrenData.length; i++) {
    final name = childrenData[i].info.childName;
    if (seen.add(name)) result.add((firstIndex: i, name: name));
  }
  return result;
}

List<ChildDashboardData> childEntriesFor(
    List<ChildDashboardData> all, String childName) {
  return all.where((c) => c.info.childName == childName).toList();
}

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}

double computeGradeAverage(List<GradeModel> grades) {
  if (grades.isEmpty) return 0.0;
  final total = grades.fold(
      0.0, (s, g) => s + (g.total > 0 ? g.score / g.total * 100 : 0.0));
  return total / grades.length;
}

({int present, int absent, int tardy, int total})
    computeAttendanceSummary(List<AttendanceRecord> records) {
  int present = 0, absent = 0, tardy = 0;
  for (final r in records) {
    switch (r.status) {
      case AttendanceStatus.present:
        present++;
      case AttendanceStatus.absent:
        absent++;
      case AttendanceStatus.tardy:
        tardy++;
    }
  }
  return (present: present, absent: absent, tardy: tardy, total: present + absent + tardy);
}

String exportReportToCsv(WeeklyReport report) {
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
  buf.writeln('Attendance,Rate,${report.attendanceRate.toStringAsFixed(1)}%');
  buf.writeln('Homework,Completed,${report.homeworkCompleted}');
  buf.writeln('Homework,Total,${report.homeworkTotal}');
  buf.writeln('Homework,Rate,${report.homeworkCompletionRate.toStringAsFixed(1)}%');
  buf.writeln('Grades,Average,${report.gradeAverage.toStringAsFixed(1)}%');
  return buf.toString();
}
