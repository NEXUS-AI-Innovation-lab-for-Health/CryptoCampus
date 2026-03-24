import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      try {
        _currentUser = await _apiService.getUserById(userId);
        notifyListeners();
      } catch (e) {
        await logout();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _apiService.login(email, password);
      
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      
      _currentUser = user;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.userId);
      await prefs.setString('email', user.email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Erreur de connexion: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String role = 'STUDENT',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _apiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );

      _currentUser = user;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.userId);
      await prefs.setString('email', user.email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Erreur inscription: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
