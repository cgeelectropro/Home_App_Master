import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:home_app/components/show_loading.dart';
import 'package:home_app/models/collections.dart';
import 'package:home_app/services/api/uploadfiles.dart';
import 'package:home_app/services/provider/collection_provider.dart';
import 'package:home_app/services/provider/devices_provider.dart';
import 'package:home_app/theme/color.dart';
import 'package:home_app/utils/assets.dart';

class RoomEditPage extends StatefulWidget {
  static String get route => '/room-edit';
  final Collection room;

  const RoomEditPage({super.key, required this.room});

  @override
  _RoomEditPageState createState() => _RoomEditPageState();
}

class _RoomEditPageState extends State<RoomEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _uploadServices = UploadServices();
  File? _imageFile;
  bool _isLoading = false;
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.room.name;
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    if (!_isMounted) return;
    await Provider.of<DeviceProvider>(context, listen: false).fetchDevices();
  }

  @override
  void dispose() {
    _isMounted = false;
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null && _isMounted) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate() || !_isMounted) return;

    setState(() => _isLoading = true);

    try {
      showLoading(context);

      final collectionProvider =
          Provider.of<CollectionProvider>(context, listen: false);
      String pictureUrl = widget.room.picture;

      if (_imageFile != null) {
        pictureUrl = await _uploadServices.uploadImage(_imageFile!);
      }

      final updatedRoom = Collection(
        id: widget.room.id,
        name: _nameController.text.trim(),
        picture: pictureUrl,
        devices: widget.room.devices,
        createdAt: widget.room.createdAt,
        updatedAt: DateTime.now(),
        createdBy: widget.room.createdBy,
        v: widget.room.v,
      );

      final success = await collectionProvider.updateCollection(updatedRoom);

      if (!_isMounted) return;

      Navigator.pop(context); // Dismiss loading

      if (success) {
        Navigator.pop(context); // Return to previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update room')),
        );
      }
    } catch (e) {
      if (!_isMounted) return;

      Navigator.pop(context); // Dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating room: $e')),
      );
    } finally {
      if (_isMounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Room'),
          backgroundColor: AppColors.primaryColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveRoom,
              color: AppColors.iconColor,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Room Name',
                    border: OutlineInputBorder(),
                    fillColor: AppColors.inputBackground,
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a room name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _isLoading ? null : _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : widget.room.picture.isNotEmpty
                            ? Image.network(
                                widget.room.picture,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset(Assets.placeholderImage),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 50,
                                    color: AppColors.iconColor,
                                  ),
                                  Text(
                                    'Add Room Image',
                                    style: TextStyle(
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Devices in Room',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Consumer<DeviceProvider>(
                  builder: (context, deviceProvider, child) {
                    final devices = deviceProvider.devices
                        .where(
                            (device) => widget.room.devices.contains(device.id))
                        .toList();

                    if (devices.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text('No devices in this room'),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return ListTile(
                          title: Text(device.name),
                          subtitle: Text(device.type),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    try {
                                      final collectionProvider =
                                          Provider.of<CollectionProvider>(
                                        context,
                                        listen: false,
                                      );
                                      await collectionProvider
                                          .removeDeviceFromCollection(
                                        widget.room.id,
                                        device.id,
                                      );
                                    } catch (e) {
                                      if (!_isMounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Failed to remove device: $e'),
                                        ),
                                      );
                                    }
                                  },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
