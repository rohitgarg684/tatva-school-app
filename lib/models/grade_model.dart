class GradeModel {
  final String id;
  final String studentUid;
  final String studentName;
  final String classId;
  final String subject;
  final String assessmentName;
  final double score;
  final double total;
  final String teacherUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GradeModel({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.classId,
    required this.subject,
    required this.assessmentName,
    required this.score,
    required this.total,
    required this.teacherUid,
    this.createdAt,
    this.updatedAt,
  });

  double get percentage => total > 0 ? (score / total) * 100 : 0;

  factory GradeModel.fromJson(Map<String, dynamic> data) {
    return GradeModel(
      id: data['id'] as String? ?? '',
      studentUid: data['studentUid'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      assessmentName: data['assessmentName'] as String? ?? '',
      score: (data['score'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      teacherUid: data['teacherUid'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'] as String)
          : null,
    );
  }

  GradeModel copyWith({
    String? id,
    String? studentUid,
    String? studentName,
    String? classId,
    String? subject,
    String? assessmentName,
    double? score,
    double? total,
    String? teacherUid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GradeModel(
      id: id ?? this.id,
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      subject: subject ?? this.subject,
      assessmentName: assessmentName ?? this.assessmentName,
      score: score ?? this.score,
      total: total ?? this.total,
      teacherUid: teacherUid ?? this.teacherUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentUid': studentUid,
      'studentName': studentName,
      'classId': classId,
      'subject': subject,
      'assessmentName': assessmentName,
      'score': score,
      'total': total,
      'teacherUid': teacherUid,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}
