import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_app/services/provider/bluetooth_provider.dart';
import 'package:home_app/services/provider/devices_provider.dart';
import 'package:home_app/services/provider/collection_provider.dart';
import 'package:home_app/utils/bluetooth_permission_handler.dart';
import 'package:home_app/utils/app_logger.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String _status = 'Initializing...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Check permissions
      setState(() => _status = 'Checking permissions...');
      final hasPermissions =
          await BluetoothPermissionHandler.checkAndRequestPermissions();
      if (!hasPermissions) {
        throw Exception('Required permissions not granted');
      }

      // Initialize Bluetooth
      setState(() => _status = 'Initializing Bluetooth...');
      final bluetoothProvider = context.read<BluetoothProvider>();
      await bluetoothProvider.initialize();

      // Load devices
      setState(() => _status = 'Loading devices...');
      final devicesProvider = context.read<DeviceProvider>();
      await devicesProvider.fetchDevices();

      // Load collections
      setState(() => _status = 'Loading rooms...');
      final collectionProvider = context.read<CollectionProvider>();
      await collectionProvider.loadCollections();

      await AppLogger.log('App initialized successfully');

      // Navigate to home
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() {
        _status = 'Error: ${e.toString()}';
        _hasError = true;
      });
      await AppLogger.logError('Initialization failed', e, StackTrace.current);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo or Icon
            Icon(
              Icons.home,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),

            // App Name
            Text(
              'Smart Home',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 48),

            // Loading Indicator or Error
            if (!_hasError) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                _status,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _status,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _status = 'Initializing...';
                    _hasError = false;
                  });
                  _initialize();
                },
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
