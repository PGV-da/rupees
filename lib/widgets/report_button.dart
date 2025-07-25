import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/cyber_crime_reporting_service.dart';
import '../utils/error_handler.dart';

class ReportButton extends StatefulWidget {
  final File imageFile;
  final VoidCallback? onReported;

  const ReportButton({super.key, required this.imageFile, this.onReported});

  @override
  State<ReportButton> createState() => _ReportButtonState();
}

class _ReportButtonState extends State<ReportButton> {
  bool _isReporting = false;
  bool _isReported = false;

  @override
  Widget build(BuildContext context) {
    if (_isReported) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              'Reported to Authorities',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _isReporting ? null : _handleReport,
      icon: _isReporting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.report, size: 18),
      label: Text(
        _isReporting ? 'Reporting...' : 'Report to Cyber Crime',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 3,
      ),
    );
  }

  Future<void> _handleReport() async {
    setState(() {
      _isReporting = true;
    });

    try {
      // Show reporting options dialog
      final action = await _showReportingOptionsDialog();

      if (action != null && mounted) {
        switch (action) {
          case 'copy':
            await _copyReportToClipboard();
            break;
          case 'website':
            await _openCyberCrimeWebsite();
            break;
          case 'email':
            await _openEmailClient();
            break;
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Failed to process report: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReporting = false;
        });
      }
    }
  }

  Future<String?> _showReportingOptionsDialog() async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.report, color: Colors.red),
              SizedBox(width: 8),
              Text('Report Fake Currency'),
            ],
          ),
          content: const Text(
            'How would you like to report this fake currency detection?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop('copy'),
              icon: const Icon(Icons.copy),
              label: const Text('Copy Report'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop('website'),
              icon: const Icon(Icons.web),
              label: const Text('Visit Website'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop('email'),
              icon: const Icon(Icons.email),
              label: const Text('Email Report'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _copyReportToClipboard() async {
    await CyberCrimeReportingService.reportFakeCurrency(
      imageFile: widget.imageFile,
      deviceInfo: Platform.operatingSystem,
    );

    if (mounted) {
      setState(() {
        _isReported = true;
      });

      ErrorHandler.showSuccess(
        context,
        'Report copied to clipboard!\nYou can paste it in an email or web form.',
      );

      widget.onReported?.call();
    }
  }

  Future<void> _openCyberCrimeWebsite() async {
    final success = await CyberCrimeReportingService.launchCyberCrimeWebsite();

    if (mounted) {
      setState(() {
        _isReported = true;
      });

      if (success) {
        ErrorHandler.showSuccess(
          context,
          'Cyber Crime website opened. Please file your report there.',
        );
      } else {
        ErrorHandler.showSuccess(
          context,
          'Please visit: ${CyberCrimeReportingService.getCyberCrimeWebsite()}\n'
          'Or NCRP: ${CyberCrimeReportingService.getNcrpWebsite()}',
        );
      }

      widget.onReported?.call();
    }
  }

  Future<void> _openEmailClient() async {
    final success = await CyberCrimeReportingService.launchEmailClient();

    if (!success) {
      // Fallback: copy email content to clipboard
      final mailtoLink = CyberCrimeReportingService.generateMailtoLink();
      await Clipboard.setData(ClipboardData(text: mailtoLink));
    }

    if (mounted) {
      setState(() {
        _isReported = true;
      });

      if (success) {
        ErrorHandler.showSuccess(
          context,
          'Email client opened with pre-filled report.',
        );
      } else {
        ErrorHandler.showSuccess(
          context,
          'Email template copied to clipboard!\n'
          'Please send to: ${CyberCrimeReportingService.getCyberCrimeEmail()}',
        );
      }

      widget.onReported?.call();
    }
  }
}
