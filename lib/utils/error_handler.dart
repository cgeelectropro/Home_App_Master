import 'package:flutter/material.dart';
import 'dart:async'; // Add this for TimeoutException

class ErrorHandler {
  static String handleBluetoothError(dynamic error) {
    String errorMessage = error.toString();

    if (errorMessage.contains('bluetooth_disabled')) {
      return 'Please enable Bluetooth to continue';
    } else if (errorMessage.contains('location_disabled')) {
      return 'Please enable Location services to scan for devices';
    } else if (errorMessage.contains('device_not_found')) {
      return 'Device not found. Please make sure it is nearby and powered on';
    } else if (errorMessage.contains('connect_timeout')) {
      return 'Connection timeout. Please try again';
    } else if (errorMessage.contains('already_connected')) {
      return 'Device is already connected';
    } else if (errorMessage.contains('connection_lost')) {
      return 'Connection lost. Please try reconnecting';
    }

    if (error is TimeoutException) {
      return 'Operation timed out. Please try again';
    }

    return 'An unexpected error occurred: $error';
  }

  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message,
      {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  static bool isBluetoothError(dynamic error) {
    return error.toString().contains('bluetooth');
  }

  static bool isConnectionError(dynamic error) {
    return error.toString().toLowerCase().contains('connection') ||
        error.toString().toLowerCase().contains('timeout');
  }

  static bool isPermissionError(dynamic error) {
    return error.toString().toLowerCase().contains('permission');
  }
}
