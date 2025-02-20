import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_app/models/device_model.dart';
import 'package:home_app/services/provider/devices_provider.dart';
import 'package:home_app/services/provider/bluetooth_provider.dart';
import 'package:home_app/utils/device_validator.dart';
import 'package:home_app/utils/error_handler.dart';
import 'package:home_app/utils/app_logger.dart';
import 'package:uuid/uuid.dart';

class AddDevicePage extends StatefulWidget {
  const AddDevicePage({super.key});

  @override
  _AddDevicePageState createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _macAddressController = TextEditingController();
  String _selectedType = 'light';
  bool _isScanning = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _macAddressController.dispose();
    super.dispose();
  }

  Future<void> _scanForDevices() async {
    final bluetoothProvider = context.read<BluetoothProvider>();

    setState(() => _isScanning = true);
    try {
      if (!bluetoothProvider.isInitialized) {
        await bluetoothProvider.initialize();
      }

      final scanResults = await bluetoothProvider.scanForDevices();
      if (scanResults.isNotEmpty) {
        setState(() {
          _macAddressController.text = scanResults.first.device.id.id;
        });
      } else {
        throw Exception('No devices found');
      }
    } catch (e) {
      await AppLogger.error(
          'Failed to scan for devices', e, StackTrace.current);
      ErrorHandler.showErrorSnackBar(
          context, 'Failed to scan: ${e.toString()}');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _addDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final devicesProvider = context.read<DeviceProvider>();
      final bluetoothProvider = context.read<BluetoothProvider>();

      final newDevice = Device(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        type: _selectedType,
        status: 'off',
        macAddress: _macAddressController.text.trim(),
        createdAt: DateTime.now(),
      );

      final validationError = DeviceValidator.validateDevice(newDevice);
      if (validationError != null) {
        throw Exception(validationError);
      }

      final connected = await bluetoothProvider.connectToDevice(newDevice);
      if (!connected) {
        throw Exception('Could not connect to device');
      }

      final success = await devicesProvider.addDevice(newDevice);
      if (!success) {
        throw Exception('Failed to add device');
      }

      await AppLogger.log('Added new device: ${newDevice.id}');
      Navigator.pop(context);
    } catch (e) {
      await AppLogger.logError('Failed to add device', e, StackTrace.current);
      ErrorHandler.showErrorSnackBar(
          context, 'Failed to add device: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a device name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Device Type',
                border: OutlineInputBorder(),
              ),
              items: DeviceValidator.SUPPORTED_DEVICE_TYPES.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedType = value!);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _macAddressController,
                    decoration: const InputDecoration(
                      labelText: 'MAC Address',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter MAC address';
                      }
                      if (!DeviceValidator.isValidMacAddress(value)) {
                        return 'Invalid MAC address format';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.bluetooth_searching),
                  onPressed: _isScanning ? null : _scanForDevices,
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _addDevice,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check),
      ),
    );
  }
}
