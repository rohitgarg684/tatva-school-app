import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory BehaviorPoint.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BehaviorPoint(
      id: doc.id,
      studentUid: data['studentUid'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      points: (data['points'] as num?)?.toInt() ?? 0,
      awardedBy: data['awardedBy'] as String? ?? '',
      awardedByName: data['awardedByName'] as String? ?? '',
      note: data['note'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentUid': studentUid,
      'studentName': studentName,
      'classId': classId,
      'categoryId': categoryId,
      'points': points,
      'awardedBy': awardedBy,
      'awardedByName': awardedByName,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
