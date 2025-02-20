import 'package:flutter/material.dart';
import 'package:home_app/components/device_card.dart';
import 'package:home_app/services/provider/devices_provider.dart';
import 'package:provider/provider.dart';
import 'package:home_app/models/device_model.dart';

class MyDevicesPage extends StatefulWidget {
  static const route = '/myDevices';

  const MyDevicesPage({super.key});

  @override
  _MyDevicesPageState createState() => _MyDevicesPageState();
}

class _MyDevicesPageState extends State<MyDevicesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DeviceProvider>(context, listen: false).fetchDevices();
    });
  }

  Future<void> _toggleDeviceStatus(String deviceId) async {
    try {
      await Provider.of<DeviceProvider>(context, listen: false)
          .toggleDevice(deviceId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling device: $e')),
        );
      }
    }
  }

  Future<void> _handleDeviceDelete(Device device) async {
    try {
      await Provider.of<DeviceProvider>(context, listen: false)
          .deleteDevice(device.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting device: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Devices'),
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, deviceProvider, child) {
          if (deviceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (deviceProvider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${deviceProvider.error}'),
                  ElevatedButton(
                    onPressed: () {
                      deviceProvider.clearError();
                      deviceProvider.fetchDevices();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (deviceProvider.devices.isEmpty) {
            return const Center(
              child: Text('No devices found. Add a device to get started!'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: deviceProvider.devices.length,
            itemBuilder: (context, index) {
              final device = deviceProvider.devices[index];
              return DeviceCard(
                device: device,
                onToggle: () => _toggleDeviceStatus(device.id),
                onDelete: () => _handleDeviceDelete(device),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/addDevice'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
