import 'dart:async';
import 'dart:collection';
import '../../utils/app_logger.dart';
import '../../models/bluetooth_command.dart';
import 'bluetooth_service.dart';

class CommandQueue {
  final BluetoothService _bluetoothService;
  final Map<CommandPriority, Queue<BluetoothCommand>> _queues = {
    CommandPriority.high: Queue<BluetoothCommand>(),
    CommandPriority.normal: Queue<BluetoothCommand>(),
    CommandPriority.low: Queue<BluetoothCommand>(),
  };

  final Map<String, List<BluetoothCommand>> _deviceHistory = {};
  final Map<String, int> _failedCommands = {};
  bool _isProcessing = false;
  Timer? _retryTimer;

  static const int MAX_HISTORY_PER_DEVICE = 50;
  static const int MAX_RETRY_COUNT = 3;
  static const Duration RETRY_DELAY = Duration(seconds: 2);

  CommandQueue(this._bluetoothService);

  Future<void> addCommand(BluetoothCommand command,
      {CommandPriority priority = CommandPriority.normal}) async {
    try {
      if (!await _bluetoothService.validateCommand(command)) {
        throw Exception('Invalid command format');
      }

      _queues[priority]!.add(command);
      _addToHistory(command);

      if (!_isProcessing) {
        _processQueue();
      }
    } catch (e) {
      AppLogger.error('Failed to add command', error: e, stackTrace: StackTrace.current);
      _incrementFailedCommands(command.deviceId);
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (_hasCommands()) {
        final command = _getNextCommand();
        if (command == null) break;

        final success = await _bluetoothService.sendWithRetry(
          command,
          maxRetries: MAX_RETRY_COUNT,
        );

        if (!success) {
          _incrementFailedCommands(command.deviceId);
          _scheduleRetry(command);
          break;
        }

        // Reset failed count on success
        _failedCommands.remove(command.deviceId);
      }
    } catch (e) {
      AppLogger.error('Error processing command queue', error: e, stackTrace: StackTrace.current);
    } finally {
      _isProcessing = false;
    }
  }

  bool _hasCommands() {
    return _queues.values.any((queue) => queue.isNotEmpty);
  }

  BluetoothCommand? _getNextCommand() {
    for (var priority in CommandPriority.values) {
      if (_queues[priority]!.isNotEmpty) {
        return _queues[priority]!.removeFirst();
      }
    }
    return null;
  }

  void _addToHistory(BluetoothCommand command) {
    _deviceHistory.putIfAbsent(command.deviceId, () => []);
    final history = _deviceHistory[command.deviceId]!;

    if (history.length >= MAX_HISTORY_PER_DEVICE) {
      history.removeAt(0);
    }

    history.add(command);
  }

  void _incrementFailedCommands(String deviceId) {
    _failedCommands[deviceId] = (_failedCommands[deviceId] ?? 0) + 1;
  }

  void _scheduleRetry(BluetoothCommand command) {
    _retryTimer?.cancel();
    _retryTimer = Timer(RETRY_DELAY, () {
      if (_failedCommands[command.deviceId]! < MAX_RETRY_COUNT) {
        addCommand(command, priority: CommandPriority.high);
      }
    });
  }

  List<BluetoothCommand> getDeviceHistory(String deviceId) {
    return List.unmodifiable(_deviceHistory[deviceId] ?? []);
  }

  bool hasFailedCommands(String deviceId) {
    return (_failedCommands[deviceId] ?? 0) > 0;
  }

  void clearQueue() {
    for (var queue in _queues.values) {
      queue.clear();
    }
    _retryTimer?.cancel();
    _isProcessing = false;
  }

  @override
  void dispose() {
    clearQueue();
    _deviceHistory.clear();
    _failedCommands.clear();
  }
}
