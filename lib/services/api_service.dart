// lib/services/api_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator → localhost
  // Use 'http://YOUR_PC_IP:8000' for physical device

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── AUTH ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String email, String password, String role) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'role': role}),
      );
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, ...data};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> data) async {
    final headers = await _headers();
    final res = await http.patch(
      Uri.parse('$baseUrl/auth/me/update'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return {};
  }

  // ─── CHILDREN ──────────────────────────────────────────
  static Future<List<dynamic>> getChildren({String? parentId}) async {
    final headers = await _headers();
    final query = parentId != null ? '?parent_id=$parentId' : '';
    final res =
    await http.get(Uri.parse('$baseUrl/children$query'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>> addChild(
      Map<String, dynamic> data) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/children'),
      headers: headers,
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateChild(
      String childId, Map<String, dynamic> data) async {
    final headers = await _headers();
    final res = await http.put(
      Uri.parse('$baseUrl/children/$childId'),
      headers: headers,
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<void> deleteChild(String childId) async {
    final headers = await _headers();
    await http.delete(Uri.parse('$baseUrl/children/$childId'), headers: headers);
  }

  // ─── ASSESSMENTS ───────────────────────────────────────
  static Future<Map<String, dynamic>> uploadAudio(
      File audioFile, String childId, String activityType) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/assessments/analyze'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['child_id'] = childId;
    request.fields['activity_type'] = activityType;
    request.files
        .add(await http.MultipartFile.fromPath('audio', audioFile.path));

    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> analyzeText(
      String text, String childId, String activityType) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/assessments/analyze-text'),
      headers: headers,
      body: jsonEncode({
        'text': text,
        'child_id': childId,
        'activity_type': activityType,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getAssessments({
    String? childId,
    String? status,
  }) async {
    final headers = await _headers();
    final params = <String, String>{};
    if (childId != null) params['child_id'] = childId;
    if (status != null) params['status'] = status;
    final uri = Uri.parse('$baseUrl/assessments').replace(queryParameters: params);
    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>> reviewAssessment(
      String assessmentId, {
        required String status,
        String? note,
        double? correctedScore,
      }) async {
    final headers = await _headers();
    final res = await http.patch(
      Uri.parse('$baseUrl/assessments/$assessmentId/review'),
      headers: headers,
      body: jsonEncode({
        'status': status,
        if (note != null) 'note': note,
        if (correctedScore != null) 'corrected_score': correctedScore,
      }),
    );
    return jsonDecode(res.body);
  }

  // ─── NOTIFICATIONS ─────────────────────────────────────
  static Future<List<dynamic>> getNotifications() async {
    final headers = await _headers();
    final res = await http.get(
        Uri.parse('$baseUrl/notifications'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String message,
    required String type,
  }) async {
    final headers = await _headers();
    await http.post(
      Uri.parse('$baseUrl/notifications/send'),
      headers: headers,
      body: jsonEncode({
        'recipient_id': recipientId,
        'title': title,
        'message': message,
        'type': type,
      }),
    );
  }

  static Future<void> markNotificationRead(String id) async {
    final headers = await _headers();
    await http.patch(
        Uri.parse('$baseUrl/notifications/$id/read'), headers: headers);
  }

  // ─── MESSAGES ──────────────────────────────────────────
  static Future<List<dynamic>> getConversations() async {
    final headers = await _headers();
    final res = await http.get(
        Uri.parse('$baseUrl/messages/conversations'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<List<dynamic>> getMessages(String conversationId) async {
    final headers = await _headers();
    final res = await http.get(
        Uri.parse('$baseUrl/messages/$conversationId'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String recipientId,
    required String content,
  }) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: headers,
      body: jsonEncode({'recipient_id': recipientId, 'content': content}),
    );
    return jsonDecode(res.body);
  }

  // ─── SCHEDULES ─────────────────────────────────────────
  static Future<List<dynamic>> getSchedules({String? date}) async {
    final headers = await _headers();
    final query = date != null ? '?date=$date' : '';
    final res = await http.get(
        Uri.parse('$baseUrl/schedules$query'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>> createSchedule(
      Map<String, dynamic> data) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/schedules'),
      headers: headers,
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  // ─── REPORTS ───────────────────────────────────────────
  static Future<Map<String, dynamic>> getChildReport(String childId) async {
    final headers = await _headers();
    final res = await http.get(
        Uri.parse('$baseUrl/reports/child/$childId'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return {};
  }

  static Future<List<dynamic>> getAllStats() async {
    final headers = await _headers();
    final res =
    await http.get(Uri.parse('$baseUrl/reports/stats'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  // ─── ATTENDANCE ────────────────────────────────────────
  static Future<List<dynamic>> getAttendance({String? date}) async {
    final headers = await _headers();
    final query = date != null ? '?date=$date' : '';
    final res = await http.get(
        Uri.parse('$baseUrl/attendance$query'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>> saveAttendance(
      Map<String, dynamic> data) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/attendance'),
      headers: headers,
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  // ─── SYSTEM LOGS ───────────────────────────────────────
  static Future<List<dynamic>> getSystemLogs() async {
    final headers = await _headers();
    final res = await http.get(
        Uri.parse('$baseUrl/logs'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  // ─── USERS (Admin) ─────────────────────────────────────
  static Future<List<dynamic>> getAllUsers({String? role}) async {
    final headers = await _headers();
    final query = role != null ? '?role=$role' : '';
    final res = await http.get(
        Uri.parse('$baseUrl/users$query'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>> createUser(
      Map<String, dynamic> data) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: headers,
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<void> deleteUser(String userId) async {
    final headers = await _headers();
    await http.delete(Uri.parse('$baseUrl/users/$userId'), headers: headers);
  }
}

