import 'api_service.dart';

class ClassService {
  final ApiService _api;

  ClassService({ApiService? api}) : _api = api ?? ApiService();

  Future<Map<String, dynamic>?> createClass({
    required String name,
    required String subject,
    required String classCode,
  }) async {
    try {
      return await _api.createClass(
        name: name,
        subject: subject,
        classCode: classCode,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> joinClassByCode({
    required String classCode,
    String? childName,
  }) async {
    try {
      await _api.joinClass(classCode: classCode, childName: childName);
      return null;
    } catch (e) {
      return 'Could not join class: $e';
    }
  }

  Future<Map<String, dynamic>?> enrollStudent({
    required String name,
    String rollNumber = '',
    String grade = '',
    String section = '',
    String parentName = '',
    String parentPhone = '',
    List<String> classIds = const [],
  }) async {
    try {
      return await _api.enrollStudent(
        name: name,
        rollNumber: rollNumber,
        grade: grade,
        section: section,
        parentName: parentName,
        parentPhone: parentPhone,
        classIds: classIds,
      );
    } catch (_) {
      return null;
    }
  }
}
