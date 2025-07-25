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
  bool _isAnalyzing = false;
  String? _error;

  File? get selectedImage => _selectedImage;
  CurrencyPrediction? get prediction => _prediction;
  bool get isLoading => _isLoading;
  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;
  bool get hasImageSelected => _selectedImage != null;

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
      _clearError();
      _clearPrediction();

      final image = await _imagePickerService.pickFromCamera();
      if (image != null) {
        _selectedImage = image;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to pick image from camera: $e');
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      _clearError();
      _clearPrediction();

      final image = await _imagePickerService.pickFromGallery();
      if (image != null) {
        _selectedImage = image;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to pick image from gallery: $e');
    }
  }

  Future<void> checkCurrency() async {
    if (_selectedImage == null) return;

    try {
      _setAnalyzing(true);
      _clearError();

      _prediction = await _detectionService.predictCurrency(_selectedImage!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to analyze currency: $e');

      // Debug: Log model info when there's an error
      try {
        final modelInfo = _detectionService.getModelInfo();
        for (final info in modelInfo) {
          print('Model Info: $info');
        }
      } catch (debugError) {
        print('Failed to get model info: $debugError');
      }
    } finally {
      _setAnalyzing(false);
    }
  }

  void clearImage() {
    _selectedImage = null;
    _prediction = null;
    _clearError();
    notifyListeners();
  }

  void _clearPrediction() {
    _prediction = null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setAnalyzing(bool analyzing) {
    _isAnalyzing = analyzing;
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
