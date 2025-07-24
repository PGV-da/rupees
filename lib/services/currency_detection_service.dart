import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/currency_prediction.dart';
import '../utils/constants.dart';

class CurrencyDetectionService {
  static const String _modelPath = 'assets/currency_detector.tflite';
  static const int _inputSize = AppConstants.modelInputSize;

  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);
      _isModelLoaded = true;
    } catch (e) {
      throw Exception('Failed to load model: $e');
    }
  }

  Future<CurrencyPrediction> predictCurrency(File imageFile) async {
    if (!_isModelLoaded || _interpreter == null) {
      await loadModel();
    }

    try {
      // Read and decode image
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Preprocess image to proper tensor format
      final inputTensor = _preprocessImage(image);

      // Prepare output tensor - create proper 2D list structure
      var outputTensor = [List<double>.filled(2, 0.0)];

      // Run inference with properly shaped tensors
      _interpreter!.run([inputTensor], outputTensor);

      // Extract results from the output
      final results = outputTensor[0];
      final fakeConfidence = results[0];
      final realConfidence = results[1];

      final isReal = realConfidence > fakeConfidence;
      final maxConfidence = isReal ? realConfidence : fakeConfidence;

      return CurrencyPrediction(
        isReal: isReal,
        confidence: maxConfidence.clamp(0.0, 1.0),
      );
    } catch (e) {
      throw Exception('Prediction failed: $e');
    }
  }

  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    // Resize image to model input size
    final resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Convert to 4D tensor [batch=1, height, width, channels=3]
    return [
      List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      ),
    ];
  }

  // Alternative preprocessing if model expects different input format
  List<List<List<List<double>>>> _preprocessImageAs4D(img.Image image) {
    final resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Create 4D tensor [batch=1, height, width, channels=3]
    return [
      List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      ),
    ];
  }

  // Method for models that expect different output format
  Future<CurrencyPrediction> predictCurrencyWith4DOutput(File imageFile) async {
    if (!_isModelLoaded || _interpreter == null) {
      await loadModel();
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final inputTensor = _preprocessImageAs4D(image);

      // Output as 2D array [batch=1, classes=2]
      final outputTensor = List.generate(1, (_) => List<double>.filled(2, 0.0));

      _interpreter!.run(inputTensor, outputTensor);

      final results = outputTensor[0];
      final fakeConfidence = results[0];
      final realConfidence = results[1];

      final isReal = realConfidence > fakeConfidence;
      final maxConfidence = isReal ? realConfidence : fakeConfidence;

      return CurrencyPrediction(
        isReal: isReal,
        confidence: maxConfidence.clamp(0.0, 1.0),
      );
    } catch (e) {
      throw Exception('4D Prediction failed: $e');
    }
  }

  // Get model input/output details for debugging
  List<String> getModelInfo() {
    if (_interpreter == null) return ['Model not loaded'];

    final inputTensors = _interpreter!.getInputTensors();
    final outputTensors = _interpreter!.getOutputTensors();

    List<String> info = [];
    info.add('=== INPUT TENSORS ===');
    for (int i = 0; i < inputTensors.length; i++) {
      final tensor = inputTensors[i];
      info.add('Input $i: ${tensor.shape} ${tensor.type}');
    }

    info.add('=== OUTPUT TENSORS ===');
    for (int i = 0; i < outputTensors.length; i++) {
      final tensor = outputTensors[i];
      info.add('Output $i: ${tensor.shape} ${tensor.type}');
    }

    return info;
  }

  Future<void> dispose() async {
    try {
      _interpreter?.close();
      _interpreter = null;
      _isModelLoaded = false;
    } catch (e) {
      // Handle disposal error gracefully
    }
  }
}
