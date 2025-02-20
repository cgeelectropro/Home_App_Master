import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_app/models/collections.dart';
import 'package:home_app/services/provider/collection_provider.dart';
import 'package:home_app/utils/error_handler.dart';
import 'package:home_app/utils/app_logger.dart';
import 'package:uuid/uuid.dart';

class AddRoomPage extends StatefulWidget {
  const AddRoomPage({super.key});

  @override
  _AddRoomPageState createState() => _AddRoomPageState();
}

class _AddRoomPageState extends State<AddRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final collectionProvider = context.read<CollectionProvider>();

      // Create new room/collection
      final newRoom = Collection(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        picture: '',
        devices: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'local',
        v: 1,
      );

      // Add room
      final success = await collectionProvider.addCollection(newRoom);
      if (!success) {
        throw Exception('Failed to create room');
      }

      await AppLogger.log('Created new room: ${newRoom.id}');
      Navigator.pop(context, true);
    } catch (e) {
      await AppLogger.logError('Failed to create room', e, StackTrace.current);
      ErrorHandler.showErrorSnackBar(
        context,
        'Failed to create room: ${e.toString()}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Room'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Room Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.room),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a room name';
                }
                // Check for minimum length
                if (value.length < 3) {
                  return 'Room name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Consumer<CollectionProvider>(
              builder: (context, provider, _) {
                if (provider.collections.isNotEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Existing Rooms:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: provider.collections.map((collection) {
                              return Chip(
                                label: Text(collection.name),
                                backgroundColor: Colors.grey[200],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _addRoom,
        tooltip: 'Create Room',
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check),
      ),
    );
  }
}
