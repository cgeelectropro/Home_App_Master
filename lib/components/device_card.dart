import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_app/models/device_model.dart';
import 'package:home_app/services/provider/bluetooth_provider.dart';
import 'package:home_app/utils/error_handler.dart';
import 'package:home_app/utils/app_logger.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onToggle,
    required this.onDelete,
  });

  Future<void> _handleToggle(BuildContext context) async {
    try {
      final bluetoothProvider = context.read<BluetoothProvider>();

      // Check if device is connected
      if (!device.isConnected) {
        // Show connecting indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connecting to ${device.name}...'),
            duration: const Duration(seconds: 1),
          ),
        );

        // Attempt to connect
        final connected = await bluetoothProvider.connectToDevice(device);
        if (!connected) {
          throw Exception('Failed to connect to device');
        }
      }

      onToggle();
    } catch (e) {
      await AppLogger.logError(
        'Failed to toggle device: ${device.id}',
        e,
        StackTrace.current,
      );
      ErrorHandler.showErrorSnackBar(
        context,
        'Failed to toggle device: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.lightbulb_outline,
          color:
              device.status.toLowerCase() == 'on' ? Colors.yellow : Colors.grey,
        ),
        title: Text(device.name),
        subtitle: Text(device.type),
        trailing: Switch(
          value: device.status.toLowerCase() == 'on',
          onChanged: (_) => _handleToggle(context),
        ),
        onLongPress: onDelete,
      ),
    );
  }
}
