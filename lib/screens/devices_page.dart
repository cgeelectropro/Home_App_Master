import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_app/models/device_model.dart';
import 'package:home_app/services/provider/devices_provider.dart';
import 'package:home_app/services/provider/bluetooth_provider.dart';
import 'package:home_app/components/device_card.dart';
import 'package:home_app/utils/error_handler.dart';
import 'package:home_app/utils/app_logger.dart';
import 'package:home_app/components/confirmation_dialog.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  static String get route => '/devices';
  @override
  _DevicesPageState createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  bool _isLoading = false;
  String _filter = 'all'; // all, connected, disconnected
  String _sortBy = 'name'; // name, type, status

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    try {
      final devicesProvider = context.read<DeviceProvider>();
      await devicesProvider.fetchDevices();
    } catch (e) {
      await AppLogger.logError('Failed to load devices', e, StackTrace.current);
      ErrorHandler.showErrorSnackBar(
          context, 'Failed to load devices: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDevice(Device device) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Device',
      message: 'Are you sure you want to delete ${device.name}?',
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final devicesProvider = context.read<DeviceProvider>();
      final success = await devicesProvider.deleteDevice(device.id);

      if (!success) {
        throw Exception('Failed to delete device');
      }

      await AppLogger.log('Deleted device: ${device.id}');
    } catch (e) {
      await AppLogger.logError(
          'Failed to delete device', e, StackTrace.current);
      ErrorHandler.showErrorSnackBar(
          context, 'Failed to delete device: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Device> _filterAndSortDevices(List<Device> devices) {
    // Filter devices
    var filteredDevices = devices.where((device) {
      switch (_filter) {
        case 'connected':
          return device.isConnected;
        case 'disconnected':
          return !device.isConnected;
        default:
          return true;
      }
    }).toList();

    // Sort devices
    filteredDevices.sort((a, b) {
      switch (_sortBy) {
        case 'type':
          return a.type.compareTo(b.type);
        case 'status':
          return a.status.compareTo(b.status);
        default:
          return a.name.compareTo(b.name);
      }
    });

    return filteredDevices;
  }

  Future<void> _toggleDevice(Device device) async {
    try {
      final devicesProvider = context.read<DeviceProvider>();
      final success = await devicesProvider.toggleDevice(device.id);

      if (!success) {
        throw Exception('Failed to toggle device');
      }
    } catch (e) {
      await AppLogger.logError(
          'Failed to toggle device', e, StackTrace.current);
      ErrorHandler.showErrorSnackBar(
          context, 'Failed to toggle device: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Devices'),
              ),
              const PopupMenuItem(
                value: 'connected',
                child: Text('Connected'),
              ),
              const PopupMenuItem(
                value: 'disconnected',
                child: Text('Disconnected'),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() => _sortBy = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'name',
                child: Text('Sort by Name'),
              ),
              const PopupMenuItem(
                value: 'type',
                child: Text('Sort by Type'),
              ),
              const PopupMenuItem(
                value: 'status',
                child: Text('Sort by Status'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer2<DeviceProvider, BluetoothProvider>(
        builder: (context, devicesProvider, bluetoothProvider, _) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final devices = _filterAndSortDevices(devicesProvider.devices);

          if (devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No devices found'),
                  if (_filter != 'all') ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _filter = 'all'),
                      child: const Text('Show All Devices'),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadDevices,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return DeviceCard(
                  device: device,
                  onToggle: () => _toggleDevice(device),
                  onDelete: () => _deleteDevice(device),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add-device');
          if (result == true) {
            _loadDevices();
          }
        },
        tooltip: 'Add Device',
        child: const Icon(Icons.add),
      ),
    );
  }
}
