import '../../models/attendance_record.dart';
import '../../models/attendance_status.dart';
import '../../models/weekly_report.dart';

export '../../shared/utils/activity_helpers.dart' show formatTimeAgo;

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
