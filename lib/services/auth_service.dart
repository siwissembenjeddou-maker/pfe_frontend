// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<Map<String, dynamic>> login(
      String email, String password, String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService.login(email, password, role);
      if (result['success']) {
        _currentUser = User.fromJson(result['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _currentUser!.token);
        await prefs.setString('role', _currentUser!.role);
      }
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}