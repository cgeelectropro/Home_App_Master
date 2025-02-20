import 'dart:convert';

User userFromJson(String str) => User.fromMap(json.decode(str));

String userToJson(User data) => json.encode(data.toMap());

class User {
  final String id;
  final int index;
  final bool isActive;
  final String picture;
  final String name;
  final String phone;
  final String address;
  final String registered;
  final int devices;
  final String password;

  User({
    required this.id,
    required this.index,
    required this.isActive,
    required this.picture,
    required this.name,
    required this.phone,
    required this.address,
    required this.registered,
    required this.devices,
    required this.password,
  });

  factory User.fromMap(Map<String, dynamic> json) => User(
        id: json["id"],
        index: json["index"],
        isActive: json["isActive"],
        picture: json["picture"],
        name: json["name"],
        phone: json["phone"],
        address: json["address"],
        registered: json["registered"],
        devices: json["devices"],
        password: json["password"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "index": index,
        "isActive": isActive,
        "picture": picture,
        "name": name,
        "phone": phone,
        "address": address,
        "registered": registered,
        "devices": devices,
        "password": password,
      };

  User copyWith({
    String? name,
    String? picture,
    String? phone,
    String? address,
    bool? isActive,
    int? devices,
  }) {
    return User(
      id: id,
      index: index,
      isActive: isActive ?? this.isActive,
      picture: picture ?? this.picture,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      registered: registered,
      devices: devices ?? this.devices,
      password: password,
    );
  }
}
