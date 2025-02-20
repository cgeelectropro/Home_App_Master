import 'package:flutter/material.dart';
import 'package:home_app/components/show_loading.dart';
import 'package:home_app/models/device_model.dart';
import 'package:home_app/services/ap_mode/add_device_services.dart';
import 'package:home_app/services/provider/devices_provider.dart';
import 'package:home_app/services/provider/collection_provider.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:provider/provider.dart';

///Add new device with AP mode
class AddDevicePage extends StatefulWidget {
  static const route = '/addDevice';
  final String? collectionId;

  const AddDevicePage({super.key, this.collectionId});

  @override
  _AddDevicePageState createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  final APModeServices _apServices = APModeServices();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  List<ScanResult> _deviceList = [];
  bool _isScanning = false;
  String _error = '';
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _apServices.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _error = '';
      _deviceList = [];
    });

    try {
      if (!await _apServices.isBluetoothReady()) {
        throw Exception('Bluetooth is not ready');
      }

      FlutterBlue.instance.scanResults.listen((results) {
        setState(() {
          _deviceList = results.where((result) {
            // Filter for HC-05 devices
            return result.device.name.toLowerCase().contains('hc-05') ||
                result.device.name.toLowerCase().contains('smart_home');
          }).toList();
        });
      });

      await FlutterBlue.instance.startScan(timeout: const Duration(seconds: 4));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _addDevice() async {
    if (!_formKey.currentState!.validate() || _selectedDevice == null) return;

    showLoading(context);

    try {
      // Connect to device and send credentials
      final success = await _apServices.configureDevice(
        _selectedDevice!,
        _nameController.text,
        _passwordController.text,
      );

      if (!success) throw Exception('Failed to configure device');

      // Create device in app
      final newDevice = Device(
        id: _selectedDevice!.id.id,
        name: _nameController.text,
        type: 'smart_device',
        status: 'off',
        createdAt: DateTime.now(),
      );

      // Add device to provider
      final deviceProvider =
          Provider.of<DeviceProvider>(context, listen: false);
      await deviceProvider.addDevice(newDevice);

      // Add device to collection if collectionId is provided
      if (widget.collectionId != null) {
        final collectionProvider =
            Provider.of<CollectionProvider>(context, listen: false);
        await collectionProvider.addDeviceToCollection(
          widget.collectionId!,
          newDevice.id,
        );
      }

      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        Navigator.pop(context); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding device: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startScan,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Devices',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (_error.isNotEmpty)
                Text(
                  _error,
                  style: const TextStyle(color: Colors.red),
                ),
              if (_isScanning)
                const Center(child: CircularProgressIndicator())
              else if (_deviceList.isEmpty)
                const Center(
                  child: Text('No devices found. Tap refresh to scan again.'),
                ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _deviceList.length,
                itemBuilder: (context, index) {
                  final device = _deviceList[index].device;
                  return RadioListTile<BluetoothDevice>(
                    title: Text(device.name),
                    subtitle: Text(device.id.id),
                    value: device,
                    groupValue: _selectedDevice,
                    onChanged: (BluetoothDevice? value) {
                      setState(() => _selectedDevice = value);
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
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
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Device Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a device password';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectedDevice == null ? null : _addDevice,
        child: const Icon(Icons.add),
      ),
    );
  }
}
