import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/permission_service.dart';

/// Utility class to test and validate permission handling
class PermissionTest {
  static final PermissionService _permissionService = PermissionService();

  /// Test the permission system and print results
  static Future<void> testPermissionSystem() async {
    if (kDebugMode) {
      print('=== Permission System Test ===');

      // Test Android version detection
      print('Platform: ${Platform.operatingSystem}');
      if (Platform.isAndroid) {
        try {
          final hasPermission = await _permissionService
              .isStoragePermissionGranted();
          print('Current storage permission status: $hasPermission');

          final status = await _permissionService.getStoragePermissionStatus();
          print('Detailed permission status: $status');

          final shouldShowRationale = await _permissionService
              .shouldShowPermissionRationale();
          print('Should show rationale: $shouldShowRationale');
        } catch (e) {
          print('Error testing permissions: $e');
        }
      } else {
        print('iOS detected - permissions handled by image_picker');
      }

      print('=== End Permission Test ===');
    }
  }

  /// Get permission summary for debugging
  static Future<Map<String, dynamic>> getPermissionSummary() async {
    final summary = <String, dynamic>{
      'platform': Platform.operatingSystem,
      'isAndroid': Platform.isAndroid,
    };

    if (Platform.isAndroid) {
      try {
        summary['hasStoragePermission'] = await _permissionService
            .isStoragePermissionGranted();
        summary['permissionStatus'] =
            (await _permissionService.getStoragePermissionStatus()).name;
        summary['shouldShowRationale'] = await _permissionService
            .shouldShowPermissionRationale();
      } catch (e) {
        summary['error'] = e.toString();
      }
    }

    return summary;
  }
}
