import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? tag;
  final dynamic error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.toString(),
    'message': message,
    'tag': tag,
    'error': error?.toString(),
    'stackTrace': stackTrace?.toString(),
  };

  @override
  String toString() {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
    final buffer = StringBuffer();
    
    buffer.write('[${dateFormat.format(timestamp)}]');
    buffer.write('[${level.toString().toUpperCase()}]');
    if (tag != null) buffer.write('[$tag]');
    buffer.write(' $message');
    
    if (error != null) {
      buffer.write('\nError: $error');
      if (stackTrace != null) {
        buffer.write('\nStackTrace:\n$stackTrace');
      }
    }
    
    return buffer.toString();
  }
}

class AppLogger {
  static const String LOG_FILE_NAME = 'app_logs.txt';
  static const int MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
  static const int MAX_BACKUP_FILES = 5;
  
  static bool _initialized = false;
  static late File _logFile;
  static LogLevel _minLogLevel = LogLevel.debug;
  static final List<void Function(LogEntry)> _listeners = [];

  static Future<void> initialize({LogLevel minLogLevel = LogLevel.debug}) async {
    if (_initialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/$LOG_FILE_NAME');
      _minLogLevel = minLogLevel;
      _initialized = true;

      // Create log file if it doesn't exist
      if (!await _logFile.exists()) {
        await _logFile.create(recursive: true);
      }

      // Check file size and rotate if needed
      await _checkAndRotateLogFile();
    } catch (e) {
      debugPrint('Failed to initialize logger: $e');
    }
  }

  static Future<void> _checkAndRotateLogFile() async {
    try {
      if (!await _logFile.exists()) return;

      final fileSize = await _logFile.length();
      if (fileSize > MAX_FILE_SIZE) {
        // Rotate existing backup files
        for (var i = MAX_BACKUP_FILES - 1; i >= 1; i--) {
          final file = File('${_logFile.path}.$i');
          if (await file.exists()) {
            if (i == MAX_BACKUP_FILES - 1) {
              await file.delete();
            } else {
              await file.rename('${_logFile.path}.${i + 1}');
            }
          }
        }

        // Rename current log file
        await _logFile.rename('${_logFile.path}.1');
        
        // Create new log file
        _logFile = File('${_logFile.path}');
        await _logFile.create();
      }
    } catch (e) {
      debugPrint('Failed to rotate log files: $e');
    }
  }

  static void addListener(void Function(LogEntry) listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function(LogEntry) listener) {
    _listeners.remove(listener);
  }

  static Future<void> _writeLogEntry(LogEntry entry) async {
    if (!_initialized) await initialize();

    try {
      await _checkAndRotateLogFile();
      await _logFile.writeAsString('${entry.toString()}\n', mode: FileMode.append);
      
      // Notify listeners
      for (final listener in _listeners) {
        listener(entry);
      }

      if (kDebugMode) {
        debugPrint(entry.toString());
      }
    } catch (e) {
      debugPrint('Failed to write log: $e');
    }
  }

  static Future<void> log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) async {
    if (level.index < _minLogLevel.index) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );

    await _writeLogEntry(entry);
  }

  static Future<void> debug(String message, {String? tag}) async {
    await log(message, level: LogLevel.debug, tag: tag);
  }

  static Future<void> info(String message, {String? tag}) async {
    await log(message, level: LogLevel.info, tag: tag);
  }

  static Future<void> warning(String message, {String? tag, dynamic error}) async {
    await log(message, level: LogLevel.warning, tag: tag, error: error);
  }

  static Future<void> error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) async {
    await log(
      message,
      level: LogLevel.error,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static Future<void> critical(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) async {
    await log(
      message,
      level: LogLevel.critical,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static Future<void> logBluetoothEvent(
    String event, {
    String? deviceId,
    LogLevel level = LogLevel.info,
  }) async {
    await log(
      'Bluetooth Event: $event${deviceId != null ? ' (Device: $deviceId)' : ''}',
      level: level,
      tag: 'BLUETOOTH',
    );
  }

  static Future<void> logDeviceCommand(
    String deviceId,
    String command,
    bool success, {
    dynamic error,
    StackTrace? stackTrace,
  }) async {
    final level = success ? LogLevel.info : LogLevel.error;
    await log(
      'Device Command - ID: $deviceId, Command: $command, Success: $success',
      level: level,
      tag: 'COMMAND',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static Future<List<LogEntry>> getLogEntries({
    DateTime? startTime,
    DateTime? endTime,
    LogLevel? minLevel,
    String? tag,
    int? limit,
  }) async {
    if (!_initialized) await initialize();

    try {
      final content = await _logFile.readAsString();
      final lines = content.split('\n').where((line) => line.isNotEmpty);
      
      final entries = <LogEntry>[];
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
      
      for (final line in lines) {
        try {
          // Parse timestamp
          final timestampMatch = RegExp(r'\[(.*?)\]').firstMatch(line);
          if (timestampMatch == null) continue;
          
          final timestamp = dateFormat.parse(timestampMatch.group(1)!);
          
          // Apply time filters
          if (startTime != null && timestamp.isBefore(startTime)) continue;
          if (endTime != null && timestamp.isAfter(endTime)) continue;
          
          // Parse level
          final levelMatch = RegExp(r'\[(DEBUG|INFO|WARNING|ERROR|CRITICAL)\]').firstMatch(line);
          if (levelMatch == null) continue;
          
          final level = LogLevel.values.firstWhere(
            (l) => l.toString().toUpperCase() == levelMatch.group(1),
          );
          
          // Apply level filter
          if (minLevel != null && level.index < minLevel.index) continue;
          
          // Parse tag
          String? parsedTag;
          final tagMatch = RegExp(r'\[([^\]]+)\](?!\[)').allMatches(line).toList();
          if (tagMatch.length > 2) {
            parsedTag = tagMatch[2].group(1);
          }
          
          // Apply tag filter
          if (tag != null && parsedTag != tag) continue;
          
          // Parse message and error
          final parts = line.split(RegExp(r'\][^[]*\[|\]'));
          final message = parts.last.trim();
          
          entries.add(LogEntry(
            timestamp: timestamp,
            level: level,
            message: message,
            tag: parsedTag,
          ));
          
          if (limit != null && entries.length >= limit) break;
        } catch (e) {
          debugPrint('Failed to parse log line: $e');
        }
      }
      
      return entries;
    } catch (e) {
      debugPrint('Failed to read logs: $e');
      return [];
    }
  }

  static Future<void> clearLogs() async {
    if (!_initialized) await initialize();

    try {
      await _logFile.writeAsString('');
      await log('Logs cleared', level: LogLevel.info, tag: 'SYSTEM');
    } catch (e) {
      debugPrint('Failed to clear logs: $e');
    }
  }

  static Future<File?> exportLogs({String? customPath}) async {
    if (!_initialized) await initialize();

    try {
      final directory = customPath != null
          ? Directory(customPath)
          : await getExternalStorageDirectory();
          
      if (directory == null) throw Exception('Export directory not available');

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final exportFile = File('${directory.path}/logs_$timestamp.txt');
      
      await _logFile.copy(exportFile.path);
      
      await log(
        'Logs exported to ${exportFile.path}',
        level: LogLevel.info,
        tag: 'SYSTEM',
      );
      
      return exportFile;
    } catch (e) {
      await error(
        'Failed to export logs',
        tag: 'SYSTEM',
        error: e,
        stackTrace: StackTrace.current,
      );
      return null;
    }
  }
}
