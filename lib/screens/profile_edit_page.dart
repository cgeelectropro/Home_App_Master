import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_app/components/icon_button.dart';
import 'package:home_app/services/api/uploadfiles.dart';
import 'package:home_app/services/api/user.dart';
import 'package:home_app/services/provider/user_provider.dart';
import 'package:home_app/theme/color.dart';
import 'package:home_app/theme/theme_changer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:home_app/utils/error_handler.dart';
import 'package:home_app/utils/app_logger.dart';

class ProfileEditPage extends StatefulWidget {
  static const String route = '/profileEdit';

  const ProfileEditPage({super.key});
  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final TextEditingController _nameController = TextEditingController();
  File? _image;
  final UploadServices _uploadServices = UploadServices();
  final UserServices _userServices = UserServices();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _imageLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() {
    final user = context.read<UserProvider>().user;
    if (user?.name != null) {
      _nameController.text = user!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _getImage() async {
    if (_imageLoading) return;

    setState(() => _imageLoading = true);
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        // Verify file size
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          // 5MB limit
          throw Exception(
              'Image size too large. Please select an image under 5MB.');
        }

        setState(() => _image = file);
        await AppLogger.log('Profile image selected');
      }
    } catch (e) {
      await AppLogger.logError('Failed to pick image', e, StackTrace.current);
      ErrorHandler.showErrorSnackBar(
        context,
        e is Exception ? e.toString() : 'Failed to select image',
      );
    } finally {
      setState(() => _imageLoading = false);
    }
  }

  Future<void> _updateUserDetails() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) {
      ErrorHandler.showErrorSnackBar(context, 'User not found');
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty && _image == null) {
      ErrorHandler.showErrorSnackBar(
        context,
        'No changes to update',
        isError: false,
      );
      return;
    }

    // Validate name
    if (name.isNotEmpty && (name.length < 2 || name.length > 50)) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Name must be between 2 and 50 characters',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> data = {};

      // Handle image upload if new image selected
      if (_image != null) {
        try {
          final picUrl = await _uploadServices.uploadImage(_image!);
          data['picture'] = picUrl;
        } catch (e) {
          throw Exception('Failed to upload image: ${e.toString()}');
        }
      }

      // Add name to update data if changed
      if (name.isNotEmpty && name != user.name) {
        data['name'] = name;
      }

      if (data.isEmpty) {
        ErrorHandler.showErrorSnackBar(
          context,
          'No changes to update',
          isError: false,
        );
        return;
      }

      // Update user data
      final updatedUser = await _userServices.updateUser(user.id, data);
      if (updatedUser == null) {
        throw Exception('Failed to update user data');
      }

      Provider.of<UserProvider>(context, listen: false).setUser(updatedUser);
      await AppLogger.log('User profile updated successfully');

      // Show success message and navigate back
      ErrorHandler.showErrorSnackBar(
        context,
        'Profile updated successfully',
        isError: false,
      );
      Navigator.pop(context, true); // Return true to indicate successful update
    } catch (e) {
      await AppLogger.logError(
          'Failed to update profile', e, StackTrace.current);
      ErrorHandler.showErrorSnackBar(
        context,
        'Failed to update profile: ${e.toString()}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(22.0),
                  bottomLeft: Radius.circular(22.0),
                ),
                color: Theme.of(context).primaryColor,
              ),
              child: Wrap(
                direction: Axis.vertical,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width,
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        direction: Axis.vertical,
                        children: [
                          _buildProfileImage(
                              Provider.of<UserProvider>(context, listen: true)),
                          const SizedBox(height: 10),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: 30,
                            alignment: Alignment.centerRight,
                            child: TextField(
                              controller: _nameController,
                              autofocus: true,
                              textInputAction: TextInputAction.done,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                              onSubmitted: (_) => _updateUserDetails(),
                              decoration: InputDecoration(
                                hintText: 'Enter new name',
                                hintStyle:
                                    Theme.of(context).textTheme.titleMedium,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(12.0),
        child: MaterialButton(
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          minWidth: 32,
          height: 32,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
      actions: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 12),
            child: Consumer<ThemeChanger>(
              builder: (context, value, child) => RectIconButton(
                height: 28,
                width: 28,
                onPressed: _updateUserDetails,
                color: value.darkTheme
                    ? AppColors.iconsColorBackground2_dark
                    : AppColors.iconsColorBackground3_light,
                child: Icon(
                  Icons.done,
                  color: value.darkTheme
                      ? AppColors.iconsColor_dark
                      : AppColors.iconsColor_light,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileImage(UserProvider userProvider) {
    final user = userProvider.user;

    return Hero(
      tag: 'profile',
      child: Stack(
        children: [
          Container(
            width: 90.0,
            height: 90.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(45.0),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              image: DecorationImage(
                image: _image != null
                    ? FileImage(_image!) as ImageProvider
                    : NetworkImage(
                        user?.picture ?? 'https://via.placeholder.com/90'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (_imageLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(45.0),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _getImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
