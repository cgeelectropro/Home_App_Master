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
