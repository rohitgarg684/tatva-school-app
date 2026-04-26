import '../../models/attendance_record.dart';
import '../../models/attendance_status.dart';
import '../../models/weekly_report.dart';

String formatTimeAgo(DateTime dt) {
  final local = dt.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final time = '${local.hour % 12 == 0 ? 12 : local.hour % 12}:${local.minute.toString().padLeft(2, '0')} ${local.hour < 12 ? 'AM' : 'PM'}';

  String relative;
  if (diff.inMinutes < 1) {
    relative = 'now';
  } else if (diff.inMinutes < 60) {
    relative = '${diff.inMinutes}m ago';
  } else if (diff.inHours < 24) {
    relative = '${diff.inHours}h ago';
  } else if (diff.inDays < 7) {
    relative = '${diff.inDays}d ago';
  } else {
    relative = '${(diff.inDays / 7).floor()}w ago';
  }

  if (diff.inHours < 24) {
    final isToday = local.day == now.day && local.month == now.month && local.year == now.year;
    return '${isToday ? 'Today' : 'Yesterday'}, $time · $relative';
  }
  if (local.year == now.year) {
    return '${months[local.month]} ${local.day}, $time · $relative';
  }
  return '${months[local.month]} ${local.day}, ${local.year} · $relative';
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
