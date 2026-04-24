import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkModel {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String classId;
  final String className;
  final String teacherUid;
  final String teacherName;
  final String dueDate;
  final List<String> submittedBy;
  final DateTime? createdAt;

  const HomeworkModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.subject,
    required this.classId,
    this.className = '',
    this.teacherUid = '',
    this.teacherName = '',
    required this.dueDate,
    this.submittedBy = const [],
    this.createdAt,
  });

  bool isSubmittedBy(String uid) => submittedBy.contains(uid);

  int get submissionCount => submittedBy.length;

  factory HomeworkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return HomeworkModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      className: data['className'] as String? ?? '',
      teacherUid: data['teacherUid'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
      dueDate: data['dueDate'] as String? ?? '',
      submittedBy: List<String>.from(data['submittedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory HomeworkModel.fromJson(Map<String, dynamic> data) {
    return HomeworkModel(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      className: data['className'] as String? ?? '',
      teacherUid: data['teacherUid'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
      dueDate: data['dueDate'] as String? ?? '',
      submittedBy: List<String>.from(data['submittedBy'] ?? []),
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'subject': subject,
      'classId': classId,
      'className': className,
      'teacherUid': teacherUid,
      'teacherName': teacherName,
      'dueDate': dueDate,
      'submittedBy': submittedBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
