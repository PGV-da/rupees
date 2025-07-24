class CurrencyPrediction {
  final bool isReal;
  final double confidence;

  CurrencyPrediction({required this.isReal, required this.confidence});

  @override
  String toString() {
    return 'CurrencyPrediction(isReal: $isReal, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}
