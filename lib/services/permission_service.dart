import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';

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
      PermissionStatus currentStatus = await permission.status;

      if (currentStatus == PermissionStatus.granted) {
        return PermissionResult.granted();
      }

      if (currentStatus == PermissionStatus.permanentlyDenied) {
        return PermissionResult.permanentlyDenied(
          AppConstants.storagePermissionPermanentlyDeniedError,
        );
      }

      // Request permission
      final result = await permission.request();

      switch (result) {
        case PermissionStatus.granted:
          return PermissionResult.granted();
        case PermissionStatus.denied:
          return PermissionResult.denied(
            AppConstants.storagePermissionDeniedError,
          );
        case PermissionStatus.permanentlyDenied:
          return PermissionResult.permanentlyDenied(
            AppConstants.storagePermissionPermanentlyDeniedError,
          );
        case PermissionStatus.restricted:
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
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  /// Get storage permission status
  Future<PermissionStatus> getStoragePermissionStatus() async {
    if (!Platform.isAndroid) return PermissionStatus.granted;

    try {
      final androidSdk = await _getAndroidSdkVersion();
      final permission = _getStoragePermissionForAndroidVersion(androidSdk);
      return await permission.status;
    } catch (e) {
      return PermissionStatus.denied;
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
      return await openAppSettings();
    } catch (e) {
      return false;
    }
  }

  /// Get the appropriate permission based on Android version
  Permission _getStoragePermissionForAndroidVersion(int androidSdk) {
    if (androidSdk >= 33) {
      // Android 13+ (API 33+) - Use READ_MEDIA_IMAGES
      return Permission.photos;
    } else {
      // Android 12 and below - Use READ_EXTERNAL_STORAGE
      return Permission.storage;
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

      // Look for API level in the version string
      final apiMatch = RegExp(r'API (\d+)').firstMatch(versionString);
      if (apiMatch != null) {
        return int.tryParse(apiMatch.group(1)!) ?? 29;
      }

      // Look for Android version number
      final androidMatch = RegExp(r'Android (\d+)').firstMatch(versionString);
      if (androidMatch != null) {
        final majorVersion = int.tryParse(androidMatch.group(1)!) ?? 10;
        // Convert Android version to API level (approximate)
        return _androidVersionToApiLevel(majorVersion);
      }

      // Default to API 29 (Android 10) if we can't determine
      return 29;
    } catch (e) {
      return 29;
    }
  }

  /// Convert Android version to API level
  int _androidVersionToApiLevel(int androidVersion) {
    switch (androidVersion) {
      case 14:
        return 34;
      case 13:
        return 33;
      case 12:
        return 31;
      case 11:
        return 30;
      case 10:
        return 29;
      case 9:
        return 28;
      case 8:
        return 26;
      case 7:
        return 24;
      default:
        return 29; // Default to Android 10
    }
  }
}

/// Result class for permission operations
class PermissionResult {
  final PermissionResultType type;
  final String? message;

  const PermissionResult._(this.type, this.message);

  factory PermissionResult.granted() =>
      const PermissionResult._(PermissionResultType.granted, null);
  factory PermissionResult.denied(String message) =>
      PermissionResult._(PermissionResultType.denied, message);
  factory PermissionResult.permanentlyDenied(String message) =>
      PermissionResult._(PermissionResultType.permanentlyDenied, message);
  factory PermissionResult.restricted(String message) =>
      PermissionResult._(PermissionResultType.restricted, message);
  factory PermissionResult.error(String message) =>
      PermissionResult._(PermissionResultType.error, message);

  bool get isGranted => type == PermissionResultType.granted;
  bool get isDenied => type == PermissionResultType.denied;
  bool get isPermanentlyDenied =>
      type == PermissionResultType.permanentlyDenied;
  bool get isRestricted => type == PermissionResultType.restricted;
  bool get isError => type == PermissionResultType.error;
  bool get canRetry => isDenied;
  bool get needsSettings => isPermanentlyDenied;
}

enum PermissionResultType {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  error,
}
