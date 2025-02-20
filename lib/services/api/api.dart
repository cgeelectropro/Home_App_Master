import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_app/services/api/pref_services.dart';

class Api {
  static final PrefServices _prefServices = PrefServices();
  // Local storage keys
  static const String userKey = 'user_data';
  static const String tokenKey = 'auth_token';

  // Save user data to local storage
  static Future<void> saveUserData(String userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, userData);
  }

  // Get user data from local storage
  static Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userKey);
  }

  // Save token to local storage
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  // Get token from local storage
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Create authorization header
  static Future<Map<String, String>> createAuthorizationHeader() async {
    final token = await _prefServices.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
      'Accept-Language': 'en_US'
    };
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await _prefServices.getToken();
    return token != null;
  }

  // Handle API errors
  static void handleError(dynamic error) {
    if (error.toString().contains('401')) {
      // Handle unauthorized access
      _prefServices.clearAll();
    }
    throw Exception('API Error: $error');
  }

  // Validate token
  static bool isTokenValid(String token) {
    try {
      // Add your token validation logic here
      // For example, check token expiration
      return token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
