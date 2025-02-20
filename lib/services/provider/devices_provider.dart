import 'package:flutter/material.dart';
import 'package:home_app/models/device_model.dart';
import 'package:home_app/services/provider/bluetooth_provider.dart';
import 'package:home_app/services/storage/local_storage.dart';
import 'package:home_app/utils/device_validator.dart';
import 'package:home_app/utils/app_logger.dart';

class DeviceProvider with ChangeNotifier {
  final BluetoothProvider _bluetoothProvider;
  final LocalStorage _localStorage = LocalStorage();
  bool _isOperationInProgress = false;

  List<Device> _devices = [];
  bool _isLoading = false;
  String _error = '';

  DeviceProvider(this._bluetoothProvider) {
    // Initialize by loading devices
    fetchDevices();
    
    // Listen to bluetooth connection changes
    _bluetoothProvider.addListener(_onBluetoothStateChanged);
  }

  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;
  String get error => _error;

  void _onBluetoothStateChanged() {
    // Update connection status of devices
    for (var device in _devices) {
      if (device.macAddress != null && device.macAddress!.isNotEmpty) {
        final isConnected = _bluetoothProvider.isDeviceConnected(device.macAddress!);
        if (device.isConnected != isConnected) {
          updateDeviceConnectionState(device.id, isConnected);
        }
      }
    }
  }

  Future<void> fetchDevices() async {
    if (_isOperationInProgress) {
      return;
    }
    _isOperationInProgress = true;

    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      final storedDevices = await _localStorage.getDevices();
      _devices = storedDevices;
      notifyListeners();

      await AppLogger.log('Fetched ${_devices.length} devices from storage');
    } catch (e) {
      _error = 'Failed to fetch devices: ${e.toString()}';
      await AppLogger.logError(
          'Failed to fetch devices', e, StackTrace.current);
    } finally {
      _isLoading = false;
      _isOperationInProgress = false;
      notifyListeners();
    }
  }

  Future<bool> addDevice(Device device) async {
    if (_isOperationInProgress) {
      return false;
    }
    _isOperationInProgress = true;

    try {
      // Validate device
      final validationError = DeviceValidator.validateDevice(device);
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Validate settings if present
      if (device.settings != null) {
        final settingsError = DeviceValidator.validateSettings(device.settings!);
        if (settingsError != null) {
          throw Exception(settingsError);
        }
        
        // Also validate settings specific to device type
        final typeSettingsError = DeviceValidator.validateSettingsType(device.type, device.settings);
        if (typeSettingsError != null) {
          throw Exception(typeSettingsError);
        }
      }

      // Check for duplicate MAC address
      if (device.macAddress != null &&
          _devices.any((d) => d.macAddress == device.macAddress)) {
        throw Exception('Device with this MAC address already exists');
      }

      _devices.add(device);
      await _localStorage.saveDevices(_devices);
      notifyListeners();

      await AppLogger.log('Added new device: ${device.id}');
      return true;
    } catch (e) {
      _error = 'Failed to add device: ${e.toString()}';
      await AppLogger.logError('Failed to add device', e, StackTrace.current);
      return false;
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<void> clearDevices() async {
    if (_isOperationInProgress) {
      return;
    }
    _isOperationInProgress = true;

    try {
      _devices.clear();
      await _localStorage.saveDevices(_devices);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear devices: ${e.toString()}';
      await AppLogger.logError('Failed to clear devices', e, StackTrace.current);
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<bool> updateDevice(Device device) async {
    if (_isOperationInProgress) {
      return false;
    }
    _isOperationInProgress = true;

    try {
      final index = _devices.indexWhere((d) => d.id == device.id);
      if (index == -1) {
        throw Exception('Device not found');
      }

      // Validate device
      final validationError = DeviceValidator.validateDevice(device);
      if (validationError != null) {
        throw Exception(validationError);
      }

      _devices[index] = device;
      await _localStorage.saveDevices(_devices);
      notifyListeners();

      await AppLogger.log('Updated device: ${device.id}');
      return true;
    } catch (e) {
      _error = 'Failed to update device: ${e.toString()}';
      await AppLogger.logError(
          'Failed to update device', e, StackTrace.current);
      return false;
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<bool> deleteDevice(String deviceId) async {
    if (_isOperationInProgress) {
      return false;
    }
    _isOperationInProgress = true;

    try {
      final device = _devices.firstWhere((d) => d.id == deviceId);

      // Disconnect device if connected
      if (device.isConnected) {
        await _bluetoothProvider.disconnectDevice(device);
      }

      _devices.removeWhere((d) => d.id == deviceId);
      await _localStorage.saveDevices(_devices);
      notifyListeners();

      await AppLogger.log('Deleted device: $deviceId');
      return true;
    } catch (e) {
      _error = 'Failed to delete device: ${e.toString()}';
      await AppLogger.logError(
          'Failed to delete device', e, StackTrace.current);
      return false;
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<bool> toggleDevice(String deviceId) async {
    if (_isOperationInProgress) {
      return false;
    }
    _isOperationInProgress = true;

    try {
      final device = _devices.firstWhere((d) => d.id == deviceId);
      final newStatus = device.status.toLowerCase() == 'on' ? 'off' : 'on';

      // Ensure device is connected
      if (!device.isConnected) {
        await _bluetoothProvider.connectToDevice(device);
      }

      // Send command
      final success = await _bluetoothProvider.sendCommand(device, newStatus);
      if (success) {
        // Update device status
        final updatedDevice = device.copyWith(status: newStatus);
        await updateDevice(updatedDevice);

        await AppLogger.log('Toggled device: $deviceId to $newStatus');
      }

      return success;
    } catch (e) {
      _error = 'Failed to toggle device: ${e.toString()}';
      await AppLogger.logError(
          'Failed to toggle device', e, StackTrace.current);
      return false;
    } finally {
      _isOperationInProgress = false;
    }
  }

  Device? getDeviceById(String id) {
    try {
      return _devices.firstWhere((device) => device.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Device> getDevicesByType(String type) {
    return _devices
        .where((device) => device.type.toLowerCase() == type.toLowerCase())
        .toList();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  Future<void> refreshDevices() async {
    await fetchDevices();
  }

  Future<void> setDevices(List<Device> devices) async {
    _devices = devices;
    notifyListeners();
  }

  void updateDeviceConnectionState(String deviceId, bool isConnected) {
    final deviceIndex = _devices.indexWhere((d) => d.id == deviceId);
    if (deviceIndex != -1) {
      final updatedDevice = _devices[deviceIndex].copyWith(isConnected: isConnected);
      _devices[deviceIndex] = updatedDevice;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _bluetoothProvider.removeListener(_onBluetoothStateChanged);
    super.dispose();
  }
}
