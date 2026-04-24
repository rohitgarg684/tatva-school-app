import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

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

  Future<Map<String, dynamic>> toggleStoryLike(String storyId) =>
      _post('/story/$storyId/like', {});

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

  // ─── File Upload ──────────────────────────────────────────────────────

  Future<String?> uploadStoryImage(
      Uint8List bytes, String classId, String fileName) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$_baseUrl/story/upload');
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
}
