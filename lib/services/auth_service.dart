import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null && token.isNotEmpty) {
      final userJson = prefs.getString('user');
      if (userJson != null) {
        try {
          _currentUser = User.fromJson(jsonDecode(userJson));
        } catch (e) {
          debugPrint('Invalid stored user data: $e');
          await prefs.remove('user');
          await prefs.remove('token');
        }
        notifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>> login(String email, String password,
      [String? role]) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.login(email, password, role);
      debugPrint('FULL LOGIN DATA: $result');
      debugPrint('USER OBJECT: ${result['user']}');
      if (result['success']) {
        final prefs = await SharedPreferences.getInstance();

        // ┌─ Extract JWT Token (consistent format from backend)
        // Backend should return in order of preference: token > access > user.token
        // This is a fallback chain for compatibility with different API versions
        final token = _extractToken(result);
        debugPrint('TOKEN EXTRACTED: "$token"');

        if (token.isEmpty) {
          debugPrint('ERROR: No token found in login response');
          return {
            'success': false,
            'message': 'No authentication token received'
          };
        }

        await prefs.setString('token', token);
        await prefs.setString('user', jsonEncode(result['user']));
        try {
          _currentUser = User.fromJson(result['user'] ?? {});
        } catch (e) {
          debugPrint('Login User.fromJson failed: $e');
        }
        notifyListeners();
      }
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Extract JWT token from API response with consistent fallback chain
  String _extractToken(Map<String, dynamic> response) {
    // Try standard formats in order of preference
    return (response['token'] as String?) ??
        (response['access'] as String?) ??
        (response['access_token'] as String?) ??
        (response['user']?['token'] as String?) ??
        '';
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      if (result['success']) {
        final prefs = await SharedPreferences.getInstance();
        final token = _extractToken(result);

        if (token.isEmpty) {
          debugPrint('ERROR: No token found in register response');
          return {
            'success': false,
            'message': 'No authentication token received'
          };
        }

        await prefs.setString('token', token);
        await prefs.setString('user', jsonEncode(result['user']));
        try {
          _currentUser = User.fromJson(result['user'] ?? {});
        } catch (e) {
          debugPrint('Register User.fromJson failed: $e');
        }
        notifyListeners();
      }
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return;

    final result = await ApiService.updateProfile(data);
    if (result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(result));
      try {
        _currentUser = User.fromJson(result);
      } catch (e) {
        debugPrint('UpdateProfile User.fromJson failed: $e');
      }
      notifyListeners();
    }
  }
}
