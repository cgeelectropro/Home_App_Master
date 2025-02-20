import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectionStateProvider with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  bool _hasInternetConnection = true;
  String _connectionType = 'none';
  String _error = '';

  bool get hasInternetConnection => _hasInternetConnection;
  String get connectionType => _connectionType;
  String get error => _error;

  ConnectionStateProvider() {
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) => _updateConnectionStatus(results.first),
    );
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results.first);
    } catch (e) {
      _error = 'Failed to get connectivity status: $e';
      _hasInternetConnection = false;
      notifyListeners();
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        _hasInternetConnection = true;
        _connectionType = 'wifi';
        break;
      case ConnectivityResult.mobile:
        _hasInternetConnection = true;
        _connectionType = 'mobile';
        break;
      case ConnectivityResult.none:
        _hasInternetConnection = false;
        _connectionType = 'none';
        break;
      default:
        _hasInternetConnection = false;
        _connectionType = 'unknown';
    }
    notifyListeners();
  }

  Future<bool> checkInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results.first);
      return _hasInternetConnection;
    } catch (e) {
      _error = 'Failed to check internet connection: $e';
      _hasInternetConnection = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
