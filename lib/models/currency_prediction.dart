class CurrencyPrediction {
  final bool isReal;
  final double confidence;
  final bool hasCurrency;
  final String? message;

  CurrencyPrediction({
    required this.isReal,
    required this.confidence,
    this.hasCurrency = true,
    this.message,
  });

  @override
  String toString() {
    if (!hasCurrency) {
      return 'CurrencyPrediction(hasCurrency: false, message: $message)';
    }
    return 'CurrencyPrediction(isReal: $isReal, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}
