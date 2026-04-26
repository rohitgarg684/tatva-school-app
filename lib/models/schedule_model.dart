class PeriodSlot {
  final int period;
  final String startTime; // "08:00"
  final String endTime;   // "08:45"
  final String classId;
  final String subject;
  final String teacherName;

  const PeriodSlot({
    required this.period,
    required this.startTime,
    required this.endTime,
    this.classId = '',
    this.subject = '',
    this.teacherName = '',
  });

  factory PeriodSlot.fromJson(Map<String, dynamic> data) {
    return PeriodSlot(
      period: (data['period'] as num?)?.toInt() ?? 0,
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period,
        'startTime': startTime,
        'endTime': endTime,
        'classId': classId,
        'subject': subject,
        'teacherName': teacherName,
      };

  PeriodSlot copyWith({
    int? period,
    String? startTime,
    String? endTime,
    String? classId,
    String? subject,
    String? teacherName,
  }) =>
      PeriodSlot(
        period: period ?? this.period,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        classId: classId ?? this.classId,
        subject: subject ?? this.subject,
        teacherName: teacherName ?? this.teacherName,
      );
}

class ScheduleModel {
  final String id;
  final String grade;
  final String section;
  final int dayOfWeek; // 1=Monday ... 5=Friday
  final List<PeriodSlot> periods;
  final String createdBy;
  final DateTime? updatedAt;

  const ScheduleModel({
    this.id = '',
    required this.grade,
    required this.section,
    required this.dayOfWeek,
    this.periods = const [],
    this.createdBy = '',
    this.updatedAt,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> data) {
    return ScheduleModel(
      id: data['id'] as String? ?? '',
      grade: data['grade'] as String? ?? '',
      section: data['section'] as String? ?? '',
      dayOfWeek: (data['dayOfWeek'] as num?)?.toInt() ?? 1,
      periods: (data['periods'] as List<dynamic>?)
              ?.map((p) => PeriodSlot.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      createdBy: data['createdBy'] as String? ?? '',
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'] as String)
          : null,
    );
  }

  ScheduleModel copyWith({
    String? id,
    String? grade,
    String? section,
    int? dayOfWeek,
    List<PeriodSlot>? periods,
    String? createdBy,
    DateTime? updatedAt,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      periods: periods ?? this.periods,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'grade': grade,
        'section': section,
        'dayOfWeek': dayOfWeek,
        'periods': periods.map((p) => p.toJson()).toList(),
        'createdBy': createdBy,
      };

  static const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  static const dayNamesFull = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday'
  ];

  String get dayName =>
      dayOfWeek >= 1 && dayOfWeek <= 5 ? dayNames[dayOfWeek] : '';
  String get dayNameFull =>
      dayOfWeek >= 1 && dayOfWeek <= 5 ? dayNamesFull[dayOfWeek] : '';
}
