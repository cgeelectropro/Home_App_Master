import 'dart:convert';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:home_app/models/credentials.dart';
import 'package:home_app/services/api/pref_services.dart';
import 'package:home_app/utils/app_logger.dart';
import '../security/encryption_service.dart';
import '../offline/offline_storage_service.dart';

class APModeServices extends PrefServices {
  static const String HC05_SERVICE_UUID = "00001101-0000-1000-8000-00805F9B34FB";
  
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final EncryptionService _encryptionService;
  final OfflineStorageService _offlineStorage;
  bool _offlineMode = false;

  APModeServices({
    required EncryptionService encryptionService,
    required OfflineStorageService offlineStorage,
  })  : _encryptionService = encryptionService,
        _offlineStorage = offlineStorage;

  bool get isOfflineMode => _offlineMode;

  Future<void> enableOfflineMode() async {
    _offlineMode = true;
    // Cache current device states
    final devices = await getDevicesData();
    if (devices != null) {
      await _offlineStorage.cacheDeviceData(jsonDecode(devices));
    }
  }

  Future<void> disableOfflineMode() async {
    _offlineMode = false;
    // Execute pending commands
    final devices = await getDevicesData();
    if (devices != null) {
      final deviceMap = jsonDecode(devices) as Map<String, dynamic>;
      for (var deviceId in deviceMap.keys) {
        await _executePendingCommands(deviceId);
      }
    }
  }

  Future<void> _executePendingCommands(String deviceId) async {
    final pendingCommands = await _offlineStorage.getPendingCommands(deviceId);
    for (var command in pendingCommands) {
      try {
        final success = await sendData(
          command['command']['name'],
          command['command']['password'],
          configData: command['command'],
        );
        if (success) {
          await _offlineStorage.markCommandAsExecuted(deviceId, command['command']);
        }
      } catch (e) {
        AppLogger.logError('Failed to execute pending command', e, StackTrace.current);
      }
    }
  }

  @override
  Future<void> saveCredentials(Credentials credentials) async {
    try {
      final encrypted = _encryptionService.encrypt(jsonEncode(credentials.toMap()));
      await _offlineStorage.cacheDeviceData({'credentials': encrypted});
    } catch (e) {
      AppLogger.logError('Failed to save credentials', e, StackTrace.current);
      rethrow;
    }
  }

  @override
  Future<Credentials?> getCredentials() async {
    try {
      final cachedData = await _offlineStorage.getCachedDeviceData();
      if (cachedData == null) return null;

      final encrypted = cachedData['credentials'] as String;
      final decrypted = _encryptionService.decrypt(encrypted);
      return Credentials.fromMap(jsonDecode(decrypted));
    } catch (e) {
      AppLogger.logError('Failed to get credentials', e, StackTrace.current);
      return null;
    }
  }

  Future<bool> sendData(String deviceName, String devicePassword,
      {Map<String, dynamic>? configData}) async {
    try {
      if (_offlineMode) {
        // Cache command for later execution
        await _offlineStorage.cacheCommand(
          deviceName,
          configData ?? {'name': deviceName, 'password': devicePassword},
        );
        return true;
      }

      // Find and connect to device
      BluetoothDevice? targetDevice = await findDevice(deviceName);
      if (targetDevice == null) {
        throw Exception('Device not found');
      }

      // Prepare data to send with encryption
      final data = configData ?? {
        "name": deviceName,
        "password": devicePassword,
      };
      
      final encryptedData = _encryptionService.encrypt(jsonEncode(data));
      final signature = _encryptionService.generateHMAC(encryptedData);

      // Connect and send data
      await targetDevice.connect(timeout: const Duration(seconds: 5));
      List<BluetoothService> services = await targetDevice.discoverServices();

      // Find the HC-05 service
      for (BluetoothService service in services) {
        if (service.uuid.toString() == HC05_SERVICE_UUID) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.properties.write) {
              // Send encrypted data with signature
              final payload = {
                'data': encryptedData,
                'signature': signature,
              };
              
              await characteristic.write(utf8.encode(jsonEncode(payload)));
              
              // Wait for acknowledgment
              final response = await characteristic.read();
              final success = _validateResponse(response);
              
              await targetDevice.disconnect();
              return success;
            }
          }
        }
      }

      await targetDevice.disconnect();
      throw Exception('No writable characteristic found');
    } catch (e) {
      AppLogger.logError('Failed to send data to device', e, StackTrace.current);
      return false;
    }
  }

  bool _validateResponse(List<int> response) {
    try {
      final decoded = utf8.decode(response);
      final responseData = jsonDecode(decoded);
      
      // Verify response signature
      if (!_encryptionService.verifyHMAC(
        responseData['data'],
        responseData['signature'],
      )) {
        return false;
      }

      final decrypted = _encryptionService.decrypt(responseData['data']);
      return decrypted == 'OK';
    } catch (e) {
      return false;
    }
  }

  Future<bool> configureDevice(
    BluetoothDevice device,
    String name,
    String password,
  ) async {
    try {
      // Connect to device
      await device.connect();

      // Send configuration data
      final data = {'name': name, 'password': password};
      return await sendData(name, password, configData: data);
    } catch (e) {
      AppLogger.logError('Error configuring device', e, StackTrace.current);
      return false;
    }
  }

  @override
  void dispose() {
    flutterBlue.stopScan();
    super.dispose();
  }
}
