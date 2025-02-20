import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class BluetoothPermissionHandler {
  static Future<bool> checkAndRequestPermissions() async {
    try {
      // Check location permission (required for Bluetooth scanning on Android)
      if (await Permission.location.isDenied) {
        final status = await Permission.location.request();
        if (!status.isGranted) {
          return false;
        }
      }

      // Check Bluetooth permissions
      if (await Permission.bluetooth.isDenied) {
        final status = await Permission.bluetooth.request();
        if (!status.isGranted) {
          return false;
        }
      }

      if (await Permission.bluetoothScan.isDenied) {
        final status = await Permission.bluetoothScan.request();
        if (!status.isGranted) {
          return false;
        }
      }

      if (await Permission.bluetoothConnect.isDenied) {
        final status = await Permission.bluetoothConnect.request();
        if (!status.isGranted) {
          return false;
        }
      }

      return true;
    } on PlatformException catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  static Future<bool> isBluetoothPermissionGranted() async {
    return await Permission.bluetooth.isGranted &&
        await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted;
  }

  static Future<bool> isLocationPermissionGranted() async {
    return await Permission.location.isGranted;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
