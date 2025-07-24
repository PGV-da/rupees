class AppConstants {
  // Model configuration
  static const String modelPath = 'assets/currency_detector.tflite';
  static const String labelsPath = 'assets/labels.txt';
  static const int modelInputSize = 224;

  // Confidence thresholds
  static const double minConfidenceThreshold = 0.5;
  static const double highConfidenceThreshold = 0.8;

  // Image processing
  static const int imageQuality = 80;
  static const double imageCompressionRatio = 0.8;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardElevation = 4.0;
  static const double borderRadius = 12.0;

  // Error messages
  static const String modelLoadError =
      'Failed to load the currency detection model';
  static const String imagePickerError = 'Failed to pick image';
  static const String predictionError = 'Failed to analyze currency';
  static const String permissionDeniedError =
      'Permission denied. Please grant camera/storage permissions to continue.';

  // Success messages
  static const String modelLoadedSuccess = 'Model loaded successfully';

  // Labels
  static const String realCurrencyLabel = 'REAL CURRENCY';
  static const String fakeCurrencyLabel = 'FAKE CURRENCY';
}
