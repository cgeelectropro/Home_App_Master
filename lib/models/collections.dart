import 'dart:convert';

Collection collectionFromJson(String str) =>
    Collection.fromMap(json.decode(str));

String collectionToJson(Collection data) => json.encode(data.toMap());

class Collection {
  final String id;
  final String name;
  final String? description;
  final String picture;
  final List<String> devices;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final int v;

  Collection({
    required this.id,
    required this.name,
    this.description,
    required this.picture,
    required this.devices,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.v,
  });

  Collection copyWith({
    String? id,
    String? name,
    String? description,
    String? picture,
    List<String>? devices,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    int? v,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      picture: picture ?? this.picture,
      devices: devices ?? List.from(this.devices),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      v: v ?? this.v,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'picture': picture,
      'devices': devices,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'v': v,
    };
  }

  factory Collection.fromMap(Map<String, dynamic> map) {
    return Collection(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      picture: map['picture'] ?? '',
      devices: List<String>.from(map['devices'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      createdBy: map['createdBy'] ?? '',
      v: map['v']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Collection.fromJson(String source) =>
      Collection.fromMap(json.decode(source));

  bool hasDevice(String deviceId) {
    return devices.contains(deviceId);
  }

  bool get isEmpty => devices.isEmpty;

  int get deviceCount => devices.length;

  @override
  String toString() {
    return 'Collection(id: $id, name: $name, devices: $devices)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Collection && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
