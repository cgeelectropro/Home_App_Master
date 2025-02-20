import 'dart:convert';
import 'package:home_app/models/device_model.dart';
import 'package:home_app/models/collections.dart';
import 'package:home_app/models/user.dart';
import 'package:home_app/services/api/pref_services.dart';

class LocalStorage {
  final PrefServices _prefServices = PrefServices();

  // User Storage Operations
  Future<bool> saveUser(User user) async {
    try {
      final userData = json.encode(user.toMap());
      return await _prefServices.setUserData(userData);
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  Future<User?> getUser() async {
    try {
      final userData = await _prefServices.getUserData();
      if (userData != null) {
        return User.fromMap(json.decode(userData));
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Device Storage Operations
  Future<bool> saveDevices(List<Device> devices) async {
    try {
      final devicesData = json.encode(
        devices.map((device) => device.toMap()).toList(),
      );
      return await _prefServices.setDevicesData(devicesData);
    } catch (e) {
      print('Error saving devices: $e');
      return false;
    }
  }

  Future<List<Device>> getDevices() async {
    try {
      final devicesData = await _prefServices.getDevicesData();
      if (devicesData != null) {
        List<dynamic> decoded = json.decode(devicesData);
        return decoded.map((data) => Device.fromMap(data)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting devices: $e');
      return [];
    }
  }

  // Collection Storage Operations
  Future<bool> saveCollections(List<Collection> collections) async {
    try {
      final collectionsData = json.encode(
        collections.map((collection) => collection.toMap()).toList(),
      );
      return await _prefServices.setCollectionsData(collectionsData);
    } catch (e) {
      print('Error saving collections: $e');
      return false;
    }
  }

  Future<List<Collection>> getCollections() async {
    try {
      final collectionsData = await _prefServices.getCollectionsData();
      if (collectionsData != null) {
        List<dynamic> decoded = json.decode(collectionsData);
        return decoded.map((data) => Collection.fromMap(data)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting collections: $e');
      return [];
    }
  }

  // Device-Collection Relationship Operations
  Future<bool> addDeviceToCollection(
      String collectionId, String deviceId) async {
    try {
      final collections = await getCollections();
      final index = collections.indexWhere((c) => c.id == collectionId);

      if (index != -1) {
        collections[index].devices.add(deviceId);
        return await saveCollections(collections);
      }
      return false;
    } catch (e) {
      print('Error adding device to collection: $e');
      return false;
    }
  }

  Future<bool> removeDeviceFromCollection(
      String collectionId, String deviceId) async {
    try {
      final collections = await getCollections();
      final index = collections.indexWhere((c) => c.id == collectionId);

      if (index != -1) {
        collections[index].devices.remove(deviceId);
        return await saveCollections(collections);
      }
      return false;
    } catch (e) {
      print('Error removing device from collection: $e');
      return false;
    }
  }

  // Cleanup Operations
  Future<bool> clearAllData() async {
    try {
      return await _prefServices.clearAll();
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }

  Future<bool> clearUserData() async {
    try {
      return await _prefServices.removeFromPrefs(PrefServices.userKey);
    } catch (e) {
      print('Error clearing user data: $e');
      return false;
    }
  }

  // Backup Operations
  Future<String?> exportData() async {
    try {
      final userData = await _prefServices.getUserData();
      final devicesData = await _prefServices.getDevicesData();
      final collectionsData = await _prefServices.getCollectionsData();

      final backupData = {
        'user': userData,
        'devices': devicesData,
        'collections': collectionsData,
      };

      return json.encode(backupData);
    } catch (e) {
      print('Error exporting data: $e');
      return null;
    }
  }

  Future<bool> importData(String backupData) async {
    try {
      final decoded = json.decode(backupData);

      if (decoded['user'] != null) {
        await _prefServices.setUserData(decoded['user']);
      }
      if (decoded['devices'] != null) {
        await _prefServices.setDevicesData(decoded['devices']);
      }
      if (decoded['collections'] != null) {
        await _prefServices.setCollectionsData(decoded['collections']);
      }

      return true;
    } catch (e) {
      print('Error importing data: $e');
      return false;
    }
  }
}
