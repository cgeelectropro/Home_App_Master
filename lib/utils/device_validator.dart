import 'package:home_app/models/device_model.dart';

class DeviceValidator {
  static const List<String> SUPPORTED_DEVICE_TYPES = [
    'light',
    'fan',
    'ac',
    'tv',
    'door',
    'camera'
  ];

  static const Map<String, List<String>> VALID_COMMANDS = {
    'light': ['ON', 'OFF', 'TOGGLE', 'DIM'],
    'fan': ['ON', 'OFF', 'SPEED1', 'SPEED2', 'SPEED3'],
    'ac': ['ON', 'OFF', 'TEMP+', 'TEMP-', 'MODE'],
    'tv': ['ON', 'OFF', 'VOL+', 'VOL-', 'CH+', 'CH-'],
    'door': ['OPEN', 'CLOSE', 'LOCK', 'UNLOCK'],
    'camera': ['ON', 'OFF', 'RECORD', 'SNAPSHOT']
  };

  static bool isValidDeviceType(String type) {
    return SUPPORTED_DEVICE_TYPES.contains(type.toLowerCase());
  }

  static bool isValidCommand(String type, String command) {
    final validCommands = VALID_COMMANDS[type.toLowerCase()];
    return validCommands?.contains(command.toUpperCase()) ?? false;
  }

  static bool isValidMacAddress(String? macAddress) {
    if (macAddress == null) return false;

    final RegExp macRegex =
        RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    return macRegex.hasMatch(macAddress);
  }

  static String? validateDevice(Device device) {
    if (!isValidDeviceType(device.type)) {
      return 'Invalid device type: ${device.type}';
    }

    if (device.macAddress != null && !isValidMacAddress(device.macAddress)) {
      return 'Invalid MAC address: ${device.macAddress}';
    }

    if (!['on', 'off'].contains(device.status.toLowerCase())) {
      return 'Invalid device status: ${device.status}';
    }

    return null;
  }

  static String? validateSettings(Map<String, dynamic> settings) {
    if (settings.isEmpty) {
      return 'Settings cannot be empty';
    }

    // Validate required settings fields
    if (!settings.containsKey('name')) {
      return 'Device name is required in settings';
    }

    if (!settings.containsKey('room')) {
      return 'Room assignment is required in settings';
    }

    // Validate setting values
    if (settings['name'] is! String || (settings['name'] as String).isEmpty) {
      return 'Invalid device name in settings';
    }

    if (settings['room'] is! String || (settings['room'] as String).isEmpty) {
      return 'Invalid room assignment in settings';
    }

    return null;
  }

  static bool canExecuteCommand(Device device, String command) {
    if (!isValidDeviceType(device.type)) return false;
    if (!isValidCommand(device.type, command)) return false;
    if (!device.isConnected) return false;
    return true;
  }

  static Map<String, dynamic>? validateSettingsType(
      String type, Map<String, dynamic>? settings) {
    if (settings == null) return null;

    switch (type.toLowerCase()) {
      case 'light':
        return _validateLightSettings(settings);
      case 'fan':
        return _validateFanSettings(settings);
      case 'ac':
        return _validateACSettings(settings);
      default:
        return settings;
    }
  }

  static Map<String, dynamic>? _validateLightSettings(
      Map<String, dynamic> settings) {
    var validated = Map<String, dynamic>.from(settings);

    // Validate brightness
    if (validated.containsKey('brightness')) {
      var brightness = validated['brightness'];
      if (brightness is num) {
        validated['brightness'] = brightness.clamp(0, 100);
      } else {
        validated.remove('brightness');
      }
    }

    return validated;
  }

  static Map<String, dynamic>? _validateFanSettings(
      Map<String, dynamic> settings) {
    var validated = Map<String, dynamic>.from(settings);

    // Validate speed
    if (validated.containsKey('speed')) {
      var speed = validated['speed'];
      if (speed is num) {
        validated['speed'] = speed.clamp(1, 3);
      } else {
        validated.remove('speed');
      }
    }

    return validated;
  }

  static Map<String, dynamic>? _validateACSettings(
      Map<String, dynamic> settings) {
    var validated = Map<String, dynamic>.from(settings);

    // Validate temperature
    if (validated.containsKey('temperature')) {
      var temp = validated['temperature'];
      if (temp is num) {
        validated['temperature'] = temp.clamp(16, 30);
      } else {
        validated.remove('temperature');
      }
    }

    // Validate mode
    if (validated.containsKey('mode')) {
      var mode = validated['mode'];
      if (!['cool', 'heat', 'fan', 'auto'].contains(mode)) {
        validated.remove('mode');
      }
    }

    return validated;
  }
}
