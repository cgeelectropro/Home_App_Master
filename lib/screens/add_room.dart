import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_app/components/show_loading.dart';
import 'package:home_app/models/collections.dart';
import 'package:home_app/services/api/uploadfiles.dart';
import 'package:home_app/services/provider/collection_provider.dart';
import 'package:home_app/theme/color.dart';
import 'package:home_app/theme/theme_changer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue/flutter_blue.dart';

class AddRoomPage extends StatefulWidget {
  static const route = '/addRoom';

  const AddRoomPage({super.key});

  @override
  _AddRoomPageState createState() => _AddRoomPageState();
}

class _AddRoomPageState extends State<AddRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _uploadServices = UploadServices();
  File? _imageFile;
  bool _isLoading = false;
  FlutterBlue flutterBlue = FlutterBlue.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    showLoading(context);

    try {
      String pictureUrl = '';
      if (_imageFile != null) {
        pictureUrl = await _uploadServices.uploadImage(_imageFile!);
      }

      final newRoom = Collection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        picture: pictureUrl,
        devices: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user', // Get from user provider
        v: 0,
      );

      final success = await Provider.of<CollectionProvider>(
        context,
        listen: false,
      ).addCollection(newRoom);

      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        if (success) {
          Navigator.pop(context); // Return to previous screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create room')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating room: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: MaterialButton(
            onPressed: () => Navigator.pop(context),
            padding: const EdgeInsets.all(0),
            minWidth: 32,
            height: 32,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.elliptical(16.0, 16.0)),
            ),
            child: const Center(
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 12),
            child: Consumer<ThemeChanger>(
              builder: (context, value, child) => IconButton(
                iconSize: 28,
                onPressed: _isLoading ? null : _createRoom,
                icon: Icon(
                  Icons.done,
                  color: value.darkTheme
                      ? AppColors.iconsColor_dark
                      : AppColors.iconsColor_light,
                ),
              ),
            ),
          ),
        ],
        elevation: 0,
        title: Text(
          'Add room',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Colors.white),
        ),
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a room name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : const Icon(Icons.add_photo_alternate, size: 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
