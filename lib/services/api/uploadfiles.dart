import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:async';

class UploadServices {
  Future<String> uploadImage(File imageFile) async {
    // Copy file to app's local storage and return the path
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${basename(imageFile.path)}';
    final localPath = '${directory.path}/$fileName';

    final File localImage = await imageFile.copy(localPath);
    return localImage.path;
  }

  /// Save Image to Local Storage
  Future<String> saveImageLocally(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String path = directory.path;
      final String fileName = basename(imageFile.path);
      final File localImage = await imageFile.copy('$path/$fileName');
      return localImage.path;
    } catch (e) {
      throw Exception('Failed to save image locally: $e');
    }
  }

  /// Get Image from Local Storage
  Future<File> getImage(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final String path = directory.path;
    return File('$path/$fileName');
  }
}
