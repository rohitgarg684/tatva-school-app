class BehaviorPoint {
  final String id;
  final String studentUid;
  final String studentName;
  final String classId;
  final String categoryId;
  final int points;
  final String awardedBy;
  final String awardedByName;
  final String note;
  final DateTime? createdAt;

  const BehaviorPoint({
    this.id = '',
    required this.studentUid,
    required this.studentName,
    required this.classId,
    required this.categoryId,
    required this.points,
    required this.awardedBy,
    required this.awardedByName,
    this.note = '',
    this.createdAt,
  });

  bool get isPositive => points > 0;

  factory BehaviorPoint.fromJson(Map<String, dynamic> data) {
    return BehaviorPoint(
      id: data['id'] as String? ?? '',
      studentUid: data['studentUid'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      points: (data['points'] as num?)?.toInt() ?? 0,
      awardedBy: data['awardedBy'] as String? ?? '',
      awardedByName: data['awardedByName'] as String? ?? '',
      note: data['note'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  BehaviorPoint copyWith({
    String? id,
    String? studentUid,
    String? studentName,
    String? classId,
    String? categoryId,
    int? points,
    String? awardedBy,
    String? awardedByName,
    String? note,
    DateTime? createdAt,
  }) {
    return BehaviorPoint(
      id: id ?? this.id,
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      categoryId: categoryId ?? this.categoryId,
      points: points ?? this.points,
      awardedBy: awardedBy ?? this.awardedBy,
      awardedByName: awardedByName ?? this.awardedByName,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentUid': studentUid,
      'studentName': studentName,
      'classId': classId,
      'categoryId': categoryId,
      'points': points,
      'awardedBy': awardedBy,
      'awardedByName': awardedByName,
      'note': note,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
