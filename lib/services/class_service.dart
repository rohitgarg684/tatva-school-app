import 'dart:math';
import '../models/child_info.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../repositories/class_repository.dart';
import '../repositories/student_repository.dart';
import '../repositories/user_repository.dart';

class ClassService {
  final ClassRepository _classRepo;
  final UserRepository _userRepo;
  final StudentRepository _studentRepo;

  ClassService({
    ClassRepository? classRepo,
    UserRepository? userRepo,
    StudentRepository? studentRepo,
  })  : _classRepo = classRepo ?? ClassRepository(),
        _userRepo = userRepo ?? UserRepository(),
        _studentRepo = studentRepo ?? StudentRepository();

  Future<String> generateUniqueCode(String subject) async {
    final subjectPart = subject
        .replaceAll(' ', '')
        .toUpperCase()
        .substring(0, min(4, subject.replaceAll(' ', '').length));

    const maxAttempts = 10;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final rand = Random().nextInt(9000) + 1000;
      final code = '$subjectPart$rand';
      if (await _classRepo.isCodeUnique(code)) return code;
    }
    final ts = DateTime.now().millisecondsSinceEpoch % 100000;
    return '$subjectPart$ts';
  }

  Future<ClassModel?> createClass({
    required String name,
    required String subject,
  }) async {
    try {
      final user = await _userRepo.getUser();
      if (user == null) return null;

      final code = await generateUniqueCode(subject);

      final model = ClassModel(
        id: '',
        name: name,
        subject: subject,
        teacherUid: user.uid,
        teacherName: user.name,
        teacherEmail: user.email,
        classCode: code,
      );

      return await _classRepo.createClass(model);
    } catch (_) {
      return null;
    }
  }

  /// Joins a user to a class by code. Used by both AuthService and ClassService.
  Future<String?> joinClassByCode({
    required String classCode,
    required UserRole role,
    String? childName,
  }) async {
    try {
      final classModel = await _classRepo.findByCode(classCode);
      if (classModel == null) {
        return 'Class code not found. Please check and try again.';
      }

      final uid = _classRepo.currentUid;

      if (role == UserRole.student) {
        await _classRepo.addStudentToClass(classModel.id, uid);
        await _userRepo.updateUser(uid, {
          'classIds': [classModel.id],
        });
      } else if (role == UserRole.parent) {
        await _classRepo.addParentToClass(classModel.id, uid);
        final child = ChildInfo(
          childName: childName ?? '',
          classId: classModel.id,
          className: classModel.name,
          subject: classModel.subject,
          teacherName: classModel.teacherName,
          teacherUid: classModel.teacherUid,
          teacherEmail: classModel.teacherEmail,
        );
        await _userRepo.updateUser(uid, {
          'classIds': [classModel.id],
          'children': [child.toMap()],
        });
      }

      return null;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<List<UserModel>> getStudentsInClass(String classId) async {
    final classModel = await _classRepo.getClass(classId);
    if (classModel == null) return [];
    return _userRepo.getUsersByIds(classModel.studentUids);
  }

  Future<List<UserModel>> getParentsInClass(String classId) async {
    final classModel = await _classRepo.getClass(classId);
    if (classModel == null) return [];
    return _userRepo.getUsersByIds(classModel.parentUids);
  }

  /// Creates a student record and optionally assigns to a class.
  Future<StudentModel?> enrollStudent({
    required String name,
    String rollNumber = '',
    String grade = '',
    String section = '',
    String parentName = '',
    String parentPhone = '',
    String? classId,
  }) async {
    try {
      final enrollerUid = _classRepo.currentUid;
      final classIds = classId != null ? [classId] : <String>[];

      final model = StudentModel(
        id: '',
        name: name,
        rollNumber: rollNumber,
        grade: grade,
        section: section,
        parentName: parentName,
        parentPhone: parentPhone,
        classIds: classIds,
        enrolledBy: enrollerUid,
      );

      final student = await _studentRepo.add(model);
      if (student == null) return null;

      if (classId != null) {
        await _classRepo.addStudentToClass(classId, student.id);
      }

      return student;
    } catch (_) {
      return null;
    }
  }

  /// Adds an existing student record to a class (both sides).
  Future<bool> addStudentToClassById({
    required String classId,
    required String studentId,
  }) async {
    try {
      await _classRepo.addStudentToClass(classId, studentId);
      await _studentRepo.addClassToStudent(studentId, classId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<StudentModel>> getStudentRecordsInClass(String classId) {
    return _studentRepo.getByClass(classId);
  }

  Future<List<StudentModel>> getAllStudentRecords() {
    return _studentRepo.getAll();
  }

  /// Client-side search across all student records.
  Future<List<StudentModel>> searchStudentRecords(String query) async {
    if (query.trim().isEmpty) return getAllStudentRecords();
    final lower = query.trim().toLowerCase();
    final all = await _studentRepo.getAll();
    return all
        .where((s) =>
            s.name.toLowerCase().contains(lower) ||
            s.rollNumber.toLowerCase().contains(lower))
        .toList();
  }
}
