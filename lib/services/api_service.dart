import 'package:cloud_functions/cloud_functions.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  HttpsCallable _callable(String name) {
    return _functions.httpsCallable(
      name,
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
  }

  Future<Map<String, dynamic>> getStudentDashboard(String uid) async {
    final result = await _callable('getStudentDashboard').call({'uid': uid});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> getTeacherDashboard(String uid) async {
    final result = await _callable('getTeacherDashboard').call({'uid': uid});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> getParentDashboard(String uid) async {
    final result = await _callable('getParentDashboard').call({'uid': uid});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> getPrincipalDashboard(String uid) async {
    final result = await _callable('getPrincipalDashboard').call({'uid': uid});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> toggleStoryLike(String storyId) async {
    final result =
        await _callable('toggleStoryLike').call({'storyId': storyId});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> submitHomework(String homeworkId) async {
    final result =
        await _callable('submitHomework').call({'homeworkId': homeworkId});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> markContentCompleted(String contentId) async {
    final result =
        await _callable('markContentCompleted').call({'contentId': contentId});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> castVote(String voteId, String choice) async {
    final result =
        await _callable('castVote').call({'voteId': voteId, 'choice': choice});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> closeVote(String voteId) async {
    final result = await _callable('closeVote').call({'voteId': voteId});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> markAttendanceBatch(
      List<Map<String, dynamic>> records) async {
    final result =
        await _callable('markAttendance').call({'records': records});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> awardBehaviorPoint({
    required String studentUid,
    required String classId,
    required String categoryId,
    String studentName = '',
    int points = 1,
    String note = '',
  }) async {
    final result = await _callable('awardBehaviorPoint').call({
      'studentUid': studentUid,
      'studentName': studentName,
      'classId': classId,
      'categoryId': categoryId,
      'points': points,
      'note': note,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
