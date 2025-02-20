import 'package:flutter/material.dart';
import 'package:home_app/services/provider/bluetooth_provider.dart';
import 'package:home_app/services/provider/user_provider.dart';
import 'package:home_app/services/provider/devices_provider.dart';

class AppStateProvider with ChangeNotifier {
  final BluetoothProvider _bluetoothProvider;
  final UserProvider _userProvider;
  final DeviceProvider _deviceProvider;

  bool _isInitialized = false;
  bool _isLoading = false;
  String _error = '';

  AppStateProvider(
    this._bluetoothProvider,
    this._userProvider,
    this._deviceProvider,
  );

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isBluetoothReady => _bluetoothProvider.isInitialized;
  bool get isAuthenticated => _userProvider.isAuthenticated;

  Future<void> initializeApp() async {
    if (_isInitialized) return;

    setLoading(true);
    try {
      // Initialize Bluetooth - critical for device control
      await _bluetoothProvider.initialize();

      // Check local authentication
      await _userProvider.checkAuthStatus();

      // If authenticated, fetch local devices
      if (_userProvider.isAuthenticated) {
        await _deviceProvider.fetchDevices();
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      setError('Failed to initialize app: $e');
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  Future<void> refreshAppState() async {
    setLoading(true);
    try {
      if (_userProvider.isAuthenticated) {
        await _deviceProvider.fetchDevices();
      }
    } catch (e) {
      setError('Failed to refresh app state: $e');
    } finally {
      setLoading(false);
    }
  }

  void resetAppState() {
    _isInitialized = false;
    _isLoading = false;
    _error = '';
    notifyListeners();
  }
}
