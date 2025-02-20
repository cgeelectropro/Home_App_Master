import 'package:flutter/material.dart';
import 'package:home_app/components/device_card.dart';
import 'package:home_app/services/provider/collection_provider.dart';
import 'package:home_app/services/provider/devices_provider.dart';
import 'package:provider/provider.dart';
import 'package:home_app/models/collections.dart';
import 'package:home_app/models/device_model.dart';
import 'package:home_app/utils/error_handler.dart';
import 'package:home_app/utils/app_logger.dart';

class RoomPage extends StatefulWidget {
  final Collection collection;

  const RoomPage({super.key, required this.collection});

  @override
  _RoomPageState createState() => _RoomPageState();

  static String get route => '/room';
}

class _RoomPageState extends State<RoomPage> {
  bool _isLoading = false;

  Future<void> _handleDeviceToggle(Device device) async {
    try {
      final devicesProvider = context.read<DeviceProvider>();
      final success = await devicesProvider.toggleDevice(device.id);

      if (!success) {
        throw Exception('Failed to toggle device');
      }
    } catch (e) {
      await AppLogger.logError(
        'Failed to toggle device in room',
        e,
        StackTrace.current,
      );
      ErrorHandler.showErrorSnackBar(
        context,
        'Failed to toggle device: ${e.toString()}',
      );
    }
  }

  Future<void> _handleDeviceRemove(Device device) async {
    try {
      setState(() => _isLoading = true);

      final collectionProvider = context.read<CollectionProvider>();
      final success = await collectionProvider.removeDeviceFromCollection(
        widget.collection.id,
        device.id,
      );

      if (!success) {
        throw Exception('Failed to remove device from room');
      }

      await AppLogger.log(
        'Removed device ${device.id} from room ${widget.collection.id}',
      );
    } catch (e) {
      await AppLogger.logError(
        'Failed to remove device from room',
        e,
        StackTrace.current,
      );
      ErrorHandler.showErrorSnackBar(
        context,
        'Failed to remove device: ${e.toString()}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAllDevices(bool turnOn) async {
    setState(() => _isLoading = true);
    try {
      final devicesProvider = context.read<DeviceProvider>();
      final devices = widget.collection.devices
          .map((id) => devicesProvider.getDeviceById(id))
          .where((device) => device != null)
          .cast<Device>()
          .toList();

      for (final device in devices) {
        if (device.status.toLowerCase() == (turnOn ? 'off' : 'on')) {
          await devicesProvider.toggleDevice(device.id);
        }
      }

      await AppLogger.log(
        'Toggled all devices in room ${widget.collection.id} to ${turnOn ? 'on' : 'off'}',
      );
    } catch (e) {
      await AppLogger.logError(
        'Failed to toggle all devices',
        e,
        StackTrace.current,
      );
      ErrorHandler.showErrorSnackBar(
        context,
        'Failed to toggle all devices: ${e.toString()}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.collection.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb),
            onPressed: _isLoading ? null : () => _toggleAllDevices(true),
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _isLoading ? null : () => _toggleAllDevices(false),
          ),
        ],
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, devicesProvider, _) {
          final devices = widget.collection.devices
              .map((id) => devicesProvider.getDeviceById(id))
              .where((device) => device != null)
              .cast<Device>()
              .toList();

          if (devices.isEmpty) {
            return const Center(
              child: Text('No devices in this room'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return DeviceCard(
                device: device,
                onToggle: () => _handleDeviceToggle(device),
                onDelete: () => _handleDeviceRemove(device),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
              context, '/add-device-to-room',
              arguments: widget.collection);
          if (result == true) {
            // Refresh the collection provider to update the UI
            context.read<CollectionProvider>().refreshCollections();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DeviceDetailsSheet extends StatelessWidget {
  final Device device;

  const DeviceDetailsSheet({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Device Details'),
            subtitle: Text(device.name),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Status'),
            subtitle: Text(device.status),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Type'),
            subtitle: Text(device.type),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/deviceEdit',
                arguments: device,
              );
            },
            child: const Text('Edit Device'),
          ),
        ],
      ),
    );
  }
}
