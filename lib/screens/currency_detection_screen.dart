import 'package:flutter/material.dart';
import '../controllers/currency_detection_controller.dart';
import '../utils/error_handler.dart';
import '../widgets/common_widgets.dart';
import '../widgets/report_button.dart';

class CurrencyDetectionScreen extends StatefulWidget {
  const CurrencyDetectionScreen({super.key});

  @override
  State<CurrencyDetectionScreen> createState() =>
      _CurrencyDetectionScreenState();
}

class _CurrencyDetectionScreenState extends State<CurrencyDetectionScreen> {
  late CurrencyDetectionController _controller;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _controller = CurrencyDetectionController();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      await _controller.initializeModel();
      if (mounted) {
        ErrorHandler.showSuccess(context, 'Model loaded successfully!');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Failed to load model: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rupees - Currency Detector'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          centerTitle: true,
        ),
        body: const LoadingWidget(message: 'Initializing AI model...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rupees - Currency Detector'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        elevation: 2,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Show error in snackbar when it occurs
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_controller.error != null) {
              ErrorHandler.showError(context, _controller.error!);
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInstructionCard(),
                const SizedBox(height: 16),
                _buildImageSection(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 24),
                _buildResultSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Capture or select a clear image of the currency note to detect if it\'s real or fake. If fake currency is detected, you can report it to cyber crime authorities.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: _controller.selectedImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Image.file(
                    _controller.selectedImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  if (_controller.isAnalyzing)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Select an image to analyze',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Camera or Gallery',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_controller.isLoading || _controller.isAnalyzing)
                    ? null
                    : () async {
                        try {
                          await _controller.pickImageFromCamera();
                        } catch (e) {
                          if (mounted) {
                            ErrorHandler.showError(context, e.toString());
                          }
                        }
                      },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_controller.isLoading || _controller.isAnalyzing)
                    ? null
                    : () async {
                        try {
                          await _controller.pickImageFromGallery();
                        } catch (e) {
                          if (mounted) {
                            ErrorHandler.showError(context, e.toString());
                          }
                        }
                      },
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                ),
              ),
            ),
            if (_controller.selectedImage != null) ...[
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: (_controller.isLoading || _controller.isAnalyzing)
                    ? null
                    : _controller.clearImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  elevation: 2,
                ),
                child: const Icon(Icons.clear),
              ),
            ],
          ],
        ),
        if (_controller.hasImageSelected && _controller.prediction == null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _controller.isAnalyzing
                  ? null
                  : () async {
                      try {
                        await _controller.checkCurrency();
                      } catch (e) {
                        if (mounted) {
                          ErrorHandler.showError(context, e.toString());
                        }
                      }
                    },
              icon: _controller.isAnalyzing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(
                _controller.isAnalyzing ? 'Analyzing...' : 'Check Currency',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 4,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultSection() {
    if (_controller.isAnalyzing) {
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Analyzing currency...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller.prediction == null) {
      return const SizedBox.shrink();
    }

    final prediction = _controller.prediction!;

    // Handle no currency detected case
    if (!prediction.hasCurrency) {
      return Card(
        elevation: 6,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange.shade50, Colors.orange.shade100],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  child: Icon(
                    Icons.search_off,
                    size: 80,
                    color: Colors.orange.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'NO CURRENCY DETECTED',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  prediction.message ?? 'No currency note found in the image',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.orange.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Please ensure:\n• The image contains a currency note\n• The note is clearly visible\n• Good lighting conditions',
                  style: TextStyle(fontSize: 14, color: Colors.orange.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _controller.clearImage();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Another Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Handle normal currency detection case
    // final confidencePercentage = (prediction.confidence * 100).toStringAsFixed(
    // 1,
    // );

    return Card(
      elevation: 6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: prediction.isReal
                ? [Colors.green.shade50, Colors.green.shade100]
                : [Colors.red.shade50, Colors.red.shade100],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                child: Icon(
                  prediction.isReal ? Icons.check_circle : Icons.dangerous,
                  size: 80,
                  color: prediction.isReal
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                prediction.isReal ? 'REAL CURRENCY' : 'FAKE CURRENCY',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: prediction.isReal
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: prediction.isReal
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: (prediction.isReal ? Colors.green : Colors.red)
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                prediction.isReal
                    ? 'This currency note appears to be authentic.'
                    : 'Warning: This currency note may be counterfeit.',
                style: TextStyle(
                  fontSize: 14,
                  color: prediction.isReal
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Show report button only for fake currency
              if (!prediction.isReal && _controller.selectedImage != null) ...[
                ReportButton(
                  imageFile: _controller.selectedImage!,
                  onReported: () {
                    // Optional: Add any callback logic here
                  },
                ),
                const SizedBox(height: 16),
              ],

              ElevatedButton.icon(
                onPressed: () {
                  _controller.clearImage();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Check Another'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
