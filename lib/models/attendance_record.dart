import 'attendance_status.dart';

class AttendanceRecord {
  final String id;
  final String studentUid;
  final String studentName;
  final String date; // YYYY-MM-DD
  final AttendanceStatus status;
  final String markedBy;
  final DateTime? createdAt;

  const AttendanceRecord({
    this.id = '',
    required this.studentUid,
    required this.studentName,
    required this.date,
    required this.status,
    required this.markedBy,
    this.createdAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> data) {
    return AttendanceRecord(
      id: data['id'] as String? ?? '',
      studentUid: data['studentUid'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      date: data['date'] as String? ?? '',
      status: AttendanceStatus.fromString(data['status'] as String? ?? ''),
      markedBy: data['markedBy'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  AttendanceRecord copyWith({
    String? id,
    String? studentUid,
    String? studentName,
    String? date,
    AttendanceStatus? status,
    String? markedBy,
    DateTime? createdAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      date: date ?? this.date,
      status: status ?? this.status,
      markedBy: markedBy ?? this.markedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentUid': studentUid,
      'studentName': studentName,
      'date': date,
      'status': status.label,
      'markedBy': markedBy,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
