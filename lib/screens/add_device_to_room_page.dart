import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_app/models/collections.dart';
import 'package:home_app/services/provider/devices_provider.dart';
import 'package:home_app/services/provider/collection_provider.dart';
import 'package:home_app/utils/error_handler.dart';
import 'package:home_app/utils/app_logger.dart';

class AddDeviceToRoomPage extends StatefulWidget {
  final Collection collection;

  const AddDeviceToRoomPage({super.key, required this.collection});

  @override
  _AddDeviceToRoomPageState createState() => _AddDeviceToRoomPageState();
}

class _AddDeviceToRoomPageState extends State<AddDeviceToRoomPage> {
  bool _isLoading = false;
  final List<String> _selectedDevices = [];

  Future<void> _addDevicesToRoom() async {
    if (_selectedDevices.isEmpty) {
      ErrorHandler.showErrorSnackBar(
          context, 'Please select at least one device');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final collectionProvider = context.read<CollectionProvider>();

      for (final deviceId in _selectedDevices) {
        final success = await collectionProvider.addDeviceToCollection(
          widget.collection.id,
          deviceId,
        );

        if (!success) {
          throw Exception('Failed to add device $deviceId to room');
        }
      }

      await AppLogger.log(
        'Added ${_selectedDevices.length} devices to room ${widget.collection.id}',
      );

      Navigator.pop(context, true);
    } catch (e) {
      await AppLogger.logError(
        'Failed to add devices to room',
        e,
        StackTrace.current,
      );
      ErrorHandler.showErrorSnackBar(
        context,
        'Failed to add devices: ${e.toString()}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Devices to ${widget.collection.name}'),
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, devicesProvider, _) {
          // Get all devices that aren't already in the room
          final availableDevices = devicesProvider.devices
              .where((device) => !widget.collection.devices.contains(device.id))
              .toList();

          if (availableDevices.isEmpty) {
            return const Center(
              child: Text('No available devices to add'),
            );
          }

          return ListView.builder(
            itemCount: availableDevices.length,
            itemBuilder: (context, index) {
              final device = availableDevices[index];
              final isSelected = _selectedDevices.contains(device.id);

              return CheckboxListTile(
                title: Text(device.name),
                subtitle: Text(device.type),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedDevices.add(device.id);
                    } else {
                      _selectedDevices.remove(device.id);
                    }
                  });
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _addDevicesToRoom,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check),
      ),
    );
  }
}
