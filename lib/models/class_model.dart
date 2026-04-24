class ClassModel {
  final String id;
  final String name;
  final String subject;
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
    required this.teacherUid,
    required this.teacherName,
    required this.teacherEmail,
    required this.classCode,
    this.studentUids = const [],
    this.parentUids = const [],
    this.createdAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> data) {
    return ClassModel(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'subject': subject,
      'teacherUid': teacherUid,
      'teacherName': teacherName,
      'teacherEmail': teacherEmail,
      'classCode': classCode,
      'studentUids': studentUids,
      'parentUids': parentUids,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}
