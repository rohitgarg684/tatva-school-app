/// Strongly-typed child information stored on a parent's user document.
class ChildInfo {
  final String childName;
  final String classId;
  final String className;
  final String subject;
  final String teacherName;
  final String teacherUid;
  final String teacherEmail;

  const ChildInfo({
    required this.childName,
    this.classId = '',
    this.className = '',
    this.subject = '',
    this.teacherName = '',
    this.teacherUid = '',
    this.teacherEmail = '',
  });

  factory ChildInfo.fromMap(Map<String, dynamic> data) {
    return ChildInfo(
      childName: data['childName'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      className: data['className'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
      teacherUid: data['teacherUid'] as String? ?? '',
      teacherEmail: data['teacherEmail'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childName': childName,
      'classId': classId,
      'className': className,
      'subject': subject,
      'teacherName': teacherName,
      'teacherUid': teacherUid,
      'teacherEmail': teacherEmail,
    };
  }
}
