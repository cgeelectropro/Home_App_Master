import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_app/services/provider/bluetooth_provider.dart';
import 'package:home_app/services/provider/devices_provider.dart';
import 'package:home_app/utils/bluetooth_permission_handler.dart';
import 'package:home_app/utils/app_logger.dart';
import 'package:home_app/utils/error_handler.dart';
import 'package:home_app/components/confirmation_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;

  Future<void> _resetBluetoothConnection() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Reset Bluetooth',
      message:
          'This will disconnect all devices and reset Bluetooth connection. Continue?',
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final bluetoothProvider = context.read<BluetoothProvider>();

      // Reset Bluetooth service
      await bluetoothProvider.initialize();

      await AppLogger.log('Bluetooth connection reset successfully');
      ErrorHandler.showErrorSnackBar(
        context,
        'Bluetooth reset successful',
        isError: false,
      );
    } catch (e) {
      await AppLogger.logError(
          'Failed to reset Bluetooth', e, StackTrace.current);
      ErrorHandler.showErrorSnackBar(
          context, 'Failed to reset Bluetooth: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    try {
      final hasPermissions =
          await BluetoothPermissionHandler.checkAndRequestPermissions();

      if (!hasPermissions) {
        throw Exception('Not all permissions were granted');
      }

      await AppLogger.log('Permissions checked and granted');
      ErrorHandler.showErrorSnackBar(
        context,
        'All permissions granted',
        isError: false,
      );
    } catch (e) {
      await AppLogger.logError(
          'Permission check failed', e, StackTrace.current);
      ErrorHandler.showErrorSnackBar(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearDeviceData() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Clear All Data',
      message:
          'This will remove all devices and rooms. This action cannot be undone. Continue?',
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final devicesProvider = context.read<DeviceProvider>();

      // Get all devices and remove them
      final devices = devicesProvider.devices;
      for (final device in devices) {
        await devicesProvider.deleteDevice(device.id);
      }

      await AppLogger.log('All device data cleared');
      ErrorHandler.showErrorSnackBar(
        context,
        'All data cleared successfully',
        isError: false,
      );
    } catch (e) {
      await AppLogger.logError('Failed to clear data', e, StackTrace.current);
      ErrorHandler.showErrorSnackBar(
          context, 'Failed to clear data: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportLogs() async {
    setState(() => _isLoading = true);
    try {
      await AppLogger.exportLogs();
      ErrorHandler.showErrorSnackBar(
        context,
        'Logs exported successfully',
        isError: false,
      );
    } catch (e) {
      await AppLogger.logError('Failed to export logs', e, StackTrace.current);
      ErrorHandler.showErrorSnackBar(
          context, 'Failed to export logs: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Bluetooth',
            children: [
              ListTile(
                leading: const Icon(Icons.bluetooth),
                title: const Text('Reset Bluetooth Connection'),
                subtitle: const Text('Troubleshoot connection issues'),
                onTap: _isLoading ? null : _resetBluetoothConnection,
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Check Permissions'),
                subtitle: const Text('Verify required permissions'),
                onTap: _isLoading ? null : _checkPermissions,
              ),
            ],
          ),
          _buildSection(
            title: 'Data Management',
            children: [
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Clear All Data'),
                subtitle: const Text('Remove all devices and rooms'),
                onTap: _isLoading ? null : _clearDeviceData,
              ),
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Export Logs'),
                subtitle: const Text('Save logs for troubleshooting'),
                onTap: _isLoading ? null : _exportLogs,
              ),
            ],
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
