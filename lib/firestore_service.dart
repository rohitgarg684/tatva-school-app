import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ─── CLASS CODE GENERATOR ──────────────────────────────────────────────────
  String generateClassCode(String subject, String className) {
    final subjectPart = subject
        .replaceAll(' ', '')
        .toUpperCase()
        .substring(0, min(4, subject.replaceAll(' ', '').length));
    final rand = Random().nextInt(900) + 100;
    return '$subjectPart$rand';
  }

  // ─── CREATE CLASS (Teacher) ────────────────────────────────────────────────
  Future<Map<String, dynamic>?> createClass({
    required String name,
    required String subject,
  }) async {
    try {
      final userDoc = await _db.collection('users').doc(_uid).get();
      final userData = userDoc.data()!;
      final classCode = generateClassCode(subject, name);

      final classRef = await _db.collection('classes').add({
        'name': name,
        'subject': subject,
        'teacherUid': _uid,
        'teacherName': userData['name'] ?? '',
        'teacherEmail': userData['email'] ?? '',
        'classCode': classCode,
        'studentUids': [],
        'parentUids': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'classId': classRef.id, 'classCode': classCode};
    } catch (e) {
      return null;
    }
  }

  // ─── GET TEACHER'S CLASSES ─────────────────────────────────────────────────
  Stream<QuerySnapshot> getTeacherClasses() {
    return _db
        .collection('classes')
        .where('teacherUid', isEqualTo: _uid)
        .snapshots();
  }

  // ─── JOIN CLASS BY CODE (Student or Parent) ────────────────────────────────
  Future<String?> joinClassByCode({
    required String classCode,
    required String role,
    String? childName,
  }) async {
    try {
      final query = await _db
          .collection('classes')
          .where('classCode', isEqualTo: classCode.trim().toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return 'Class code not found. Please check and try again.';
      }

      final classDoc = query.docs.first;
      final classId = classDoc.id;
      final classData = classDoc.data() as Map<String, dynamic>;

      if (role == 'Student') {
        await classDoc.reference.update({
          'studentUids': FieldValue.arrayUnion([_uid]),
        });
        await _db.collection('users').doc(_uid).update({
          'classIds': FieldValue.arrayUnion([classId]),
          'classCode': classCode.trim().toUpperCase(),
          'className': classData['name'] ?? '',
          'subject': classData['subject'] ?? '',
          'teacherName': classData['teacherName'] ?? '',
          'teacherUid': classData['teacherUid'] ?? '',
        });
      } else if (role == 'Parent') {
        await classDoc.reference.update({
          'parentUids': FieldValue.arrayUnion([_uid]),
        });
        final childEntry = {
          'classId': classId,
          'classCode': classCode.trim().toUpperCase(),
          'childName': childName ?? '',
          'className': classData['name'] ?? '',
          'subject': classData['subject'] ?? '',
          'teacherName': classData['teacherName'] ?? '',
          'teacherUid': classData['teacherUid'] ?? '',
          'teacherEmail': classData['teacherEmail'] ?? '',
        };
        await _db.collection('users').doc(_uid).update({
          'classIds': FieldValue.arrayUnion([classId]),
          'children': FieldValue.arrayUnion([childEntry]),
        });
      }

      return null; // null = success
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  // ─── GET STUDENTS IN A CLASS ───────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getStudentsInClass(String classId) async {
    try {
      final classDoc = await _db.collection('classes').doc(classId).get();
      final studentUids =
          List<String>.from(classDoc.data()?['studentUids'] ?? []);
      if (studentUids.isEmpty) return [];

      final students = await Future.wait(
        studentUids.map((uid) => _db.collection('users').doc(uid).get()),
      );

      return students
          .where((doc) => doc.exists)
          .map((doc) => {'uid': doc.id, ...doc.data()!})
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ─── ENTER GRADE (Teacher) ─────────────────────────────────────────────────
  Future<bool> enterGrade({
    required String studentUid,
    required String studentName,
    required String classId,
    required String subject,
    required String assessmentName,
    required double score,
    required double total,
  }) async {
    try {
      final existing = await _db
          .collection('grades')
          .where('studentUid', isEqualTo: studentUid)
          .where('classId', isEqualTo: classId)
          .where('assessmentName', isEqualTo: assessmentName)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.update({
          'score': score,
          'total': total,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _db.collection('grades').add({
          'studentUid': studentUid,
          'studentName': studentName,
          'classId': classId,
          'subject': subject,
          'assessmentName': assessmentName,
          'score': score,
          'total': total,
          'teacherUid': _uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── GET GRADES FOR STUDENT ────────────────────────────────────────────────
  Stream<QuerySnapshot> getStudentGrades(String studentUid) {
    return _db
        .collection('grades')
        .where('studentUid', isEqualTo: studentUid)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // ─── GET GRADES FOR CLASS (Teacher view) ──────────────────────────────────
  Stream<QuerySnapshot> getClassGrades(String classId) {
    return _db
        .collection('grades')
        .where('classId', isEqualTo: classId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // ─── POST ANNOUNCEMENT ─────────────────────────────────────────────────────
  Future<bool> postAnnouncement({
    required String title,
    required String body,
    required String audience,
    List<String> classIds = const [],
  }) async {
    try {
      final userDoc = await _db.collection('users').doc(_uid).get();
      await _db.collection('announcements').add({
        'title': title,
        'body': body,
        'audience': audience,
        'classIds': classIds,
        'createdBy': _uid,
        'createdByName': userDoc.data()?['name'] ?? '',
        'createdByRole': userDoc.data()?['role'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── GET ANNOUNCEMENTS ─────────────────────────────────────────────────────
  Stream<QuerySnapshot> getAnnouncements() {
    return _db
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  // ─── CREATE VOTE ───────────────────────────────────────────────────────────
  Future<bool> createVote({
    required String question,
    required String type,
  }) async {
    try {
      final userDoc = await _db.collection('users').doc(_uid).get();
      await _db.collection('votes').add({
        'question': question,
        'type': type,
        'createdBy': _uid,
        'createdByName': userDoc.data()?['name'] ?? '',
        'createdByRole': userDoc.data()?['role'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'active': true,
        'votes': {'school': 0, 'no_school': 0, 'undecided': 0},
        'voters': [],
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── CAST VOTE ─────────────────────────────────────────────────────────────
  Future<bool> castVote({
    required String voteId,
    required String option,
  }) async {
    try {
      await _db.collection('votes').doc(voteId).update({
        'votes.$option': FieldValue.increment(1),
        'voters': FieldValue.arrayUnion([_uid]),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── GET ACTIVE VOTES ──────────────────────────────────────────────────────
  Stream<QuerySnapshot> getActiveVotes() {
    return _db
        .collection('votes')
        .where('active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ─── CLOSE VOTE ────────────────────────────────────────────────────────────
  Future<bool> closeVote(String voteId) async {
    try {
      await _db.collection('votes').doc(voteId).update({'active': false});
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── GET USER DATA ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserData([String? uid]) async {
    try {
      final doc = await _db.collection('users').doc(uid ?? _uid).get();
      return doc.exists ? {'uid': doc.id, ...doc.data()!} : null;
    } catch (e) {
      return null;
    }
  }

  // ─── GET ALL PARENTS ───────────────────────────────────────────────────────
  Stream<QuerySnapshot> getAllParents() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'Parent')
        .snapshots();
  }

  // ─── GET ALL TEACHERS ──────────────────────────────────────────────────────
  Stream<QuerySnapshot> getAllTeachers() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'Teacher')
        .snapshots();
  }

  // ─── GET PARENTS IN CLASS ──────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getParentsInClass(String classId) async {
    try {
      final classDoc = await _db.collection('classes').doc(classId).get();
      final parentUids =
          List<String>.from(classDoc.data()?['parentUids'] ?? []);
      if (parentUids.isEmpty) return [];

      final parents = await Future.wait(
        parentUids.map((uid) => _db.collection('users').doc(uid).get()),
      );

      return parents
          .where((doc) => doc.exists)
          .map((doc) => {'uid': doc.id, ...doc.data()!})
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ─── GET USER CLASSES ──────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getUserClasses() async {
    try {
      final userDoc = await _db.collection('users').doc(_uid).get();
      final classIds = List<String>.from(userDoc.data()?['classIds'] ?? []);
      if (classIds.isEmpty) return [];

      final classes = await Future.wait(
        classIds.map((id) => _db.collection('classes').doc(id).get()),
      );

      return classes
          .where((doc) => doc.exists)
          .map((doc) => {'classId': doc.id, ...doc.data()!})
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ─── SAVE FCM TOKEN ────────────────────────────────────────────────────────
  Future<void> saveFcmToken(String token) async {
    try {
      await _db.collection('users').doc(_uid).update({'fcmToken': token});
    } catch (e) {}
  }
}
