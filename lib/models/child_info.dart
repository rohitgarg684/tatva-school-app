/// Strongly-typed child information stored on a parent's user document.
class ChildInfo {
  final String childName;
  final String childUid;
  final String classId;
  final String className;
  final String subject;
  final String teacherName;
  final String teacherUid;
  final String teacherEmail;

  const ChildInfo({
    required this.childName,
    this.childUid = '',
    this.classId = '',
    this.className = '',
    this.subject = '',
    this.teacherName = '',
    this.teacherUid = '',
    this.teacherEmail = '',
  });

  factory ChildInfo.fromJson(Map<String, dynamic> data) {
    return ChildInfo(
      childName: data['childName'] as String? ?? '',
      childUid: data['childUid'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      className: data['className'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
      teacherUid: data['teacherUid'] as String? ?? '',
      teacherEmail: data['teacherEmail'] as String? ?? '',
    );
  }

  ChildInfo copyWith({
    String? childName,
    String? childUid,
    String? classId,
    String? className,
    String? subject,
    String? teacherName,
    String? teacherUid,
    String? teacherEmail,
  }) {
    return ChildInfo(
      childName: childName ?? this.childName,
      childUid: childUid ?? this.childUid,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subject: subject ?? this.subject,
      teacherName: teacherName ?? this.teacherName,
      teacherUid: teacherUid ?? this.teacherUid,
      teacherEmail: teacherEmail ?? this.teacherEmail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'childName': childName,
      'childUid': childUid,
      'classId': classId,
      'className': className,
      'subject': subject,
      'teacherName': teacherName,
      'teacherUid': teacherUid,
      'teacherEmail': teacherEmail,
    };
  }
}
