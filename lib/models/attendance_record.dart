import 'package:cloud_firestore/cloud_firestore.dart';
import 'attendance_status.dart';

class AttendanceRecord {
  final String id;
  final String studentUid;
  final String studentName;
  final String classId;
  final String date; // YYYY-MM-DD
  final AttendanceStatus status;
  final String markedBy;
  final DateTime? createdAt;

  const AttendanceRecord({
    this.id = '',
    required this.studentUid,
    required this.studentName,
    required this.classId,
    required this.date,
    required this.status,
    required this.markedBy,
    this.createdAt,
  });

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AttendanceRecord(
      id: doc.id,
      studentUid: data['studentUid'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      date: data['date'] as String? ?? '',
      status: AttendanceStatus.fromString(data['status'] as String? ?? ''),
      markedBy: data['markedBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> data) {
    return AttendanceRecord(
      id: data['id'] as String? ?? '',
      studentUid: data['studentUid'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      date: data['date'] as String? ?? '',
      status: AttendanceStatus.fromString(data['status'] as String? ?? ''),
      markedBy: data['markedBy'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentUid': studentUid,
      'studentName': studentName,
      'classId': classId,
      'date': date,
      'status': status.label,
      'markedBy': markedBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
