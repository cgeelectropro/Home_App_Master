import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_app/models/collections.dart';
import 'package:home_app/services/provider/collection_provider.dart';
import 'package:home_app/services/provider/devices_provider.dart';
import 'package:home_app/utils/error_handler.dart';
import 'package:home_app/utils/app_logger.dart';
import 'package:home_app/components/confirmation_dialog.dart';

class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});

  static String get route => '/rooms';
  @override
  _RoomsPageState createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    try {
      final collectionProvider = context.read<CollectionProvider>();
      await collectionProvider.loadCollections();
    } catch (e) {
      await AppLogger.logError('Failed to load rooms', e, StackTrace.current);
      ErrorHandler.showErrorSnackBar(
          context, 'Failed to load rooms: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRoom(Collection room) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Room',
      message:
          'Are you sure you want to delete ${room.name}? This will not delete the devices in the room.',
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final collectionProvider = context.read<CollectionProvider>();
      final success = await collectionProvider.deleteCollection(room.id);

      if (!success) {
        throw Exception('Failed to delete room');
      }

      await AppLogger.log('Deleted room: ${room.id}');
    } catch (e) {
      await AppLogger.logError('Failed to delete room', e, StackTrace.current);
      ErrorHandler.showErrorSnackBar(
          context, 'Failed to delete room: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editRoom(Collection room) async {
    final nameController = TextEditingController(text: room.name);
    final descController = TextEditingController(text: room.description);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Room Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'name': nameController.text,
              'description': descController.text,
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final collectionProvider = context.read<CollectionProvider>();
        final updatedRoom = room.copyWith(
          name: result['name']!,
          description: result['description'],
          updatedAt: DateTime.now(),
        );

        final success = await collectionProvider.updateCollection(updatedRoom);
        if (!success) {
          throw Exception('Failed to update room');
        }

        await AppLogger.log('Updated room: ${room.id}');
      } catch (e) {
        await AppLogger.logError(
            'Failed to update room', e, StackTrace.current);
        ErrorHandler.showErrorSnackBar(
            context, 'Failed to update room: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
      ),
      body: Consumer2<CollectionProvider, DeviceProvider>(
        builder: (context, collectionProvider, devicesProvider, _) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = collectionProvider.collections;
          if (rooms.isEmpty) {
            return const Center(
              child: Text('No rooms found'),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadRooms,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final deviceCount = room.devices.length;

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.room),
                    title: Text(room.name),
                    subtitle: Text(room.description ?? 'No description'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$deviceCount devices'),
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editRoom(room);
                            } else if (value == 'delete') {
                              _deleteRoom(room);
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/room',
                        arguments: room,
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add-room');
          if (result == true) {
            _loadRooms();
          }
        },
        tooltip: 'Add Room',
        child: const Icon(Icons.add),
      ),
    );
  }
}
