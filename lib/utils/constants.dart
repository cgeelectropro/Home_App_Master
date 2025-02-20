class AppConstants {
  // Bluetooth Configuration
  static const int BLUETOOTH_SCAN_TIMEOUT = 4; // seconds
  static const int BLUETOOTH_CONNECTION_TIMEOUT = 5; // seconds
  static const int BLUETOOTH_MAX_RETRY_ATTEMPTS = 3;
  static const String BLUETOOTH_HC05_SERVICE_UUID =
      "00001101-0000-1000-8000-00805F9B34FB";

  // Device Configuration
  static const int MAX_DEVICES_PER_ROOM = 10;
  static const int MAX_ROOMS = 10;
  static const int MAX_COMMAND_HISTORY = 100;
  static const Duration COMMAND_RETRY_DELAY = Duration(seconds: 1);

  // Storage Keys
  static const String STORAGE_USER_KEY = 'user_data';
  static const String STORAGE_DEVICES_KEY = 'devices_data';
  static const String STORAGE_COLLECTIONS_KEY = 'collections_data';
  static const String STORAGE_THEME_KEY = 'theme_data';

  // Error Messages
  static const String ERROR_BLUETOOTH_DISABLED =
      'Please enable Bluetooth to continue';
  static const String ERROR_LOCATION_DISABLED =
      'Please enable Location services to scan for devices';
  static const String ERROR_DEVICE_NOT_FOUND =
      'Device not found. Please make sure it is nearby and powered on';
  static const String ERROR_CONNECTION_TIMEOUT =
      'Connection timeout. Please try again';
  static const String ERROR_CONNECTION_LOST =
      'Connection lost. Please try reconnecting';

  // Command Delimiters
  static const String COMMAND_DELIMITER = ':';
  static const String COMMAND_END = '\n';

  // Device Types
  static const List<String> DEVICE_TYPES = [
    'light',
    'fan',
    'ac',
    'tv',
    'door',
    'camera'
  ];

  // Theme
  static const double CARD_ELEVATION = 2.0;
  static const double CARD_BORDER_RADIUS = 8.0;
  static const double SCREEN_PADDING = 16.0;
}
