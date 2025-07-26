import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/permission_service.dart';
import '../utils/constants.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();
  final PermissionService _permissionService = PermissionService();

  /// Picks an image from camera with proper permission handling
  Future<File?> pickFromCamera() async {
    try {
      // Request camera permission first
      final permissionResult = await _permissionService
          .requestCameraPermission();

      if (!permissionResult.isGranted) {
        throw Exception(
          permissionResult.message ?? AppConstants.cameraPermissionDeniedError,
        );
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: AppConstants.imageQuality,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      return image != null ? File(image.path) : null;
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        throw Exception(AppConstants.cameraPermissionDeniedError);
      }
      throw Exception('Camera access error: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// Picks an image from gallery with proper permission handling
  Future<File?> pickFromGallery() async {
    try {
      // Request storage permission first
      final permissionResult = await _permissionService
          .requestStoragePermission();

      if (!permissionResult.isGranted) {
        throw Exception(
          permissionResult.message ?? AppConstants.storagePermissionDeniedError,
        );
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: AppConstants.imageQuality,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      return image != null ? File(image.path) : null;
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied') {
        throw Exception(AppConstants.storagePermissionDeniedError);
      }
      throw Exception('Gallery access error: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// Check current storage permission status
  Future<bool> hasStoragePermission() async {
    return await _permissionService.isStoragePermissionGranted();
  }

  /// Check current camera permission status
  Future<bool> hasCameraPermission() async {
    return await _permissionService.isCameraPermissionGranted();
  }

  /// Get detailed permission result for UI handling
  Future<PermissionResult> checkStoragePermission() async {
    return await _permissionService.requestStoragePermission();
  }

  /// Get detailed camera permission result for UI handling
  Future<PermissionResult> checkCameraPermission() async {
    return await _permissionService.requestCameraPermission();
  }

  /// Open app settings for permission management
  Future<bool> openAppSettings() async {
    return await _permissionService.openAppSettings();
  }

  /// Check if we should show storage permission rationale
  Future<bool> shouldShowPermissionRationale() async {
    return await _permissionService.shouldShowPermissionRationale();
  }

  /// Check if we should show camera permission rationale
  Future<bool> shouldShowCameraPermissionRationale() async {
    return await _permissionService.shouldShowCameraPermissionRationale();
  }
}
