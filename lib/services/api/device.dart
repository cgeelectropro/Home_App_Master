import 'dart:convert';
import 'package:home_app/models/device_model.dart';
import 'package:home_app/services/provider/bluetooth_provider.dart';
import 'package:home_app/services/api/pref_services.dart';
import 'package:flutter_blue/flutter_blue.dart' as fb;

class DeviceServices {
  final PrefServices _prefServices = PrefServices();
  final BluetoothProvider _bluetoothProvider;
  static const String devicesKey = 'devices_data';

  DeviceServices(this._bluetoothProvider);

  Future<List<Device>> getDevices() async {
    try {
      final String? data = await _prefServices.loadFromPrefs(devicesKey);
      if (data != null) {
        List<dynamic> jsonData = json.decode(data);
        return jsonData.map((x) => Device.fromMap(x)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get devices: $e');
    }
  }

  Future<bool> addDevice(Device device) async {
    try {
      List<Device> devices = await getDevices();
      devices.add(device);
      await _prefServices.saveToPrefs(
        devicesKey,
        json.encode(devices.map((e) => e.toMap()).toList()),
      );
      return true;
    } catch (e) {
      throw Exception('Failed to add device: $e');
    }
  }

  Future<bool> updateDevice(Device device) async {
    try {
      List<Device> devices = await getDevices();
      final index = devices.indexWhere((d) => d.id == device.id);

      if (index != -1) {
        devices[index] = device;
        await _prefServices.saveToPrefs(
          devicesKey,
          json.encode(devices.map((e) => e.toMap()).toList()),
        );
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to update device: $e');
    }
  }

  Future<bool> deleteDevice(String id) async {
    try {
      List<Device> devices = await getDevices();
      devices.removeWhere((device) => device.id == id);
      await _prefServices.saveToPrefs(
        devicesKey,
        json.encode(devices.map((e) => e.toMap()).toList()),
      );
      return true;
    } catch (e) {
      throw Exception('Failed to delete device: $e');
    }
  }

  Future<bool> toggleDeviceStatus(String id) async {
    try {
      List<Device> devices = await getDevices();
      final deviceIndex = devices.indexWhere((d) => d.id == id);

      if (deviceIndex == -1) {
        throw Exception('Device not found');
      }

      final device = devices[deviceIndex];
      final newStatus = device.status == 'on' ? 'off' : 'on';

      // Find the Bluetooth device
      final bluetoothDevice = await _findBluetoothDevice(id);
      if (bluetoothDevice == null) {
        throw Exception('Bluetooth device not found');
      }

      // Send command to HC-05
      final command = _buildCommand(device.type, newStatus);
      final success = await _bluetoothProvider.sendCommand(
          _convertToAppDevice(bluetoothDevice), command);

      if (success) {
        // Update local state
        devices[deviceIndex] = device.copyWith(status: newStatus);
        await _prefServices.saveToPrefs(
          devicesKey,
          json.encode(devices.map((e) => e.toMap()).toList()),
        );
        return true;
      }

      throw Exception('Failed to send command to device');
    } catch (e) {
      throw Exception('Failed to toggle device: $e');
    }
  }

  Future<fb.BluetoothDevice?> _findBluetoothDevice(String id) async {
    try {
      final devices = await fb.FlutterBlue.instance.connectedDevices;
      return devices.firstWhere((device) => device.id.id == id);
    } catch (e) {
      return null;
    }
  }

  String _buildCommand(String deviceType, String status) {
    // Command format: <device_type>:<action>
    // Example: "light:on", "fan:off"
    return '$deviceType:$status';
  }

  Device _convertToAppDevice(fb.BluetoothDevice bluetoothDevice) {
    return Device(
      id: bluetoothDevice.id.id,
      name: bluetoothDevice.name,
      type: 'unknown', // Set appropriate default type
      status: 'off', // Set appropriate default status
      macAddress: bluetoothDevice.id.id,
      createdAt: DateTime.now(),
    );
  }

  Future<List<Device>> getDevicesByIds(List<String> deviceIds) async {
    try {
      final allDevices = await getDevices();
      return allDevices
          .where((device) => deviceIds.contains(device.id))
          .toList();
    } catch (e) {
      print('Error getting devices by IDs: $e');
      return [];
    }
  }
}
