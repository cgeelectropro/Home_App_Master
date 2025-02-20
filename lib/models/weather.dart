import 'dart:convert';

Weather weatherFromJson(String str) => Weather.fromMap(json.decode(str));

String weatherToJson(Weather data) => json.encode(data.toMap());

class Weather {
  final double lat;
  final double lon;
  final Temp temp;
  final Humidity humidity;
  final ObservationTime observationTime;

  Weather({
    required this.lat,
    required this.lon,
    required this.temp,
    required this.humidity,
    required this.observationTime,
  });

  factory Weather.fromMap(Map<String, dynamic> json) => Weather(
        lat: (json["lat"] as num).toDouble(),
        lon: (json["lon"] as num).toDouble(),
        temp: Temp.fromMap(json["temp"] as Map<String, dynamic>),
        humidity: Humidity.fromMap(json["humidity"] as Map<String, dynamic>),
        observationTime: ObservationTime.fromMap(
            json["observationTime"] as Map<String, dynamic>),
      );

  Map<String, dynamic> toMap() => {
        "lat": lat,
        "lon": lon,
        "temp": temp.toMap(),
        "humidity": humidity.toMap(),
        "observationTime": observationTime.toMap(),
      };
}

class Temp {
  final double value;

  Temp({
    required this.value,
  });

  factory Temp.fromMap(Map<String, dynamic> json) => Temp(
        value: (json["value"] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        "value": value,
      };
}

class Humidity {
  final double value;

  Humidity({
    required this.value,
  });

  factory Humidity.fromMap(Map<String, dynamic> json) => Humidity(
        value: (json["value"] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        "value": value,
      };
}

class ObservationTime {
  String value;

  ObservationTime({
    required this.value,
  });

  factory ObservationTime.fromMap(Map<String, dynamic> json) => ObservationTime(
        value: json["value"],
      );

  Map<String, dynamic> toMap() => {
        "value": value,
      };
}
