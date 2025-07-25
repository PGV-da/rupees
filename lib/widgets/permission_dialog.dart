import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../utils/constants.dart';

class PermissionDialog {
  /// Show permission rationale dialog
  static Future<bool> showPermissionRationale(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(AppConstants.permissionRequiredTitle),
          content: const Text(AppConstants.storagePermissionRationaleMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow Access'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Show permission denied dialog with settings option
  static Future<bool> showPermissionDeniedDialog(
    BuildContext context, {
    bool isPermanentlyDenied = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(AppConstants.permissionDeniedTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPermanentlyDenied
                    ? AppConstants.storagePermissionPermanentlyDeniedError
                    : AppConstants.storagePermissionDeniedError,
              ),
              if (isPermanentlyDenied) ...[
                const SizedBox(height: 16),
                const Text(
                  AppConstants.enablePermissionInSettings,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            if (isPermanentlyDenied)
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Open Settings'),
              )
            else
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Try Again'),
              ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Handle permission request with UI feedback
  static Future<bool> handleStoragePermission(BuildContext context) async {
    final permissionService = PermissionService();

    // Check if we should show rationale first
    if (await permissionService.shouldShowPermissionRationale()) {
      final shouldRequest = await showPermissionRationale(context);
      if (!shouldRequest) return false;
    }

    // Request permission
    final result = await permissionService.requestStoragePermission();

    if (result.isGranted) {
      return true;
    }

    // Handle denied permission
    if (result.isPermanentlyDenied) {
      final openSettings = await showPermissionDeniedDialog(
        context,
        isPermanentlyDenied: true,
      );

      if (openSettings) {
        await permissionService.openAppSettings();
      }
      return false;
    }

    if (result.isDenied) {
      final tryAgain = await showPermissionDeniedDialog(context);
      if (tryAgain) {
        // Retry permission request
        return await handleStoragePermission(context);
      }
      return false;
    }

    // Show error for other cases
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Permission request failed'),
          backgroundColor: Colors.red,
        ),
      );
    }

    return false;
  }
}

/// Widget to show permission status and actions
class PermissionStatusWidget extends StatefulWidget {
  final VoidCallback? onPermissionGranted;

  const PermissionStatusWidget({super.key, this.onPermissionGranted});

  @override
  State<PermissionStatusWidget> createState() => _PermissionStatusWidgetState();
}

class _PermissionStatusWidgetState extends State<PermissionStatusWidget> {
  final PermissionService _permissionService = PermissionService();
  bool _isCheckingPermission = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _permissionService.isStoragePermissionGranted(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasPermission = snapshot.data ?? false;

        if (hasPermission) {
          return const SizedBox.shrink(); // Hide if permission is granted
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  size: 48,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  AppConstants.permissionRequiredTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppConstants.storagePermissionRationaleMessage,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isCheckingPermission ? null : _requestPermission,
                  icon: _isCheckingPermission
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _isCheckingPermission
                        ? 'Checking...'
                        : 'Grant Gallery Access',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isCheckingPermission = true;
    });

    try {
      final hasPermission = await PermissionDialog.handleStoragePermission(
        context,
      );

      if (hasPermission && widget.onPermissionGranted != null) {
        widget.onPermissionGranted!();
      }

      // Refresh the widget state
      if (mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPermission = false;
        });
      }
    }
  }
}
