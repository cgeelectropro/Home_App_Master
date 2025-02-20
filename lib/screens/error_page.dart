import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_app/services/provider/bluetooth_provider.dart';
import 'package:home_app/utils/app_logger.dart';
import 'package:home_app/utils/error_handler.dart';

class ErrorPage extends StatelessWidget {
  final String title;
  final String message;
  final String? errorCode;
  final Function()? onRetry;
  final bool canGoBack;

  const ErrorPage({
    super.key,
    required this.title,
    required this.message,
    this.errorCode,
    this.onRetry,
    this.canGoBack = true,
  });

  // Factory constructor for common Bluetooth errors
  factory ErrorPage.bluetooth({
    required String message,
    required Function() onRetry,
  }) {
    return ErrorPage(
      title: 'Bluetooth Error',
      message: message,
      errorCode: 'BLE_ERROR',
      onRetry: onRetry,
    );
  }

  // Factory constructor for permission errors
  factory ErrorPage.permission({
    required String message,
    required Function() onRetry,
  }) {
    return ErrorPage(
      title: 'Permission Required',
      message: message,
      errorCode: 'PERMISSION_ERROR',
      onRetry: onRetry,
    );
  }

  // Factory constructor for network errors
  factory ErrorPage.network({
    required String message,
    required Function() onRetry,
  }) {
    return ErrorPage(
      title: 'Connection Error',
      message: message,
      errorCode: 'NETWORK_ERROR',
      onRetry: onRetry,
    );
  }

  Future<void> _handleRetry(BuildContext context) async {
    try {
      if (onRetry != null) {
        await onRetry!();
      }
    } catch (e) {
      await AppLogger.logError(
        'Retry failed on error page',
        e,
        StackTrace.current,
      );
      ErrorHandler.showErrorSnackBar(
        context,
        'Retry failed: ${e.toString()}',
      );
    }
  }

  Future<void> _handleBluetoothReset(BuildContext context) async {
    try {
      final bluetoothProvider = context.read<BluetoothProvider>();
      await bluetoothProvider.initialize();

      if (onRetry != null) {
        await onRetry!();
      }
    } catch (e) {
      await AppLogger.logError(
        'Bluetooth reset failed',
        e,
        StackTrace.current,
      );
      ErrorHandler.showErrorSnackBar(
        context,
        'Bluetooth reset failed: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => canGoBack,
      child: Scaffold(
        appBar: canGoBack
            ? AppBar(
                title: const Text('Error'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Error Icon
                Icon(
                  _getErrorIcon(),
                  size: 64,
                  color: _getErrorColor(context),
                ),
                const SizedBox(height: 24),

                // Error Title
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _getErrorColor(context),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Error Message
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                if (errorCode != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Error Code: $errorCode',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
                const SizedBox(height: 32),

                // Action Buttons
                if (onRetry != null) ...[
                  ElevatedButton(
                    onPressed: () => _handleRetry(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 45),
                    ),
                    child: const Text('Try Again'),
                  ),
                  const SizedBox(height: 16),
                ],

                // Additional actions for Bluetooth errors
                if (errorCode == 'BLE_ERROR') ...[
                  OutlinedButton(
                    onPressed: () => _handleBluetoothReset(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(200, 45),
                    ),
                    child: const Text('Reset Bluetooth'),
                  ),
                  const SizedBox(height: 16),
                ],

                // Home button if can't go back
                if (!canGoBack)
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    },
                    child: const Text('Go to Home'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (errorCode) {
      case 'BLE_ERROR':
        return Icons.bluetooth_disabled;
      case 'PERMISSION_ERROR':
        return Icons.no_encryption;
      case 'NETWORK_ERROR':
        return Icons.wifi_off;
      default:
        return Icons.error_outline;
    }
  }

  Color _getErrorColor(BuildContext context) {
    switch (errorCode) {
      case 'BLE_ERROR':
        return Colors.blue;
      case 'PERMISSION_ERROR':
        return Colors.orange;
      case 'NETWORK_ERROR':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.error;
    }
  }
}
