import 'dart:io';
import 'dart:math' as math;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/currency_prediction.dart';
import '../utils/constants.dart';
import 'currency_presence_service.dart';

class CurrencyDetectionService {
  static const String _modelPath = 'assets/currency_detector.tflite';
  static const int _inputSize = AppConstants.modelInputSize;

  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    if (_isModelLoaded && _interpreter != null) return;

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
      // First, check if the image contains a currency note
      final hasCurrency = await CurrencyPresenceService.hasCurrencyNote(
        imageFile,
      );

      if (!hasCurrency) {
        return CurrencyPrediction(
          isReal: false,
          confidence: 0.0,
          hasCurrency: false,
          message: 'No currency detected in the image',
        );
      }

      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Get input tensor shape and validate
      final inputTensor = _interpreter!.getInputTensor(0);
      final inputShape = inputTensor.shape;

      // Validate input shape matches expected format [1, height, width, channels]
      if (inputShape.length != 4 ||
          inputShape[1] != _inputSize ||
          inputShape[2] != _inputSize) {
        throw Exception(
          'Input shape mismatch. Expected: [1, $_inputSize, $_inputSize, 3], Got: $inputShape',
        );
      }

      // Get output tensor shape dynamically
      final outputTensor = _interpreter!.getOutputTensor(0);
      final outputShape = outputTensor.shape;

      // Prepare input data
      final input = _preprocessImage(image);

      // Create output buffer with correct shape
      final output = _createOutputBuffer(outputShape);

      // Run inference
      _interpreter!.run(input, output);

      // Extract and interpret results
      final results = _extractResults(output, outputShape);

      return results;
    } catch (e) {
      throw Exception('Prediction failed: $e');
    }
  }

  dynamic _createOutputBuffer(List<int> shape) {
    if (shape.length == 2 && shape[0] == 1) {
      // Single batch output: [1, num_classes]
      return List.generate(1, (_) => List<double>.filled(shape[1], 0.0));
    } else if (shape.length == 1) {
      // Single dimension output: [num_classes]
      return List<double>.filled(shape[0], 0.0);
    } else {
      throw Exception('Unsupported output shape: $shape');
    }
  }

  CurrencyPrediction _extractResults(dynamic output, List<int> shape) {
    List<double> predictions;

    if (output is List<List<double>>) {
      // Output format: [[pred1, pred2, ..., predN]]
      predictions = output[0];
    } else if (output is List<double>) {
      // Output format: [pred1, pred2, ..., predN]
      predictions = output;
    } else {
      throw Exception('Unexpected output format: ${output.runtimeType}');
    }

    // Apply softmax to get probabilities
    final softmaxPredictions = _applySoftmax(predictions);

    // Find the class with highest probability
    int maxIndex = 0;
    double maxConfidence = softmaxPredictions[0];

    for (int i = 1; i < softmaxPredictions.length; i++) {
      if (softmaxPredictions[i] > maxConfidence) {
        maxConfidence = softmaxPredictions[i];
        maxIndex = i;
      }
    }

    // Interpret the result based on your labels.txt
    // Since you have 45 outputs but only 2 classes (fake, real),
    // this could be a multi-denomination currency detector.
    // We'll need to map the 45 classes to fake/real categories.

    bool isReal;

    if (predictions.length == 2) {
      // Simple binary classification: [fake_prob, real_prob]
      isReal = maxIndex == 1;
    } else {
      // Multi-class scenario with 45 outputs
      // Based on typical currency detection models, we can assume:
      // - Lower indices might be fake currencies
      // - Higher indices might be real currencies
      //
      // Since you have labels.txt with ["fake", "real"],
      // a reasonable approach is to check if the model might have
      // multiple denominations for each category.

      // Option 1: Map based on index ranges
      // Assuming first half are fake, second half are real
      final halfPoint = predictions.length ~/ 2;
      isReal = maxIndex >= halfPoint;

      // Option 2: You can also implement custom mapping based on your model
      // For example, if you know which specific indices correspond to real currencies:
      // final realIndices = {1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35, 37, 39, 41, 43};
      // isReal = realIndices.contains(maxIndex);
    }

    return CurrencyPrediction(
      isReal: isReal,
      confidence: maxConfidence.clamp(0.0, 1.0),
    );
  }

  List<double> _applySoftmax(List<double> input) {
    if (input.isEmpty) return [];

    // Find max value for numerical stability
    final maxVal = input.reduce(math.max);

    // Calculate exponentials
    final exp = input.map((x) => math.exp(x - maxVal)).toList();

    // Calculate sum of exponentials
    final sumExp = exp.fold(0.0, (sum, x) => sum + x);

    // Return normalized probabilities
    return exp.map((x) => x / sumExp).toList();
  }

  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

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

  // Helper method to get output shape for debugging
  List<int>? getOutputShape() {
    if (_interpreter == null) return null;
    return _interpreter!.getOutputTensor(0).shape;
  }

  // Helper method to get input shape for debugging
  List<int>? getInputShape() {
    if (_interpreter == null) return null;
    return _interpreter!.getInputTensor(0).shape;
  }

  // Debug method to test model with dummy data
  Future<Map<String, dynamic>> debugModelOutput() async {
    if (!_isModelLoaded || _interpreter == null) {
      await loadModel();
    }

    try {
      // Get tensor shapes
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      // Create dummy input (all zeros)
      final input = List.generate(
        inputShape[0],
        (_) => List.generate(
          inputShape[1],
          (_) => List.generate(
            inputShape[2],
            (_) => List.generate(inputShape[3], (_) => 0.0),
          ),
        ),
      );

      // Create output buffer
      final output = _createOutputBuffer(outputShape);

      // Run inference
      _interpreter!.run(input, output);

      return {
        'inputShape': inputShape,
        'outputShape': outputShape,
        'outputSample': output is List<List<double>>
            ? output[0].take(10).toList()
            : output is List<double>
            ? output.take(10).toList()
            : output,
        'outputLength': output is List<List<double>>
            ? output[0].length
            : output is List<double>
            ? output.length
            : 0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  void dispose() {
    try {
      _interpreter?.close();
      _interpreter = null;
      _isModelLoaded = false;
    } catch (e) {
      // Handle disposal error gracefully
    }
  }
}
