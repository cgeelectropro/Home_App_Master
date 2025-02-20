import 'package:shared_preferences/shared_preferences.dart';

class PrefServices {
  static const String userKey = 'user_data';
  static const String devicesKey = 'devices_data';
  static const String collectionsKey = 'collections_data';
  static const String themeKey = 'theme_data';
  static const String tokenKey = 'auth_token';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // User data operations
  Future<String?> getUserData() async {
    final prefs = await _prefs;
    return prefs.getString(userKey);
  }

  Future<bool> setUserData(String userData) async {
    final prefs = await _prefs;
    return prefs.setString(userKey, userData);
  }

  // Device data operations
  Future<String?> getDevicesData() async {
    final prefs = await _prefs;
    return prefs.getString(devicesKey);
  }

  Future<bool> setDevicesData(String devicesData) async {
    final prefs = await _prefs;
    return prefs.setString(devicesKey, devicesData);
  }

  // Collection data operations
  Future<String?> getCollectionsData() async {
    final prefs = await _prefs;
    return prefs.getString(collectionsKey);
  }

  Future<bool> setCollectionsData(String collectionsData) async {
    final prefs = await _prefs;
    return prefs.setString(collectionsKey, collectionsData);
  }

  // Theme data operations
  Future<bool> getDarkMode() async {
    final prefs = await _prefs;
    return prefs.getBool(themeKey) ?? false;
  }

  Future<bool> setDarkMode(bool isDark) async {
    final prefs = await _prefs;
    return prefs.setBool(themeKey, isDark);
  }

  // Generic operations
  Future<String?> loadFromPrefs(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  Future<bool> saveToPrefs(String key, String value) async {
    final prefs = await _prefs;
    return prefs.setString(key, value);
  }

  Future<bool> removeFromPrefs(String key) async {
    final prefs = await _prefs;
    return prefs.remove(key);
  }

  Future<bool> clearAll() async {
    final prefs = await _prefs;
    return prefs.clear();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<bool> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(tokenKey, token);
  }
}
