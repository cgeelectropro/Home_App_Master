import 'dart:async';
import '../../models/bluetooth_command.dart';
import '../../models/device_model.dart';
import 'bluetooth_service.dart';
import '../../utils/app_logger.dart';

class BluetoothCommandHandler {
  final BluetoothService _bluetoothService;
  final Map<String, Completer<bool>> _pendingCommands = {};
  final Map<String, Timer> _commandTimeouts = {};

  static const int COMMAND_TIMEOUT = 5; // seconds
  static const int MAX_RETRIES = 3;

  BluetoothCommandHandler(this._bluetoothService);

  Future<bool> sendDeviceCommand(Device device, String action) async {
    final command = device.getCommand(action);
    final commandId = '${device.id}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // Create a completer for this command
      final completer = Completer<bool>();
      _pendingCommands[commandId] = completer;

      // Set command timeout
      _setCommandTimeout(commandId);

      // Create and send the command
      final bluetoothCommand = BluetoothCommand(
        deviceId: device.id,
        command: command,
      );

      // Log the command attempt
      await AppLogger.error(
        'Sending command',
        error: command,
        stackTrace: StackTrace.current,
      );

      // Attempt to send command with retries
      bool success = false;
      int attempts = 0;

      while (!success && attempts < MAX_RETRIES) {
        try {
          success = await _bluetoothService.sendCommand(bluetoothCommand);
          if (success) break;
        } catch (e) {
          attempts++;
          if (attempts >= MAX_RETRIES) rethrow;
          await Future.delayed(Duration(milliseconds: 500 * attempts));
        }
      }

      // Log the command result
      await AppLogger.error(
        'Command result',
        error: 'Device ${device.id}, Command: $command, Success: $success',
        stackTrace: StackTrace.current,
      );

      // Clean up
      _cleanupCommand(commandId);

      return success;
    } catch (e) {
      // Log the error
      await AppLogger.error(
        'Failed to send command to device',
        error: 'Device: ${device.id}, Error: $e',
        stackTrace: StackTrace.current,
      );

      // Clean up
      _cleanupCommand(commandId);

      rethrow;
    }
  }

  void _setCommandTimeout(String commandId) {
    _commandTimeouts[commandId] = Timer(
      const Duration(seconds: COMMAND_TIMEOUT),
      () => _handleCommandTimeout(commandId),
    );
  }

  void _handleCommandTimeout(String commandId) {
    final completer = _pendingCommands[commandId];
    if (completer != null && !completer.isCompleted) {
      completer.complete(false);
      AppLogger.error(
        'Command timeout',
        error: 'Command $commandId timed out',
        stackTrace: StackTrace.current,
      );
    }
    _cleanupCommand(commandId);
  }

  void _cleanupCommand(String commandId) {
    _pendingCommands.remove(commandId);
    _commandTimeouts[commandId]?.cancel();
    _commandTimeouts.remove(commandId);
  }

  Future<bool> verifyDeviceResponse(Device device) async {
    try {
      // Send a status check command
      final statusCommand = device.getCommand('STATUS');
      final bluetoothCommand = BluetoothCommand(
        deviceId: device.id,
        command: statusCommand,
      );

      return await _bluetoothService.sendCommand(bluetoothCommand);
    } catch (e) {
      await AppLogger.error(
        'Failed to verify device response',
        error: 'Device: ${device.id}, Error: $e',
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }

  void dispose() {
    for (var timer in _commandTimeouts.values) {
      timer.cancel();
    }
    _commandTimeouts.clear();
    _pendingCommands.clear();
  }
}
