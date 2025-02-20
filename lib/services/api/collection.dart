import 'dart:convert';
import 'package:home_app/models/collections.dart';
import 'package:home_app/services/api/pref_services.dart';
import 'package:home_app/services/api/api.dart';

class CollectionServices {
  final PrefServices _prefServices = PrefServices();
  static const String collectionsKey = 'collections_data';

  Future<List<Collection>> getCollections() async {
    try {
      if (!await Api.isAuthenticated()) {
        throw Exception('User not authenticated');
      }

      final String? data = await _prefServices.loadFromPrefs(collectionsKey);
      if (data != null) {
        List<dynamic> jsonData = json.decode(data);
        return jsonData.map((x) => Collection.fromMap(x)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting collections: $e');
      throw Exception('Failed to get collections: $e');
    }
  }

  Future<bool> createCollection(Collection collection) async {
    try {
      if (!await Api.isAuthenticated()) {
        throw Exception('User not authenticated');
      }

      List<Collection> collections = await getCollections();
      collections.add(collection);

      await _prefServices.saveToPrefs(collectionsKey,
          json.encode(collections.map((e) => e.toMap()).toList()));
      return true;
    } catch (e) {
      print('Error creating collection: $e');
      throw Exception('Failed to create collection: $e');
    }
  }

  Future<bool> updateCollection(Collection updatedCollection) async {
    try {
      if (!await Api.isAuthenticated()) {
        throw Exception('User not authenticated');
      }

      List<Collection> collections = await getCollections();
      final index = collections.indexWhere((c) => c.id == updatedCollection.id);

      if (index != -1) {
        collections[index] = updatedCollection;
        await _prefServices.saveToPrefs(collectionsKey,
            json.encode(collections.map((e) => e.toMap()).toList()));
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating collection: $e');
      throw Exception('Failed to update collection: $e');
    }
  }

  Future<bool> deleteCollection(String id) async {
    try {
      if (!await Api.isAuthenticated()) {
        throw Exception('User not authenticated');
      }

      List<Collection> collections = await getCollections();
      collections.removeWhere((collection) => collection.id == id);

      await _prefServices.saveToPrefs(collectionsKey,
          json.encode(collections.map((e) => e.toMap()).toList()));
      return true;
    } catch (e) {
      print('Error deleting collection: $e');
      throw Exception('Failed to delete collection: $e');
    }
  }

  Future<bool> addDeviceToCollection(
      String collectionId, String deviceId) async {
    try {
      List<Collection> collections = await getCollections();
      final index = collections.indexWhere((c) => c.id == collectionId);

      if (index != -1) {
        if (!collections[index].devices.contains(deviceId)) {
          collections[index].devices.add(deviceId);
          await _prefServices.saveToPrefs(collectionsKey,
              json.encode(collections.map((e) => e.toMap()).toList()));
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error adding device to collection: $e');
      throw Exception('Failed to add device to collection: $e');
    }
  }

  Future<bool> removeDeviceFromCollection(
      String collectionId, String deviceId) async {
    try {
      List<Collection> collections = await getCollections();
      final index = collections.indexWhere((c) => c.id == collectionId);

      if (index != -1) {
        collections[index].devices.remove(deviceId);
        await _prefServices.saveToPrefs(collectionsKey,
            json.encode(collections.map((e) => e.toMap()).toList()));
        return true;
      }
      return false;
    } catch (e) {
      print('Error removing device from collection: $e');
      throw Exception('Failed to remove device from collection: $e');
    }
  }
}

Weather weatherFromJson(String str) => Weather.fromMap(json.decode(str));

String weatherToJson(Weather data) => json.encode(data.toMap());

class Weather {
  double lat;
  double lon;
  Temp temp;
  Humidity humidity;
  ObservationTime observationTime;

  Weather({
    required this.lat,
    required this.lon,
    required this.temp,
    required this.humidity,
    required this.observationTime,
  });

  factory Weather.fromMap(Map<String, dynamic> json) => Weather(
        lat: json["lat"].toDouble(),
        lon: json["lon"].toDouble(),
        temp: Temp.fromMap(json["temp"]),
        humidity: Humidity.fromMap(json["humidity"]),
        observationTime: ObservationTime.fromMap(json["observationTime"]),
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
  double value;

  Temp({
    required this.value,
  });

  factory Temp.fromMap(Map<String, dynamic> json) => Temp(
        value: json["value"].toDouble(),
      );

  Map<String, dynamic> toMap() => {
        "value": value,
      };
}

class Humidity {
  double value;

  Humidity({
    required this.value,
  });

  factory Humidity.fromMap(Map<String, dynamic> json) => Humidity(
        value: json["value"].toDouble(),
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
