import 'package:flutter/foundation.dart';

enum CommandPriority {
  high,
  normal,
  low,
}

enum CommandStatus {
  pending,
  executing,
  completed,
  failed,
  retrying
}

@immutable
class BluetoothCommand {
  final String deviceId;
  final String command;
  final Map<String, dynamic>? parameters;
  final DateTime timestamp;
  final CommandPriority priority;
  final int maxRetries;
  final Duration retryDelay;
  final bool isExecuted;
  final String? error;
  
  BluetoothCommand({
    required this.deviceId,
    required this.command,
    this.parameters,
    DateTime? timestamp,
    this.priority = CommandPriority.normal,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.isExecuted = false,
    this.error,
  }) : timestamp = timestamp ?? DateTime.now();

  BluetoothCommand copyWith({
    String? deviceId,
    String? command,
    Map<String, dynamic>? parameters,
    DateTime? timestamp,
    CommandPriority? priority,
    int? maxRetries,
    Duration? retryDelay,
    bool? isExecuted,
    String? error,
  }) {
    return BluetoothCommand(
      deviceId: deviceId ?? this.deviceId,
      command: command ?? this.command,
      parameters: parameters ?? this.parameters,
      timestamp: timestamp ?? this.timestamp,
      priority: priority ?? this.priority,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      isExecuted: isExecuted ?? this.isExecuted,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'command': command,
      'parameters': parameters,
      'timestamp': timestamp.toIso8601String(),
      'priority': priority.toString(),
      'maxRetries': maxRetries,
      'retryDelay': retryDelay.inMilliseconds,
      'isExecuted': isExecuted,
      'error': error,
    };
  }

  factory BluetoothCommand.fromMap(Map<String, dynamic> map) {
    return BluetoothCommand(
      deviceId: map['deviceId'] as String,
      command: map['command'] as String,
      parameters: map['parameters'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      priority: CommandPriority.values.firstWhere(
        (e) => e.toString() == map['priority'],
        orElse: () => CommandPriority.normal,
      ),
      maxRetries: map['maxRetries'] as int? ?? 3,
      retryDelay: Duration(milliseconds: map['retryDelay'] as int? ?? 1000),
      isExecuted: map['isExecuted'] as bool? ?? false,
      error: map['error'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BluetoothCommand &&
        other.deviceId == deviceId &&
        other.command == command &&
        mapEquals(other.parameters, parameters) &&
        other.timestamp == timestamp &&
        other.priority == priority &&
        other.maxRetries == maxRetries &&
        other.retryDelay == retryDelay &&
        other.isExecuted == isExecuted &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(
      deviceId,
      command,
      parameters,
      timestamp,
      priority,
      maxRetries,
      retryDelay,
      isExecuted,
      error,
    );
  }

  @override
  String toString() {
    return 'BluetoothCommand(deviceId: $deviceId, command: $command, parameters: $parameters, timestamp: $timestamp, priority: $priority, maxRetries: $maxRetries, retryDelay: $retryDelay, isExecuted: $isExecuted, error: $error)';
  }
}
