import 'dart:convert';
import 'package:home_app/models/user.dart';
import 'package:home_app/services/api/pref_services.dart';
import 'package:home_app/services/api/api.dart';

// class UploadServices {
// Save Image to Local Storage
//   Future<String> saveImageLocally(File imageFile) async {
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final String path = directory.path;
//       final String fileName = basename(imageFile.path);
//       final File localImage = await imageFile.copy('$path/$fileName');
//       return localImage.path;
//     } catch (e) {
//       throw Exception('Failed to save image locally: $e');
//     }
//   }

//   /// Get Image from Local Storage
//   Future<File> getImage(String fileName) async {
//     final directory = await getApplicationDocumentsDirectory();
//     final String path = directory.path;
//     return File('$path/$fileName');
//   }
// }

class UserServices {
  final PrefServices _prefServices = PrefServices();
  static const String userKey = 'user_data';

  Future<User?> getUserData() async {
    try {
      if (!await Api.isAuthenticated()) {
        throw Exception('User not authenticated');
      }

      final userData = await _prefServices.getUserData();
      if (userData != null) {
        return User.fromMap(json.decode(userData));
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      throw Exception('Failed to get user data: $e');
    }
  }

  Future<User?> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      // Update user logic here
      // Return updated User object
    } catch (e) {
      print('Error updating user: $e');
      return null;
    }
    return null;
  }

  Future<void> updateDeviceCount(int count) async {
    try {
      final user = await getUserData();
      if (user != null) {
        final updatedUser = user.copyWith(devices: count);
        await updateUser(updatedUser.id, updatedUser.toMap());
      }
    } catch (e) {
      print('Error updating device count: $e');
      throw Exception('Failed to update device count: $e');
    }
  }
}
