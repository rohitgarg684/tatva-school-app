import 'dart:math';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../repositories/class_repository.dart';
import '../repositories/user_repository.dart';

class ClassService {
  final ClassRepository _classRepo;
  final UserRepository _userRepo;

  ClassService({
    ClassRepository? classRepo,
    UserRepository? userRepo,
  })  : _classRepo = classRepo ?? ClassRepository(),
        _userRepo = userRepo ?? UserRepository();

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

  Future<String?> joinClassByCode({
    required String classCode,
    required String role,
    String? childName,
  }) async {
    try {
      final classModel = await _classRepo.findByCode(classCode);
      if (classModel == null) {
        return 'Class code not found. Please check and try again.';
      }

      final uid = _classRepo.currentUid;

      if (role == 'Student') {
        await _classRepo.addStudentToClass(classModel.id, uid);
        await _userRepo.updateUser(uid, {
          'classIds': [classModel.id],
          'classCode': classModel.classCode,
          'className': classModel.name,
          'subject': classModel.subject,
          'teacherName': classModel.teacherName,
          'teacherUid': classModel.teacherUid,
        });
      } else if (role == 'Parent') {
        await _classRepo.addParentToClass(classModel.id, uid);
        await _userRepo.updateUser(uid, {
          'classIds': [classModel.id],
          'children': [
            {
              'classId': classModel.id,
              'classCode': classModel.classCode,
              'childName': childName ?? '',
              'className': classModel.name,
              'subject': classModel.subject,
              'teacherName': classModel.teacherName,
              'teacherUid': classModel.teacherUid,
              'teacherEmail': classModel.teacherEmail,
            }
          ],
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
}
