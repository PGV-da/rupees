# Rupees - Currency Detection App

A Flutter application that uses TensorFlow Lite for on-device fake currency detection. The app can analyze images of currency notes captured from the camera or selected from the gallery to determine if they are real or fake.

## Features

- **Camera Integration**: Capture currency images directly from the device camera
- **Gallery Selection**: Choose existing images from the device gallery
- **On-Device ML**: Uses TensorFlow Lite for fast, offline currency analysis
- **Real-time Results**: Get instant feedback on currency authenticity
- **Confidence Scoring**: Shows prediction confidence percentage
- **Clean UI**: Modern, intuitive interface with Material Design 3
- **Cross-Platform**: Works on both Android and iOS

## Architecture

The app follows a clean architecture pattern with:

- **Models**: Data models for currency predictions
- **Services**: Business logic for ML inference and image handling
- **Controllers**: State management using ChangeNotifier
- **Screens**: UI components and widgets
- **Utils**: Constants and utility functions

## Project Structure

```
lib/
├── controllers/
│   └── currency_detection_controller.dart
├── models/
│   └── currency_prediction.dart
├── screens/
│   └── currency_detection_screen.dart
├── services/
│   ├── currency_detection_service.dart
│   └── image_picker_service.dart
├── utils/
│   └── constants.dart
├── widgets/
│   └── common_widgets.dart
└── main.dart

assets/
└── currency_detector.tflite
```

## Setup Instructions

### Prerequisites

- Flutter 3.22+ installed
- Dart 3+ installed
- Android Studio / Xcode for device testing
- A trained TensorFlow Lite model file named `currency_detector.tflite`

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd rupees
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Add your TensorFlow Lite model**:
   - Place your trained `currency_detector.tflite` file in the `assets/` folder
   - The model should accept 224x224x3 RGB images and output 2 classes (fake/real)

4. **Run the app**:
   ```bash
   flutter run
   ```

### Model Requirements

Your TensorFlow Lite model should:
- Accept input shape: `[1, 224, 224, 3]` (batch_size, height, width, channels)
- Output shape: `[1, 2]` (batch_size, num_classes)
- Input type: Float32 with values normalized to [0, 1]
- Output: Two probabilities [fake_probability, real_probability]

### Platform-Specific Setup

#### Android
Permissions are automatically handled in the app, but ensure your `AndroidManifest.xml` includes:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS
Permissions are automatically handled, but ensure your `Info.plist` includes:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to capture currency images for analysis.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to select currency images for analysis.</string>
```

## Dependencies

- `tflite_flutter: ^0.10.4` - TensorFlow Lite inference
- `image_picker: ^1.1.2` - Camera and gallery access
- `image: ^4.3.0` - Image processing and manipulation
- `permission_handler: ^11.3.1` - Runtime permissions

## Usage

1. **Launch the app**
2. **Select image source**:
   - Tap "Camera" to capture a new image
   - Tap "Gallery" to select an existing image
3. **View results**:
   - The app will automatically analyze the selected image
   - Results show whether the currency is real or fake
   - Confidence percentage is displayed
4. **Clear and retry**:
   - Tap the clear button to select a new image

## Model Training

To train your own currency detection model:

1. Collect a dataset of real and fake currency images
2. Preprocess images to 224x224 pixels
3. Train a binary classification model (e.g., using TensorFlow/Keras)
4. Convert to TensorFlow Lite format
5. Replace the `currency_detector.tflite` file

Example training output format:
- Class 0: Fake currency
- Class 1: Real currency

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This app is for educational and demonstration purposes only. Always consult with financial experts and use official verification methods for currency authentication in real-world scenarios.
