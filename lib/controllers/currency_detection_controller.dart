import 'dart:io';
import 'package:flutter/material.dart';
import '../models/currency_prediction.dart';
import '../services/currency_detection_service.dart';
import '../services/image_picker_service.dart';

class CurrencyDetectionController extends ChangeNotifier {
  final CurrencyDetectionService _detectionService = CurrencyDetectionService();
  final ImagePickerService _imagePickerService = ImagePickerService();

  File? _selectedImage;
  CurrencyPrediction? _prediction;
  bool _isLoading = false;
  String? _error;

  File? get selectedImage => _selectedImage;
  CurrencyPrediction? get prediction => _prediction;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initializeModel() async {
    try {
      _setLoading(true);
      await _detectionService.loadModel();
      _clearError();
    } catch (e) {
      _setError('Failed to initialize model: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      _setLoading(true);
      _clearError();

      final image = await _imagePickerService.pickFromCamera();
      if (image != null) {
        _selectedImage = image;
        await _predictCurrency();
      }
    } catch (e) {
      _setError('Failed to pick image from camera: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      _setLoading(true);
      _clearError();

      final image = await _imagePickerService.pickFromGallery();
      if (image != null) {
        _selectedImage = image;
        await _predictCurrency();
      }
    } catch (e) {
      _setError('Failed to pick image from gallery: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _predictCurrency() async {
    if (_selectedImage == null) return;

    try {
      _prediction = await _detectionService.predictCurrency(_selectedImage!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to analyze currency: $e');
    }
  }

  void clearImage() {
    _selectedImage = null;
    _prediction = null;
    _clearError();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _detectionService.dispose();
    super.dispose();
  }
}
