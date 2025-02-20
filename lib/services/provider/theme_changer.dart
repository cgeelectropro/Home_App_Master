import 'package:flutter/material.dart';
import 'package:home_app/services/api/pref_services.dart';

class ThemeChanger with ChangeNotifier {
  final PrefServices _prefServices = PrefServices();
  bool _darkTheme = false;

  ThemeChanger() {
    _loadTheme();
  }

  bool get darkTheme => _darkTheme;

  Future<void> _loadTheme() async {
    try {
      _darkTheme = await _prefServices.getDarkMode();
      notifyListeners();
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  Future<void> setDarkTheme(bool value) async {
    _darkTheme = value;
    await _prefServices.setDarkMode(value);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _darkTheme = !_darkTheme;
    await _prefServices.setDarkMode(_darkTheme);
    notifyListeners();
  }
}
