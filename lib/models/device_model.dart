import 'dart:convert';

Credentials credentialsFromJson(String str) =>
    Credentials.fromMap(json.decode(str));

String credentialsToJson(Credentials data) => json.encode(data.toMap());

/// Model to save user name and password
/// so you can send this data to IoT device

class Credentials {
  String name;
  String password;

  Credentials({
    required this.name,
    required this.password,
  });

  factory Credentials.fromMap(Map<String, dynamic> json) => Credentials(
        name: json["name"],
        password: json["password"],
      );

  Map<String, dynamic> toMap() => {
        "name": name,
        "password": password,
      };
}

class Device {
  final String id;
  final String name;
  final String type;
  final String status;
  final String? macAddress;
  final DateTime createdAt;
  final Map<String, dynamic>? settings;
  final bool isConnected;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.macAddress,
    required this.createdAt,
    this.settings,
    this.isConnected = false,
  });

  Device copyWith({
    String? id,
    String? name,
    String? type,
    String? status,
    String? macAddress,
    DateTime? createdAt,
    Map<String, dynamic>? settings,
    bool? isConnected,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      macAddress: macAddress ?? this.macAddress,
      createdAt: createdAt ?? this.createdAt,
      settings: settings ?? this.settings,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'status': status,
      'macAddress': macAddress,
      'createdAt': createdAt.toIso8601String(),
      'settings': settings,
      'isConnected': isConnected,
    };
  }

  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      status: map['status'] ?? 'off',
      macAddress: map['macAddress'],
      createdAt: DateTime.parse(map['createdAt']),
      settings: map['settings'],
      isConnected: map['isConnected'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Device.fromJson(String source) => Device.fromMap(json.decode(source));

  String getCommand(String action) {
    // Format command based on device type
    switch (type.toLowerCase()) {
      case 'light':
        return 'L:${action.toUpperCase()}';
      case 'fan':
        return 'F:${action.toUpperCase()}';
      case 'ac':
        return 'AC:${action.toUpperCase()}';
      default:
        return '${type.toUpperCase()}:${action.toUpperCase()}';
    }
  }

  @override
  String toString() {
    return 'Device(id: $id, name: $name, type: $type, status: $status, macAddress: $macAddress, isConnected: $isConnected)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
