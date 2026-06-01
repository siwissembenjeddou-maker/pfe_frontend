// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static void Function()? onUnauthorized;

  static void _check401(int statusCode) {
    if (statusCode == 401) onUnauthorized?.call();
  }

  static String _cleanUrl(String url) {
    // Prevent cases like " 192.168.1.241" getting URL-encoded into "%20192.168..."
    // causing: FormatException: %20192... contains %
    final cleaned = url.trim().replaceAll(RegExp(r'\s+'), '');
    return cleaned;
  }

  // Auto-detect: Android emulator → 10.0.2.2, otherwise → 127.0.0.1
  // For physical device on same network, replace with your PC's IP (run `ipconfig`)
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Physical device (Android) on same LAN as backend
      // Using PC's LAN IPv4 address found via ipconfig: 10.236.250.160
      return _cleanUrl('http://192.168.1.45:8000');
    }
    return _cleanUrl('http://127.0.0.1:8000');
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // AUTH
  static Future<Map<String, dynamic>> login(String email, String password,
      [String? role]) async {
    try {
      final res = await http
          .post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          if (role != null && role.isNotEmpty) 'role': role,
        }),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Server is not responding. Check your backend.');
        },
      );
      // Helpful debugging: if backend returns HTML (Django error page), show it instead of crashing.
      try {
        final data = jsonDecode(res.body);
        return {'success': res.statusCode == 200, ...data};
      } catch (e) {
        final preview = res.body.length > 300
            ? '${res.body.substring(0, 300)}...'
            : res.body;
        return {
          'success': false,
          'message':
              'Unexpected response format (not JSON). status=${res.statusCode}. bodyPreview=$preview'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(
      {required String name,
      required String email,
      required String password,
      required String role}) async {
    try {
      final res = await http
          .post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Server is not responding. Check your backend.');
        },
      );
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 201, ...data};
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
    _check401(res.statusCode);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return {};
  }

  // CHILDREN
  static Future<List<dynamic>> getChildren({String? parentId}) async {
    final headers = await _headers();
    final query = parentId != null ? '?parent_id=$parentId' : '';
    final response = await http
        .get(
          Uri.parse('$baseUrl/children$query'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 10));

    _check401(response.statusCode);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;

      final Map<String, dynamic> data = decoded as Map<String, dynamic>;
      final dynamic rawChildren =
          data['results'] ?? data['data'] ?? data['items'];
      if (rawChildren is List) return rawChildren;
      return [];
    } else {
      debugPrint('getChildren failed: ${response.statusCode} ${response.body}');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addChild(
      Map<String, dynamic> childData) async {
    final headers = await _headers();

    final response = await http
        .post(
          Uri.parse('$baseUrl/children/'),
          headers: headers,
          body: jsonEncode(childData),
        )
        .timeout(const Duration(seconds: 10));

    _check401(response.statusCode);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add child: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> updateChild(
      Object childId, Map<String, dynamic> data) async {
    final headers = await _headers();
    final id = childId.toString();
    final res = await http.put(Uri.parse('$baseUrl/children/$id'),
        headers: headers, body: jsonEncode(data));
    return jsonDecode(res.body);
  }

  static Future<void> deleteChild(Object childId) async {
    final headers = await _headers();
    final id = childId.toString();
    final res =
        await http.delete(Uri.parse('$baseUrl/children/$id'), headers: headers);
    _check401(res.statusCode);
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to delete child: ${res.statusCode} ${res.body}');
    }
  }

  // ASSESSMENTS
  static Future<Map<String, dynamic>> uploadAudio(
      File audioFile, Object childId, String activityType) async {
    final headers = await _headers();
    final request = http.MultipartRequest(
        'POST', Uri.parse('$baseUrl/assessments/analyze'));
    request.fields['child_id'] = childId.toString();
    request.fields['activity_type'] = activityType;
    request.files
        .add(await http.MultipartFile.fromPath('audio', audioFile.path));
    // Multipart: add auth, skip Content-Type
    if (headers.containsKey('Authorization')) {
      request.headers['Authorization'] = headers['Authorization']!;
    }

    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);

    _check401(res.statusCode);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final body = res.body.trim();
      if (body.startsWith('<')) {
        throw Exception(
            'Server returned an HTML response instead of JSON. Please check the backend endpoint and CORS configuration. Status: ${res.statusCode}.');
      }
      throw Exception(
          'Upload failed with status ${res.statusCode}: ${body.isEmpty ? 'Empty response' : body}');
    }

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Unexpected response format from server.');
    } catch (e) {
      throw Exception(
          'Invalid JSON received from server: ${e.toString()}. Response body: ${res.body.length > 200 ? '${res.body.substring(0, 200)}...' : res.body}');
    }
  }

  static Future<Map<String, dynamic>> analyzeText(
      String text, Object childId, String activityType) async {
    final headers = await _headers();
    final res = await http.post(Uri.parse('$baseUrl/assessments/analyze-text'),
        headers: headers,
        body: jsonEncode({
          'text': text,
          'child_id': childId.toString(),
          'activity_type': activityType,
        }));
    _check401(res.statusCode);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    return {'error': 'Failed to analyze text', 'status_code': res.statusCode};
  }

  static Future<List<dynamic>> getAssessments(
      {Object? childId, String? status}) async {
    final headers = await _headers();
    final params = <String, String>{};
    if (childId != null) params['child_id'] = childId.toString();
    if (status != null) params['status'] = status;
    final uri =
        Uri.parse('$baseUrl/assessments').replace(queryParameters: params);
    final res = await http.get(uri, headers: headers);
    _check401(res.statusCode);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return data;
      if (data is Map) {
        // Support paginated {results: []} and flat {assessments: []}
        for (final key in ['results', 'assessments', 'data', 'items']) {
          final v = data[key];
          if (v is List) return v;
        }
      }
      return [];
    }
    // Log error and return empty (caller handles gracefully)
    debugPrint('getAssessments failed: ${res.statusCode} ${res.body}');
    return [];
  }

  static Future<Map<String, dynamic>> reviewAssessment(Object assessmentId,
      {required String status, String? note, double? correctedScore}) async {
    final headers = await _headers();
    final res = await http.patch(
        Uri.parse('$baseUrl/assessments/${assessmentId.toString()}/review'),
        headers: headers,
        body: jsonEncode({
          'status': status,
          if (note != null) 'note': note,
          if (correctedScore != null) 'corrected_score': correctedScore,
        }));
    _check401(res.statusCode);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    // Return error info so caller can show meaningful message
    try {
      final err = jsonDecode(res.body);
      return {'error': err['error'] ?? 'Server error (${res.statusCode})'};
    } catch (_) {
      return {'error': 'Server error (${res.statusCode})'};
    }
  }

  static Future<void> deleteAssessment(Object assessmentId) async {
    final headers = await _headers();
    final id = assessmentId.toString();
    final res = await http.delete(
      Uri.parse('$baseUrl/assessments/$id'),
      headers: headers,
    );
    _check401(res.statusCode);
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
          'Failed to delete assessment: ${res.statusCode} ${res.body}');
    }
  }

  // NOTIFICATIONS
  static Future<List<dynamic>> getNotifications() async {
    final headers = await _headers();
    final res =
        await http.get(Uri.parse('$baseUrl/notifications'), headers: headers);
    _check401(res.statusCode);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded;
      if (decoded is Map) {
        final v = decoded['results'] ?? decoded['data'] ?? decoded['items'];
        if (v is List) return v;
      }
      return [];
    }
    return [];
  }

  static Future<void> deleteNotification(Object id) async {
    final headers = await _headers();
    final res = await http.delete(
      Uri.parse('$baseUrl/notifications/${id.toString()}'),
      headers: headers,
    );
    _check401(res.statusCode);
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
          'Failed to delete notification: ${res.statusCode} ${res.body}');
    }
  }

  static Future<Map<String, dynamic>> updateNotification({
    required Object id,
    String? title,
    String? message,
    String? type,
  }) async {
    final headers = await _headers();
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (type != null) 'type': type,
    };

    final res = await http.patch(
      Uri.parse('$baseUrl/notifications/${id.toString()}/update'),
      headers: headers,
      body: jsonEncode(body),
    );

    _check401(res.statusCode);
    if (res.statusCode != 200) {
      throw Exception(
          'Failed to update notification: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static Future<bool> sendNotification(
      {required String recipientId,
      required String title,
      required String message,
      required String type}) async {
    final headers = await _headers();
    final res = await http.post(Uri.parse('$baseUrl/notifications/send'),
        headers: headers,
        body: jsonEncode({
          'recipient_id': recipientId,
          'title': title,
          'message': message,
          'type': type,
        }));
    return res.statusCode == 200 || res.statusCode == 201;
  }

  static Future<void> markNotificationRead(Object id) async {
    final headers = await _headers();
    final res = await http.patch(
        Uri.parse('$baseUrl/notifications/${id.toString()}/read'),
        headers: headers);
    _check401(res.statusCode);
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
          'Failed to mark notification read: ${res.statusCode} ${res.body}');
    }
  }

  // MESSAGES
  static Future<List<dynamic>> getConversations() async {
    final headers = await _headers();
    final res = await http.get(
      Uri.parse('$baseUrl/messages/conversations/'),
      headers: headers,
    );

    _check401(res.statusCode);
    if (res.statusCode != 200) return [];

    final decoded = jsonDecode(res.body);
    if (decoded is List) return decoded;

    if (decoded is Map<String, dynamic>) {
      final v = decoded['conversations'] ??
          decoded['results'] ??
          decoded['data'] ??
          decoded['items'];
      if (v is List) return v;
    }

    return [];
  }

  static Future<List<dynamic>> getMessages(Object conversationId) async {
    final headers = await _headers();
    final res = await http.get(
      Uri.parse('$baseUrl/messages/${conversationId.toString()}/'),
      headers: headers,
    );

    _check401(res.statusCode);
    if (res.statusCode != 200) return [];

    final decoded = jsonDecode(res.body);
    if (decoded is List) return decoded;

    if (decoded is Map<String, dynamic>) {
      final v = decoded['messages'] ??
          decoded['results'] ??
          decoded['data'] ??
          decoded['items'];
      if (v is List) return v;
    }

    return [];
  }

  static Future<Map<String, dynamic>> sendMessage(
      {required Object recipientId, required String content}) async {
    final headers = await _headers();
    final res = await http.post(Uri.parse('$baseUrl/messages/'),
        headers: headers,
        body: jsonEncode(
            {'recipient_id': recipientId.toString(), 'content': content}));
    return jsonDecode(res.body);
  }

  // PSYCHOLOGIST REPORTS
  /// Sends a child progress report from psychologist → parent as a notification.
  /// Returns `{success: bool, message: String}` with details on failure.
  static Future<Map<String, dynamic>> sendChildReport({
    required String recipientId,
    required String childId,
    required String childName,
    required String reportContent,
    required String psychologistId,
    required String psychologistName,
    required String parentName,
  }) async {
    final headers = await _headers();
    final title = '📋 Child Report: $childName';
    final message =
        '$psychologistName → $parentName  ➤ $childName\'s report:\n\n$reportContent';

    // 1) Send to parent
    final res = await http.post(Uri.parse('$baseUrl/notifications/send'),
        headers: headers,
        body: jsonEncode({
          'recipient_id': recipientId,
          'title': title,
          'message': message,
          'type': 'psychologist_report',
          'child_id': childId,
        }));
    _check401(res.statusCode);
    final parentOk = res.statusCode == 200 || res.statusCode == 201;

    // 2) Also send to psychologist (so they can see it in their "previous report")
    final psyRes = await http.post(Uri.parse('$baseUrl/notifications/send'),
        headers: headers,
        body: jsonEncode({
          'recipient_id': psychologistId,
          'title': title,
          'message': message,
          'type': 'psychologist_report',
          'child_id': childId,
        }));
    _check401(psyRes.statusCode);
    final psyOk = psyRes.statusCode == 200 || psyRes.statusCode == 201;

    if (parentOk || psyOk) {
      return {'success': true};
    }
    return {
      'success': false,
      'message':
          'Server returned parent=${res.statusCode}, psy=${psyRes.statusCode}: ${psyRes.body}',
    };
  }

  // SCHEDULES
  static Future<List<dynamic>> getSchedules({String? date}) async {
    final headers = await _headers();
    final query = date != null ? '?date=$date' : '';
    final res = await http.get(Uri.parse('$baseUrl/schedules/$query'),
        headers: headers);
    _check401(res.statusCode);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded;
      if (decoded is Map) {
        final v = decoded['schedules'] ??
            decoded['results'] ??
            decoded['data'] ??
            decoded['items'];
        if (v is List) return v;
      }
      return [];
    }
    return [];
  }

  static Future<Map<String, dynamic>> createSchedule(
      Map<String, dynamic> data) async {
    final headers = await _headers();
    final res = await http.post(Uri.parse('$baseUrl/schedules/'),
        headers: headers, body: jsonEncode(data));
    return jsonDecode(res.body);
  }

  // REPORTS
  static Future<Map<String, dynamic>> getChildReport(Object childId) async {
    final headers = await _headers();
    final res = await http.get(
        Uri.parse('$baseUrl/reports/child/${childId.toString()}/'),
        headers: headers);
    _check401(res.statusCode);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return {};
  }

  static Future<Map<String, dynamic>> getSystemStats() async {
    final headers = await _headers();
    final res =
        await http.get(Uri.parse('$baseUrl/reports/stats/'), headers: headers);
    _check401(res.statusCode);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    }
    return {};
  }

  // ATTENDANCE
  static Future<List<dynamic>> getAttendance({String? date}) async {
    final headers = await _headers();
    final query = date != null ? '?date=$date' : '';
    final res = await http.get(Uri.parse('$baseUrl/attendance/$query'),
        headers: headers);
    _check401(res.statusCode);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded;
      if (decoded is Map) {
        final v = decoded['attendance'] ??
            decoded['results'] ??
            decoded['data'] ??
            decoded['items'];
        if (v is List) return v;
      }
      return [];
    }
    return [];
  }

  static Future<Map<String, dynamic>> saveAttendance(
      Map<String, dynamic> data) async {
    final headers = await _headers();
    final res = await http.post(Uri.parse('$baseUrl/attendance/'),
        headers: headers, body: jsonEncode(data));
    return jsonDecode(res.body);
  }

  // SYSTEM LOGS
  static Future<List<dynamic>> getSystemLogs() async {
    final headers = await _headers();
    final res = await http.get(Uri.parse('$baseUrl/logs/'), headers: headers);
    _check401(res.statusCode);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded;
      if (decoded is Map) {
        final v = decoded['logs'] ??
            decoded['results'] ??
            decoded['data'] ??
            decoded['items'];
        if (v is List) return v;
      }
      return [];
    }
    return [];
  }

  // USERS (Admin)
  static Future<List<dynamic>> getAllUsers({String? role}) async {
    final headers = await _headers();
    final query = role != null ? '?role=$role' : '';
    final res =
        await http.get(Uri.parse('$baseUrl/users/$query'), headers: headers);
    _check401(res.statusCode);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded;
      if (decoded is Map) {
        final v = decoded['users'] ??
            decoded['results'] ??
            decoded['data'] ??
            decoded['items'];
        if (v is List) return v;
      }
      return [];
    }
    return [];
  }

  static Future<Map<String, dynamic>> createUser(
      Map<String, dynamic> data) async {
    final headers = await _headers();
    final res = await http.post(Uri.parse('$baseUrl/users/'),
        headers: headers, body: jsonEncode(data));
    return jsonDecode(res.body);
  }

  static Future<void> deleteUser(Object userId) async {
    final headers = await _headers();
    final res = await http.delete(
        Uri.parse('$baseUrl/users/${userId.toString()}'),
        headers: headers);
    _check401(res.statusCode);
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to delete user: ${res.statusCode} ${res.body}');
    }
  }
}
