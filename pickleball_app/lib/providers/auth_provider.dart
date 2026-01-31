import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final authResponse = await _apiService.login(username, password);
      await _apiService.saveToken(authResponse.token);
      
      // Fetch user details
      await fetchUserDetails();
      
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _apiService.register(username, email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchUserDetails() async {
    try {
      _user = await _apiService.getMe();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<void> logout() async {
    await _apiService.clearAuth();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    await fetchUserDetails();
  }

  Future<bool> checkAuthStatus() async {
    _setLoading(true);
    final token = await _apiService.getToken();
    if (token != null) {
      try {
        await fetchUserDetails();
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners(); // Notify that auth status changed to true
        return true;
      } catch (e) {
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
