/// In-memory model for weekly parent reports (not stored in Firestore).
/// Generated on-demand by ReportService.
class WeeklyReport {
  final String studentName;
  final String className;
  final String weekLabel;
  final int behaviorPointsTotal;
  final int positivePoints;
  final int negativePoints;
  final Map<String, int> topCategories;
  final int daysPresent;
  final int daysAbsent;
  final int daysTardy;
  final int totalSchoolDays;
  final int homeworkCompleted;
  final int homeworkTotal;
  final double gradeAverage;
  final List<String> teacherNotes;

  const WeeklyReport({
    required this.studentName,
    required this.className,
    required this.weekLabel,
    this.behaviorPointsTotal = 0,
    this.positivePoints = 0,
    this.negativePoints = 0,
    this.topCategories = const {},
    this.daysPresent = 0,
    this.daysAbsent = 0,
    this.daysTardy = 0,
    this.totalSchoolDays = 5,
    this.homeworkCompleted = 0,
    this.homeworkTotal = 0,
    this.gradeAverage = 0.0,
    this.teacherNotes = const [],
  });

  WeeklyReport copyWith({
    String? studentName,
    String? className,
    String? weekLabel,
    int? behaviorPointsTotal,
    int? positivePoints,
    int? negativePoints,
    Map<String, int>? topCategories,
    int? daysPresent,
    int? daysAbsent,
    int? daysTardy,
    int? totalSchoolDays,
    int? homeworkCompleted,
    int? homeworkTotal,
    double? gradeAverage,
    List<String>? teacherNotes,
  }) {
    return WeeklyReport(
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      weekLabel: weekLabel ?? this.weekLabel,
      behaviorPointsTotal: behaviorPointsTotal ?? this.behaviorPointsTotal,
      positivePoints: positivePoints ?? this.positivePoints,
      negativePoints: negativePoints ?? this.negativePoints,
      topCategories: topCategories ?? this.topCategories,
      daysPresent: daysPresent ?? this.daysPresent,
      daysAbsent: daysAbsent ?? this.daysAbsent,
      daysTardy: daysTardy ?? this.daysTardy,
      totalSchoolDays: totalSchoolDays ?? this.totalSchoolDays,
      homeworkCompleted: homeworkCompleted ?? this.homeworkCompleted,
      homeworkTotal: homeworkTotal ?? this.homeworkTotal,
      gradeAverage: gradeAverage ?? this.gradeAverage,
      teacherNotes: teacherNotes ?? this.teacherNotes,
    );
  }

  double get attendanceRate =>
      totalSchoolDays > 0 ? daysPresent / totalSchoolDays * 100 : 0;

  double get homeworkCompletionRate =>
      homeworkTotal > 0 ? homeworkCompleted / homeworkTotal * 100 : 0;
}
