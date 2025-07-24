import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickFromCamera() async {
    try {
      if (await _requestCameraPermission()) {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: AppConstants.imageQuality,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        return image != null ? File(image.path) : null;
      } else {
        throw Exception(AppConstants.permissionDeniedError);
      }
    } catch (e) {
      throw Exception('Camera error: $e');
    }
  }

  Future<File?> pickFromGallery() async {
    try {
      if (await _requestStoragePermission()) {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: AppConstants.imageQuality,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        return image != null ? File(image.path) : null;
      } else {
        throw Exception(AppConstants.permissionDeniedError);
      }
    } catch (e) {
      throw Exception('Gallery error: $e');
    }
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we need different permissions
      if (Platform.version.contains('13') || Platform.version.contains('14')) {
        final status = await Permission.photos.request();
        return status == PermissionStatus.granted;
      } else {
        final status = await Permission.storage.request();
        return status == PermissionStatus.granted;
      }
    }
    return true; // iOS handles this automatically
  }

  Future<bool> checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final storageStatus = Platform.isAndroid
        ? await Permission.storage.status
        : PermissionStatus.granted;

    return cameraStatus == PermissionStatus.granted &&
        storageStatus == PermissionStatus.granted;
  }
}
