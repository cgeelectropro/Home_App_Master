import 'package:flutter/material.dart';
import 'package:home_app/models/collections.dart';
import 'package:home_app/services/storage/local_storage.dart';
import 'package:home_app/utils/app_logger.dart';
import 'package:home_app/services/provider/devices_provider.dart';

class CollectionProvider with ChangeNotifier {
  final LocalStorage _localStorage = LocalStorage();
  final DeviceProvider _deviceProvider;

  List<Collection> _collections = [];
  bool _isLoading = false;
  String _error = '';

  Collection? _selectedCollection;
  Collection? get selectedCollection => _selectedCollection;

  CollectionProvider(this._deviceProvider);

  List<Collection> get collections => _collections;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> loadCollections() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final storedCollections = await _localStorage.getCollections();
      _collections = storedCollections;
      notifyListeners();

      await AppLogger.log('Loaded ${_collections.length} collections');
    } catch (e) {
      _error = 'Failed to load collections: ${e.toString()}';
      await AppLogger.error(
          'Failed to load collections',error: e, stackTrace: StackTrace.current);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCollection(Collection collection) async {
    try {
      // Check for duplicate names
      if (_collections
          .any((c) => c.name.toLowerCase() == collection.name.toLowerCase())) {
        throw Exception('Collection with this name already exists');
      }

      _collections.add(collection);
      await _localStorage.saveCollections(_collections);
      notifyListeners();

      await AppLogger.log('Added new collection: ${collection.id}');
      return true;
    } catch (e) {
      _error = 'Failed to add collection: ${e.toString()}';
      await AppLogger.error(
          'Failed to add collection', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> updateCollection(Collection collection) async {
    try {
      final index = _collections.indexWhere((c) => c.id == collection.id);
      if (index == -1) {
        throw Exception('Collection not found');
      }

      // Check for duplicate names (excluding current collection)
      if (_collections.any((c) =>
          c.id != collection.id &&
          c.name.toLowerCase() == collection.name.toLowerCase())) {
        throw Exception('Collection with this name already exists');
      }

      _collections[index] = collection;
      await _localStorage.saveCollections(_collections);
      notifyListeners();

      await AppLogger.log('Updated collection: ${collection.id}');
      return true;
    } catch (e) {
      _error = 'Failed to update collection: ${e.toString()}';
      await AppLogger.error(
          'Failed to update collection', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> deleteCollection(String collectionId) async {
    try {
      _collections.removeWhere((c) => c.id == collectionId);
      await _localStorage.saveCollections(_collections);
      notifyListeners();

      await AppLogger.log('Deleted collection: $collectionId');
      return true;
    } catch (e) {
      _error = 'Failed to delete collection: ${e.toString()}';
      await AppLogger.error(
          'Failed to delete collection', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> addDeviceToCollection(
      String collectionId, String deviceId) async {
    try {
      final collection = _collections.firstWhere(
        (c) => c.id == collectionId,
        orElse: () => throw Exception('Collection not found'),
      );

      // Verify device exists
      final device = _deviceProvider.getDeviceById(deviceId);
      if (device == null) {
        throw Exception('Device not found');
      }

      // Check if device is already in collection
      if (collection.devices.contains(deviceId)) {
        throw Exception('Device already in collection');
      }

      final updatedCollection = collection.copyWith(
        devices: [...collection.devices, deviceId],
        updatedAt: DateTime.now(),
      );

      return await updateCollection(updatedCollection);
    } catch (e) {
      _error = 'Failed to add device to collection: ${e.toString()}';
      await AppLogger.error(
          'Failed to add device to collection', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> removeDeviceFromCollection(
      String collectionId, String deviceId) async {
    try {
      final collection = _collections.firstWhere(
        (c) => c.id == collectionId,
        orElse: () => throw Exception('Collection not found'),
      );

      final updatedDevices =
          collection.devices.where((id) => id != deviceId).toList();
      final updatedCollection = collection.copyWith(
        devices: updatedDevices,
        updatedAt: DateTime.now(),
      );

      return await updateCollection(updatedCollection);
    } catch (e) {
      _error = 'Failed to remove device from collection: ${e.toString()}';
      await AppLogger.error(
          'Failed to remove device from collection', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Collection? getCollectionById(String id) {
    try {
      return _collections.firstWhere((collection) => collection.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Collection> getCollectionsForDevice(String deviceId) {
    return _collections
        .where((collection) => collection.devices.contains(deviceId))
        .toList();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  Future<void> refreshCollections() async {
    await loadCollections();
  }

  Future<List<Collection>> getCollections() async {
    try {
      if (_collections.isEmpty) {
        await loadCollections();
      }
      return _collections;
    } catch (e) {
      print('Error getting collections: $e');
      return [];
    }
  }

  void setCollection(Collection collection) {
    _selectedCollection = collection;
    notifyListeners();
  }
}
