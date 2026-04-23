import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ClassModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      teacherUid: data['teacherUid'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
      teacherEmail: data['teacherEmail'] as String? ?? '',
      classCode: data['classCode'] as String? ?? '',
      studentUids: List<String>.from(data['studentUids'] ?? []),
      parentUids: List<String>.from(data['parentUids'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
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
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
