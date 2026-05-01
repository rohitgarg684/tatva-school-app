class StudentModel {
  final String id;
  final String name;
  final String rollNumber;
  final String grade;
  final String section;
  final String parentName;
  final String parentPhone;
  final String parentEmail;
  final List<String> classIds;
  final String enrolledBy;
  final DateTime? createdAt;

  const StudentModel({
    required this.id,
    required this.name,
    this.rollNumber = '',
    this.grade = '',
    this.section = '',
    this.parentName = '',
    this.parentPhone = '',
    this.parentEmail = '',
    this.classIds = const [],
    this.enrolledBy = '',
    this.createdAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> data) {
    return StudentModel(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      rollNumber: data['rollNumber'] as String? ?? '',
      grade: data['grade'] as String? ?? '',
      section: data['section'] as String? ?? '',
      parentName: data['parentName'] as String? ?? '',
      parentPhone: data['parentPhone'] as String? ?? '',
      parentEmail: data['parentEmail'] as String? ?? '',
      classIds: List<String>.from(data['classIds'] ?? []),
      enrolledBy: data['enrolledBy'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rollNumber': rollNumber,
      'grade': grade,
      'section': section,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'parentEmail': parentEmail,
      'classIds': classIds,
      'enrolledBy': enrolledBy,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  StudentModel copyWith({
    String? name,
    String? rollNumber,
    String? grade,
    String? section,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    List<String>? classIds,
    String? enrolledBy,
  }) {
    return StudentModel(
      id: id,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      classIds: classIds ?? this.classIds,
      enrolledBy: enrolledBy ?? this.enrolledBy,
      createdAt: createdAt,
    );
  }

  String get displayGradeSection {
    if (grade.isEmpty && section.isEmpty) return '';
    if (section.isEmpty) return 'Grade $grade';
    return 'Grade $grade - $section';
  }
}
