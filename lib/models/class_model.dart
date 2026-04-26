class ClassModel {
  final String id;
  final String name;
  final String subject;
  final String grade;
  final String section;
  final String teacherUid;
  final String teacherName;
  final String teacherEmail;
  final String classCode;
  final List<String> studentUids;
  final List<String> parentUids;
  final DateTime? createdAt;

  const ClassModel({
    required this.id,
    required this.name,
    required this.subject,
    this.grade = '',
    this.section = '',
    required this.teacherUid,
    required this.teacherName,
    required this.teacherEmail,
    required this.classCode,
    this.studentUids = const [],
    this.parentUids = const [],
    this.createdAt,
  });

  factory ClassModel.empty() => const ClassModel(
      id: '', name: '', subject: '', teacherUid: '',
      teacherName: '', teacherEmail: '', classCode: '');

  factory ClassModel.fromJson(Map<String, dynamic> data) {
    return ClassModel(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      grade: data['grade'] as String? ?? '',
      section: data['section'] as String? ?? '',
      teacherUid: data['teacherUid'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
      teacherEmail: data['teacherEmail'] as String? ?? '',
      classCode: data['classCode'] as String? ?? '',
      studentUids: List<String>.from(data['studentUids'] ?? []),
      parentUids: List<String>.from(data['parentUids'] ?? []),
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  ClassModel copyWith({
    String? id,
    String? name,
    String? subject,
    String? grade,
    String? section,
    String? teacherUid,
    String? teacherName,
    String? teacherEmail,
    String? classCode,
    List<String>? studentUids,
    List<String>? parentUids,
    DateTime? createdAt,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      teacherUid: teacherUid ?? this.teacherUid,
      teacherName: teacherName ?? this.teacherName,
      teacherEmail: teacherEmail ?? this.teacherEmail,
      classCode: classCode ?? this.classCode,
      studentUids: studentUids ?? this.studentUids,
      parentUids: parentUids ?? this.parentUids,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'subject': subject,
      'teacherUid': teacherUid,
      'teacherName': teacherName,
      'teacherEmail': teacherEmail,
      'classCode': classCode,
      'studentUids': studentUids,
      'parentUids': parentUids,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
