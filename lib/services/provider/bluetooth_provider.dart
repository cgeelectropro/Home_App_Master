import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart' as fb;
import 'package:home_app/services/bluetooth/bluetooth_service.dart';
import 'package:home_app/services/bluetooth/bluetooth_command_handler.dart';
import 'package:home_app/utils/bluetooth_permission_handler.dart';
import 'package:home_app/utils/app_logger.dart';
import 'package:home_app/models/device_model.dart';

class BluetoothProvider with ChangeNotifier {
  final BluetoothService _bluetoothService = BluetoothService();
  late final BluetoothCommandHandler _commandHandler;

  bool _isInitialized = false;
  final bool _isScanning = false;
  String? _error;
  final Map<String, Device> _connectedDevices = {};

  BluetoothProvider() {
    _commandHandler = BluetoothCommandHandler(_bluetoothService);
  }

  bool get isInitialized => _isInitialized;
  bool get isScanning => _isScanning;
  String? get error => _error;
  List<Device> get connectedDevices => _connectedDevices.values.toList();

  bool isDeviceConnected(String macAddress) {
    return _connectedDevices.values
        .any((device) => device.macAddress == macAddress);
  }

  Future<void> initialize() async {
    try {
      // Check permissions first
      final hasPermissions =
          await BluetoothPermissionHandler.checkAndRequestPermissions();
      if (!hasPermissions) {
        throw Exception('Bluetooth permissions not granted');
      }

      // Check if Bluetooth is enabled
      final isEnabled = await _bluetoothService.isBluetoothEnabled();
      if (!isEnabled) {
        throw Exception('Bluetooth is not enabled');
      }

      _isInitialized = true;
      _error = null;
      notifyListeners();

      await AppLogger.log('Bluetooth initialized successfully');
    } catch (e) {
      _error = e.toString();
      _isInitialized = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<fb.ScanResult>> scanForDevices() async {
    // Implement scanning logic
    return [];
  }

  Future<bool> connectToDevice(Device device) async {
    try {
      if (!_isInitialized) {
        throw Exception('Bluetooth not initialized');
      }

      final scanResults = await _bluetoothService.scanForDevices();
      final targetDevice = scanResults.firstWhere(
        (result) => result.device.id.id == device.macAddress,
        orElse: () => throw Exception('Device not found'),
      );

      final success =
          await _bluetoothService.connectToDevice(targetDevice.device);
      if (success) {
        _connectedDevices[device.id] = device;
        notifyListeners();
      }

      await AppLogger.logBluetoothEvent(
        success ? 'Connected to device' : 'Failed to connect',
        deviceId: device.id,
      );

      return success;
    } catch (e) {
      await AppLogger.error(
          'Failed to connect to device', error: e, stackTrace: StackTrace.current);
      throw Exception('Failed to connect: ${e.toString()}');
    }
  }

  Future<bool> sendCommand(Device device, String action) async {
    try {
      if (!_connectedDevices.containsKey(device.id)) {
        throw Exception('Device not connected');
      }

      final success = await _commandHandler.sendDeviceCommand(device, action);

      // Update device status if command was successful
      if (success) {
        final updatedDevice = device.copyWith(
          status: action.toLowerCase() == 'on' ? 'on' : 'off',
        );
        _connectedDevices[device.id] = updatedDevice;
        notifyListeners();
      }

      return success;
    } catch (e) {
      await AppLogger.error('Failed to send command', error: e, stackTrace: StackTrace.current);
      throw Exception('Failed to send command: ${e.toString()}');
    }
  }

  Future<void> disconnectDevice(Device device) async {
    try {
      await _bluetoothService.disconnectDevice(device.id);
      _connectedDevices.remove(device.id);
      notifyListeners();

      await AppLogger.logBluetoothEvent(
        'Disconnected from device',
        deviceId: device.id,
      );
    } catch (e) {
      await AppLogger.error(
          'Failed to disconnect device', e, StackTrace.current);
      throw Exception('Failed to disconnect: ${e.toString()}');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _bluetoothService.dispose();
    _commandHandler.dispose();
    super.dispose();
  }
}
