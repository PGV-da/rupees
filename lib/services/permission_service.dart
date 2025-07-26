import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import '../utils/constants.dart';

/// Result class for permission operations
class PermissionResult {
  final bool isGranted;
  final bool isDenied;
  final bool isPermanentlyDenied;
  final bool isRestricted;
  final String? message;

  PermissionResult._({
    required this.isGranted,
    required this.isDenied,
    required this.isPermanentlyDenied,
    required this.isRestricted,
    this.message,
  });

  factory PermissionResult.granted() => PermissionResult._(
    isGranted: true,
    isDenied: false,
    isPermanentlyDenied: false,
    isRestricted: false,
  );

  factory PermissionResult.denied(String message) => PermissionResult._(
    isGranted: false,
    isDenied: true,
    isPermanentlyDenied: false,
    isRestricted: false,
    message: message,
  );

  factory PermissionResult.permanentlyDenied(String message) =>
      PermissionResult._(
        isGranted: false,
        isDenied: false,
        isPermanentlyDenied: true,
        isRestricted: false,
        message: message,
      );

  factory PermissionResult.restricted(String message) => PermissionResult._(
    isGranted: false,
    isDenied: false,
    isPermanentlyDenied: false,
    isRestricted: true,
    message: message,
  );

  factory PermissionResult.error(String message) => PermissionResult._(
    isGranted: false,
    isDenied: true,
    isPermanentlyDenied: false,
    isRestricted: false,
    message: message,
  );
}

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Check and request storage permission for gallery access
  Future<PermissionResult> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      // iOS handles gallery permission automatically through image_picker
      return PermissionResult.granted();
    }

    try {
      final androidSdk = await _getAndroidSdkVersion();
      final permission = _getStoragePermissionForAndroidVersion(androidSdk);

      // Check current status
      permission_handler.PermissionStatus currentStatus =
          await permission.status;

      if (currentStatus == permission_handler.PermissionStatus.granted) {
        return PermissionResult.granted();
      }

      if (currentStatus ==
          permission_handler.PermissionStatus.permanentlyDenied) {
        return PermissionResult.permanentlyDenied(
          AppConstants.storagePermissionPermanentlyDeniedError,
        );
      }

      // Request permission
      final result = await permission.request();

      switch (result) {
        case permission_handler.PermissionStatus.granted:
          return PermissionResult.granted();
        case permission_handler.PermissionStatus.denied:
          return PermissionResult.denied(
            AppConstants.storagePermissionDeniedError,
          );
        case permission_handler.PermissionStatus.permanentlyDenied:
          return PermissionResult.permanentlyDenied(
            AppConstants.storagePermissionPermanentlyDeniedError,
          );
        case permission_handler.PermissionStatus.restricted:
          return PermissionResult.restricted(
            AppConstants.storagePermissionRestrictedError,
          );
        default:
          return PermissionResult.denied(
            AppConstants.storagePermissionDeniedError,
          );
      }
    } catch (e) {
      return PermissionResult.error('Failed to request permission: $e');
    }
  }

  /// Check if storage permission is granted
  Future<bool> isStoragePermissionGranted() async {
    if (!Platform.isAndroid) return true;

    try {
      final androidSdk = await _getAndroidSdkVersion();
      final permission = _getStoragePermissionForAndroidVersion(androidSdk);
      final status = await permission.status;
      return status == permission_handler.PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  /// Get storage permission status
  Future<permission_handler.PermissionStatus>
  getStoragePermissionStatus() async {
    if (!Platform.isAndroid) return permission_handler.PermissionStatus.granted;

    try {
      final androidSdk = await _getAndroidSdkVersion();
      final permission = _getStoragePermissionForAndroidVersion(androidSdk);
      return await permission.status;
    } catch (e) {
      return permission_handler.PermissionStatus.denied;
    }
  }

  /// Check if should show permission rationale
  Future<bool> shouldShowPermissionRationale() async {
    if (!Platform.isAndroid) return false;

    try {
      final androidSdk = await _getAndroidSdkVersion();
      final permission = _getStoragePermissionForAndroidVersion(androidSdk);
      return await permission.shouldShowRequestRationale;
    } catch (e) {
      return false;
    }
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    try {
      return await permission_handler.openAppSettings();
    } catch (e) {
      return false;
    }
  }

  /// Get the appropriate permission based on Android version
  permission_handler.Permission _getStoragePermissionForAndroidVersion(
    int androidSdk,
  ) {
    if (androidSdk >= 33) {
      // Android 13+ (API 33+) - Use READ_MEDIA_IMAGES
      return permission_handler.Permission.photos;
    } else {
      // Android 12 and below - Use READ_EXTERNAL_STORAGE
      return permission_handler.Permission.storage;
    }
  }

  /// Get Android SDK version
  Future<int> _getAndroidSdkVersion() async {
    if (kIsWeb || !Platform.isAndroid) return 0;

    try {
      // Try to get SDK version via platform channel
      const platform = MethodChannel('flutter.dev/device_info');
      final result = await platform.invokeMethod('getAndroidSdkVersion');
      return result as int? ?? _fallbackAndroidVersion();
    } catch (e) {
      return _fallbackAndroidVersion();
    }
  }

  /// Fallback method to determine Android version
  int _fallbackAndroidVersion() {
    try {
      // Try to parse from Platform.version
      final versionString = Platform.version;
      final match = RegExp(r'Android (\d+)').firstMatch(versionString);
      if (match != null) {
        final version = int.parse(match.group(1)!);
        // Convert Android version to API level (approximate)
        return _androidVersionToApiLevel(version);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to parse Android version: $e');
      }
    }

    // Default to API 29 (Android 10) for compatibility
    return 29;
  }

  /// Convert Android version to API level
  int _androidVersionToApiLevel(int androidVersion) {
    switch (androidVersion) {
      case 14:
        return 34;
      case 13:
        return 33;
      case 12:
        return 32;
      case 11:
        return 30;
      case 10:
        return 29;
      case 9:
        return 28;
      case 8:
        return 27;
      default:
        return 29; // Default to API 29
    }
  }
}
