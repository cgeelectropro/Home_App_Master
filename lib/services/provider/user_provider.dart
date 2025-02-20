import 'package:flutter/material.dart';
import 'package:home_app/models/user.dart';
import 'package:home_app/services/api/pref_services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  final PrefServices _prefServices = PrefServices();
  User? _currentUser;
  bool _isAuthenticated = false;
  String _error = '';
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  String get error => _error;
  User? get user => _currentUser;
  bool get isLoading => _isLoading;

  // Hash password for local storage
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final hashedPassword = _hashPassword(password);
      final userData = await _prefServices.getUserData();

      if (userData != null) {
        final storedUser = User.fromMap(json.decode(userData));
        if (storedUser.name == username &&
            storedUser.password == hashedPassword) {
          _currentUser = storedUser;
          _isAuthenticated = true;
          notifyListeners();
          return true;
        }
      }

      _error = 'Invalid username or password';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String username, String password) async {
    try {
      final hashedPassword = _hashPassword(password);

      // Check if user already exists
      final existingData = await _prefServices.getUserData();
      if (existingData != null) {
        final existingUser = User.fromMap(json.decode(existingData));
        if (existingUser.name == username) {
          _error = 'Username already exists';
          notifyListeners();
          return false;
        }
      }

      // Create new user
      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: username,
        password: hashedPassword,
        devices: 0,
        isActive: true,
        picture: '',
        phone: '',
        address: '',
        registered: DateTime.now().toIso8601String(),
        index: 0,
      );

      await _prefServices.setUserData(json.encode(newUser.toMap()));
      _currentUser = newUser;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Registration failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      _error = 'Logout failed: $e';
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final userData = await _prefServices.getUserData();
      if (userData != null) {
        _currentUser = User.fromMap(json.decode(userData));
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Auth check failed: $e';
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  void setUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      final userData = await _prefServices.getUserData();
      if (userData != null) {
        _currentUser = User.fromMap(json.decode(userData));
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to refresh user: $e';
      notifyListeners();
    }
  }

  Future<bool> requestAccess({
    required String email,
    required String password,
  }) async {
    // Store pending request locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pendingEmail', email);
    await prefs.setString('pendingPassword', password);

    // In a real app, this would send request to admin
    return true; // Request stored successfully
  }
}
