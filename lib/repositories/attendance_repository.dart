import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';
import '../models/attendance_record.dart';

class AttendanceRepository extends BaseRepository {
  CollectionReference get _attendance => db.collection('attendance');

  Future<String?> mark(AttendanceRecord record) async {
    try {
      // Upsert by student+date: use composite doc ID
      final docId = '${record.studentUid}_${record.date}';
      await _attendance.doc(docId).set(record.toMap());
      return docId;
    } catch (_) {
      return null;
    }
  }

  Future<List<AttendanceRecord>> fetchByClassAndDate(
      String classId, String date) async {
    try {
      final snap = await _attendance
          .where('classId', isEqualTo: classId)
          .where('date', isEqualTo: date)
          .get();
      return snap.docs.map((d) => AttendanceRecord.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<AttendanceRecord>> fetchByStudent(String studentUid,
      {int limit = 60}) async {
    try {
      final snap = await _attendance
          .where('studentUid', isEqualTo: studentUid)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => AttendanceRecord.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<AttendanceRecord>> fetchByStudentInRange(
      String studentUid, String startDate, String endDate) async {
    try {
      final snap = await _attendance
          .where('studentUid', isEqualTo: studentUid)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();
      return snap.docs.map((d) => AttendanceRecord.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }
}
