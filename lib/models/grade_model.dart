import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory GradeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GradeModel(
      id: doc.id,
      studentUid: data['studentUid'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      assessmentName: data['assessmentName'] as String? ?? '',
      score: (data['score'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      teacherUid: data['teacherUid'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

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

  Map<String, dynamic> toMap() {
    return {
      'studentUid': studentUid,
      'studentName': studentName,
      'classId': classId,
      'subject': subject,
      'assessmentName': assessmentName,
      'score': score,
      'total': total,
      'teacherUid': teacherUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
