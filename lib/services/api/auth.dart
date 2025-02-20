import 'dart:convert';
import 'package:home_app/models/user.dart';
import 'package:home_app/services/api/pref_services.dart';
import 'package:crypto/crypto.dart';

class AuthServices {
  final PrefServices _prefServices = PrefServices();

  // Securely hash the password
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<User?> login(String username, String password) async {
    try {
      // Hash password before storing/comparing
      final hashedPassword = _hashPassword(password);

      // Get stored user data
      final userData = await _prefServices.getUserData();
      if (userData != null) {
        final user = User.fromMap(json.decode(userData));

        // Verify credentials
        if (user.name == username && user.password == hashedPassword) {
          // Generate and store new session token
          final token = _generateSessionToken(username);
          await _prefServices.setToken(token);

          return user;
        }
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<User?> register(String username, String password) async {
    try {
      // Hash password before storing
      final hashedPassword = _hashPassword(password);

      // Check if user already exists
      final existingData = await _prefServices.getUserData();
      if (existingData != null) {
        final existingUser = User.fromMap(json.decode(existingData));
        if (existingUser.name == username) {
          throw Exception('Username already exists');
        }
      }

      // Create new user
      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        index: 0,
        isActive: true,
        picture: '',
        name: username,
        phone: '',
        address: '',
        registered: DateTime.now().toIso8601String(),
        devices: 0,
        password: hashedPassword,
      );

      // Save user data
      await _prefServices.setUserData(json.encode(newUser.toMap()));

      // Generate and store session token
      final token = _generateSessionToken(username);
      await _prefServices.setToken(token);

      return newUser;
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _prefServices.clearAll();
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Logout failed: $e');
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final token = await _prefServices.getToken();
      return token != null;
    } catch (e) {
      print('Auth check error: $e');
      return false;
    }
  }

  String _generateSessionToken(String username) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final tokenData = '$username:$timestamp';
    var bytes = utf8.encode(tokenData);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}
