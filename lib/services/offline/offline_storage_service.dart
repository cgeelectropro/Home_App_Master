import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../security/encryption_service.dart';
import '../../utils/app_logger.dart';

class OfflineStorageService {
  static const String _deviceCacheKey = 'device_cache';
  static const String _commandCacheKey = 'command_cache';
  static const String _lastSyncKey = 'last_sync';

  final EncryptionService _encryptionService;
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  OfflineStorageService({
    required EncryptionService encryptionService,
    required FlutterSecureStorage secureStorage,
    required SharedPreferences prefs,
  })  : _encryptionService = encryptionService,
        _secureStorage = secureStorage,
        _prefs = prefs;

  Future<void> cacheDeviceData(Map<String, dynamic> deviceData) async {
    try {
      final encrypted = _encryptionService.encrypt(jsonEncode(deviceData));
      await _secureStorage.write(key: _deviceCacheKey, value: encrypted);
      await _updateLastSync();
    } catch (e) {
      AppLogger.error('Failed to cache device data', error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCachedDeviceData() async {
    try {
      final encrypted = await _secureStorage.read(key: _deviceCacheKey);
      if (encrypted == null) return null;

      final decrypted = _encryptionService.decrypt(encrypted);
      return jsonDecode(decrypted);
    } catch (e) {
      AppLogger.error('Failed to get cached device data', error: e, stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<void> cacheCommand(String deviceId, Map<String, dynamic> command) async {
    try {
      final commands = await _getCommandCache();
      commands.putIfAbsent(deviceId, () => []).add({
        'command': command,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending'
      });

      final encrypted = _encryptionService.encrypt(jsonEncode(commands));
      await _secureStorage.write(key: _commandCacheKey, value: encrypted);
    } catch (e) {
      AppLogger.error('Failed to cache command', error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingCommands(String deviceId) async {
    try {
      final commands = await _getCommandCache();
      return (commands[deviceId] ?? [])
          .where((cmd) => cmd['status'] == 'pending')
          .map((cmd) => Map<String, dynamic>.from(cmd))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get pending commands', error: e, stackTrace: StackTrace.current);
      return [];
    }
  }

  Future<void> markCommandAsExecuted(String deviceId, Map<String, dynamic> command) async {
    try {
      final commands = await _getCommandCache();
      final deviceCommands = commands[deviceId] ?? [];
      
      final index = deviceCommands.indexWhere((cmd) => 
        cmd['command'].toString() == command.toString() && 
        cmd['status'] == 'pending'
      );

      if (index != -1) {
        deviceCommands[index]['status'] = 'executed';
        deviceCommands[index]['executedAt'] = DateTime.now().toIso8601String();
        
        final encrypted = _encryptionService.encrypt(jsonEncode(commands));
        await _secureStorage.write(key: _commandCacheKey, value: encrypted);
      }
    } catch (e) {
      AppLogger.error('Failed to mark command as executed', error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  Future<Map<String, List<dynamic>>> _getCommandCache() async {
    try {
      final encrypted = await _secureStorage.read(key: _commandCacheKey);
      if (encrypted == null) return {};

      final decrypted = _encryptionService.decrypt(encrypted);
      return Map<String, List<dynamic>>.from(jsonDecode(decrypted));
    } catch (e) {
      AppLogger.error('Failed to get command cache', error: e, stackTrace: StackTrace.current);
      return {};
    }
  }

  Future<void> _updateLastSync() async {
    await _prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  Future<DateTime?> getLastSyncTime() async {
    final timeStr = _prefs.getString(_lastSyncKey);
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  Future<void> clearCache() async {
    try {
      await _secureStorage.delete(key: _deviceCacheKey);
      await _secureStorage.delete(key: _commandCacheKey);
      await _prefs.remove(_lastSyncKey);
    } catch (e) {
      AppLogger.error('Failed to clear cache', error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }
}
