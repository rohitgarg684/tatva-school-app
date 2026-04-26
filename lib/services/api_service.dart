import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

String _mimeFromFilename(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  const map = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'pdf': 'application/pdf',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  };
  return map[ext] ?? 'application/octet-stream';
}

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  static const _cloudRunUrl =
      'https://tatva-api-859841471446.us-central1.run.app';

  String get _baseUrl {
    if (kIsWeb) {
      return '/api';
    }
    return '$_cloudRunUrl/api';
  }

  Future<String> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');
    return await user.getIdToken() ?? '';
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final headers = await _authHeaders();
    final response = await http
        .get(Uri.parse('$_baseUrl$path'), headers: headers)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final response = await http
        .post(Uri.parse('$_baseUrl$path'),
            headers: headers, body: json.encode(body))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _put(
      String path, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final response = await http
        .put(Uri.parse('$_baseUrl$path'),
            headers: headers, body: json.encode(body))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final headers = await _authHeaders();
    final response = await http
        .delete(Uri.parse('$_baseUrl$path'), headers: headers)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  // ─── Auth ─────────────────────────────────────────────────────────────

  /// Syncs the user's Firestore role into Firebase Auth custom claims.
  /// Call after login, then force-refresh the token.
  Future<void> syncClaims() async {
    await _post('/auth/sync-claims', {});
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
  }

  // ─── Dashboards ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStudentDashboard(String uid) =>
      _get('/dashboard/student/$uid');

  Future<Map<String, dynamic>> getTeacherDashboard(String uid) =>
      _get('/dashboard/teacher/$uid');

  Future<Map<String, dynamic>> getParentDashboard(String uid) =>
      _get('/dashboard/parent/$uid');

  Future<Map<String, dynamic>> getPrincipalDashboard(String uid) =>
      _get('/dashboard/principal/$uid');

  // ─── Actions ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> submitHomework(String homeworkId) =>
      _post('/homework/$homeworkId/submit', {});

  Future<Map<String, dynamic>> markContentCompleted(String contentId) =>
      _post('/content/$contentId/complete', {});

  Future<Map<String, dynamic>> castVote(String voteId, String choice) =>
      _post('/vote/$voteId/cast', {'choice': choice});

  Future<Map<String, dynamic>> closeVote(String voteId) =>
      _post('/vote/$voteId/close', {});

  Future<Map<String, dynamic>> markAttendanceBatch(
          List<Map<String, dynamic>> records) =>
      _post('/attendance', {'records': records});

  Future<Map<String, dynamic>> getAttendanceByDate(String date) =>
      _get('/attendance/$date');

  Future<Map<String, dynamic>> awardBehaviorPoint({
    required String studentUid,
    required String classId,
    required String categoryId,
    String studentName = '',
    int points = 1,
    String note = '',
  }) =>
      _post('/behavior-point', {
        'studentUid': studentUid,
        'studentName': studentName,
        'classId': classId,
        'categoryId': categoryId,
        'points': points,
        'note': note,
      });

  Future<Map<String, dynamic>> deleteBehaviorPoint(String id) =>
      _delete('/behavior-point/$id');

  // ─── File Upload ──────────────────────────────────────────────────────

  Future<String?> _uploadMultipart(
      String endpoint, Uint8List bytes, String classId, String fileName) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['classId'] = classId
        ..files.add(http.MultipartFile.fromBytes('file', bytes,
            filename: fileName));

      final response =
          await request.send().timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) return null;

      final body = await response.stream.bytesToString();
      final data = json.decode(body) as Map<String, dynamic>;
      return data['url'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadDocument(
          Uint8List bytes, String classId, String fileName) =>
      _uploadMultipart('/document/upload', bytes, classId, fileName);

  Future<List<Map<String, dynamic>>> uploadHomeworkFiles(
      String homeworkId, List<MapEntry<String, Uint8List>> files) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$_baseUrl/homework/$homeworkId/upload');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token';
      for (final entry in files) {
        final mime = _mimeFromFilename(entry.key);
        request.files.add(
            http.MultipartFile.fromBytes('files', entry.value,
                filename: entry.key,
                contentType: MediaType.parse(mime)));
      }
      final response =
          await request.send().timeout(const Duration(seconds: 120));
      if (response.statusCode != 200) return [];
      final body = await response.stream.bytesToString();
      final data = json.decode(body) as Map<String, dynamic>;
      return (data['uploaded'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> submitHomeworkFiles(
      String homeworkId,
      List<MapEntry<String, Uint8List>> files,
      {String note = ''}) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$_baseUrl/homework/$homeworkId/submit-files');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['note'] = note;
      for (final entry in files) {
        final mime = _mimeFromFilename(entry.key);
        request.files.add(
            http.MultipartFile.fromBytes('files', entry.value,
                filename: entry.key,
                contentType: MediaType.parse(mime)));
      }
      final response =
          await request.send().timeout(const Duration(seconds: 120));
      final body = await response.stream.bytesToString();
      return json.decode(body) as Map<String, dynamic>;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getHomeworkSubmissions(
      String homeworkId) async {
    final data = await _get('/homework/$homeworkId/submissions');
    return (data['submissions'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
  }

  Future<Map<String, dynamic>?> getMyHomeworkSubmission(
      String homeworkId) async {
    final data = await _get('/homework/$homeworkId/my-submission');
    return data['submission'] as Map<String, dynamic>?;
  }

  // ─── CRUD ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUser(String uid) => _get('/user/$uid');

  Future<List<Map<String, dynamic>>> getStudents() async {
    final data = await _get('/students');
    return (data['students'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
  }

  Future<Map<String, dynamic>> createUser({
    required String uid,
    required String name,
    required String email,
    required String role,
  }) =>
      _post('/user', {
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
      });

  Future<Map<String, dynamic>> createClass({
    required String name,
    required String subject,
    required String classCode,
  }) =>
      _post('/class', {
        'name': name,
        'subject': subject,
        'classCode': classCode,
      });

  Future<Map<String, dynamic>> deleteClass(String classId) =>
      _delete('/class/$classId');

  Future<Map<String, dynamic>> joinClass({
    required String classCode,
    String? childName,
  }) =>
      _post('/class/join', {
        'classCode': classCode,
        if (childName != null) 'childName': childName,
      });

  Future<Map<String, dynamic>> enrollStudent({
    required String name,
    String rollNumber = '',
    String grade = '',
    String section = '',
    String parentName = '',
    String parentPhone = '',
    List<String> classIds = const [],
  }) =>
      _post('/student/enroll', {
        'name': name,
        'rollNumber': rollNumber,
        'grade': grade,
        'section': section,
        'parentName': parentName,
        'parentPhone': parentPhone,
        'classIds': classIds,
      });

  Future<Map<String, dynamic>> createHomework({
    required String title,
    required String classId,
    String description = '',
    String subject = '',
    String className = '',
    String dueDate = '',
    List<Map<String, dynamic>> attachments = const [],
  }) =>
      _post('/homework', {
        'title': title,
        'classId': classId,
        'description': description,
        'subject': subject,
        'className': className,
        'dueDate': dueDate,
        'attachments': attachments,
      });

  Future<Map<String, dynamic>> deleteHomework(String id) =>
      _delete('/homework/$id');

  Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String body,
    List<String> grades = const [],
    List<Map<String, dynamic>> attachments = const [],
  }) =>
      _post('/announcement', {
        'title': title,
        'body': body,
        'grades': grades,
        'attachments': attachments,
      });

  Future<Map<String, dynamic>> toggleAnnouncementLike(String id) =>
      _post('/announcement/$id/like', {});

  Future<Map<String, dynamic>> updateAnnouncement(
    String id, {
    String? title,
    String? body,
    List<String>? grades,
    List<Map<String, dynamic>>? attachments,
  }) =>
      _put('/announcement/$id', {
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        if (grades != null) 'grades': grades,
        if (attachments != null) 'attachments': attachments,
      });

  Future<List<Map<String, dynamic>>> uploadAnnouncementFiles(
      List<Uint8List> files, List<String> fileNames) async {
    final headers = await _authHeaders();
    headers.remove('content-type');
    final request = http.MultipartRequest(
        'POST', Uri.parse('$_baseUrl/announcement/upload'));
    request.headers.addAll(headers);
    for (int i = 0; i < files.length; i++) {
      request.files.add(http.MultipartFile.fromBytes('files', files[i],
          filename: fileNames[i]));
    }
    final response =
        await http.Response.fromStream(await request.send());
    if (response.statusCode != 200) {
      throw Exception('Upload failed ${response.statusCode}: ${response.body}');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['attachments'] ?? []);
  }

  Future<Map<String, dynamic>> deleteAnnouncement(String id) =>
      _delete('/announcement/$id');

  Future<Map<String, dynamic>> createVote({required String question}) =>
      _post('/vote', {'question': question});

  Future<Map<String, dynamic>> enterGrade({
    required String studentUid,
    required String classId,
    required String subject,
    required String assessmentName,
    String studentName = '',
    double score = 0,
    double total = 100,
  }) =>
      _post('/grade', {
        'studentUid': studentUid,
        'classId': classId,
        'subject': subject,
        'assessmentName': assessmentName,
        'studentName': studentName,
        'score': score,
        'total': total,
      });

  Future<Map<String, dynamic>> deleteGrade(String id) =>
      _delete('/grade/$id');

  // ─── Test Titles ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> addTestTitle({
    required String title,
    String subject = '',
    double total = 100,
  }) =>
      _post('/test-title', {
        'title': title,
        'subject': subject,
        'total': total,
      });

  Future<Map<String, dynamic>> deleteTestTitle(String id) =>
      _delete('/test-title/$id');

  // ─── Messages ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMessages(
      String conversationId) async {
    final data = await _get('/messages/$conversationId');
    return (data['messages'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
  }

  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String receiverUid,
    required String text,
  }) =>
      _post('/messages', {
        'conversationId': conversationId,
        'receiverUid': receiverUid,
        'text': text,
      });

  Future<List<Map<String, dynamic>>> getGroupMessages(
      String groupId) async {
    final data = await _get('/group-messages/$groupId');
    return (data['messages'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
  }

  Future<Map<String, dynamic>> sendGroupMessage({
    required String groupId,
    required String text,
    String senderName = '',
  }) =>
      _post('/group-messages/$groupId', {
        'text': text,
        'senderName': senderName,
      });

  Future<Map<String, dynamic>> getWeeklyReport({
    required String studentUid,
    String? startDate,
    String? endDate,
  }) =>
      _get('/report/weekly?studentUid=$studentUid'
          '${startDate != null ? '&startDate=$startDate' : ''}'
          '${endDate != null ? '&endDate=$endDate' : ''}');

  // ─── Schedule ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSchedule(
      String grade, String section) async {
    final data = await _get('/schedule/$grade/$section');
    return (data['schedules'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
  }

  Future<Map<String, dynamic>> getScheduleWithCancellations(
      String grade, String section) async {
    return await _get('/schedule/$grade/$section');
  }

  Future<Map<String, dynamic>> upsertSchedule({
    required String grade,
    required String section,
    required int dayOfWeek,
    required List<Map<String, dynamic>> periods,
  }) =>
      _put('/schedule', {
        'grade': grade,
        'section': section,
        'dayOfWeek': dayOfWeek,
        'periods': periods,
      });

  // ─── Teacher Calendar ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTeacherCalendar(
      String uid, String weekStart, String weekEnd) =>
      _get('/teacher-calendar/$uid?weekStart=$weekStart&weekEnd=$weekEnd');

  // ─── Schedule Events ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> createScheduleEvent({
    required String title,
    required String date,
    String description = '',
    String startTime = '',
    String endTime = '',
    String type = 'event',
    List<String> affectedGrades = const [],
    bool cancelsRegularSchedule = false,
  }) =>
      _post('/schedule-event', {
        'title': title,
        'date': date,
        'description': description,
        'startTime': startTime,
        'endTime': endTime,
        'type': type,
        'affectedGrades': affectedGrades,
        'cancelsRegularSchedule': cancelsRegularSchedule,
      });

  Future<Map<String, dynamic>> deleteScheduleEvent(String id) =>
      _delete('/schedule-event/$id');

  Future<List<Map<String, dynamic>>> getScheduleEvents(
      String start, String end) async {
    final data = await _get('/schedule-events?start=$start&end=$end');
    return (data['events'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  // ─── Period Cancellations ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> cancelPeriod({
    required String grade,
    required String section,
    required String date,
    required String startTime,
    String classId = '',
    String reason = '',
  }) =>
      _post('/period-cancellation', {
        'grade': grade,
        'section': section,
        'date': date,
        'startTime': startTime,
        'classId': classId,
        'reason': reason,
      });

  Future<Map<String, dynamic>> undoCancelPeriod(String id) =>
      _delete('/period-cancellation/$id');
}
