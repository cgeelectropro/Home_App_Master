import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue/flutter_blue.dart' as fb;
import '../../utils/app_logger.dart';
import '../../models/bluetooth_command.dart';

class BluetoothService {
  static const String HC05_SERVICE_UUID =
      "00001101-0000-1000-8000-00805F9B34FB";
  static const int CONNECTION_TIMEOUT = 5; // seconds
  static const int MAX_RETRY_ATTEMPTS = 3;
  static const int RETRY_DELAY_MS = 500;

  final fb.FlutterBlue _flutterBlue = fb.FlutterBlue.instance;
  final Map<String, fb.BluetoothDevice> _connectedDevices = {};
  final Map<String, StreamSubscription> _deviceStateSubscriptions = {};

  // Connection state tracking
  final Map<String, bool> _deviceConnectionStates = {};
  final _connectionStateController =
      StreamController<Map<String, bool>>.broadcast();
  Stream<Map<String, bool>> get connectionStates =>
      _connectionStateController.stream;

  Future<bool> isBluetoothEnabled() async {
    try {
      return await _flutterBlue.isOn;
    } catch (e) {
      AppLogger.error(
        'Failed to check Bluetooth state',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }

  Future<bool> sendWithRetry(BluetoothCommand cmd,
      {int maxRetries = MAX_RETRY_ATTEMPTS}) async {
    if (!await validateCommand(cmd)) {
      throw Exception('Invalid command format');
    }

    for (int i = 0; i < maxRetries; i++) {
      try {
        final success = await sendCommand(cmd);
        if (success) return true;

        AppLogger.error(
          'Command failed, attempt ${i + 1}/$maxRetries',
          error: 'Command: ${cmd.command}',
          stackTrace: StackTrace.current,
        );

        if (i < maxRetries - 1) {
          await Future.delayed(
              Duration(milliseconds: RETRY_DELAY_MS * (i + 1)));
        }
      } catch (e) {
        AppLogger.error(
          'Command error, attempt ${i + 1}/$maxRetries',
          error: e,
          stackTrace: StackTrace.current,
        );
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(Duration(milliseconds: RETRY_DELAY_MS * (i + 1)));
      }
    }
    return false;
  }

  Future<bool> validateCommand(BluetoothCommand cmd) async {
    if (cmd.command.isEmpty || cmd.deviceId.isEmpty) {
      return false;
    }

    // Validate device connection
    final device = _connectedDevices[cmd.deviceId];
    if (device == null) {
      return false;
    }

    // Validate command format
    try {
      final decoded = jsonDecode(cmd.command);
      return decoded is Map<String, dynamic>;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendCommand(BluetoothCommand command) async {
    final device = _connectedDevices[command.deviceId];
    if (device == null) {
      throw Exception('Device not connected');
    }

    try {
      return await _sendCommandWithTimeout(device, command);
    } catch (e) {
      AppLogger.error(
        'Failed to send command',
        error: e,
        stackTrace: StackTrace.current,
      );
      _updateDeviceConnectionState(command.deviceId, false);
      rethrow;
    }
  }

  void _updateDeviceConnectionState(String deviceId, bool connected) {
    _deviceConnectionStates[deviceId] = connected;
    _connectionStateController.add(Map.from(_deviceConnectionStates));
  }

  Future<bool> _sendCommandWithTimeout(
      fb.BluetoothDevice device, BluetoothCommand command) async {
    try {
      List<fb.BluetoothService> services = await device.discoverServices();
      var targetService = services.firstWhere(
        (service) => service.uuid.toString() == HC05_SERVICE_UUID,
        orElse: () => throw Exception('HC-05 service not found'),
      );

      var characteristic = targetService.characteristics.firstWhere(
        (char) => char.properties.write,
        orElse: () => throw Exception('Writable characteristic not found'),
      );

      // Encrypt command if needed
      final encodedCommand = _encryptCommand(command.command);
      await characteristic.write(utf8.encode(encodedCommand));

      // Wait for acknowledgment if needed
      final response = await characteristic.read();
      return _validateResponse(response);
    } catch (e) {
      AppLogger.error(
        'Command transmission failed',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }

  String _encryptCommand(String command) {
    // TODO: Implement proper encryption
    return command;
  }

  bool _validateResponse(List<int> response) {
    try {
      final decoded = utf8.decode(response);
      return decoded == 'OK';
    } catch (e) {
      AppLogger.error(
        'Failed to validate response',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }

  @override
  void dispose() {
    for (var subscription in _deviceStateSubscriptions.values) {
      subscription.cancel();
    }
    _deviceStateSubscriptions.clear();
    _connectedDevices.clear();
    _connectionStateController.close();
  }
}
