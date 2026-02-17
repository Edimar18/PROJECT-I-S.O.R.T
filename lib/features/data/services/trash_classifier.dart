import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class TrashClassifier {
  Interpreter? _interpreter;
  final List<String> _labels = [
    'cardboard',
    'e-waste',
    'glass',
    'medical',
    'metal',
    'paper',
    'plastic',
  ];

  // Average weights in kg for each category
  static const Map<String, double> averageWeights = {
    'cardboard': 0.05,
    'e-waste': 0.30,
    'glass': 0.25,
    'medical': 0.05,
    'metal': 0.015,
    'paper': 0.01,
    'plastic': 0.02,
  };

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions()..threads = 4;

      final appDir = await getApplicationDocumentsDirectory();
      final downloadedModelPath = '${appDir.path}/best_float32.tflite';
      final downloadedModel = File(downloadedModelPath);

      if (await downloadedModel.exists()) {
        _interpreter = await Interpreter.fromFile(
          downloadedModel,
          options: options,
        );
        print('Loaded updated model from storage');
      } else {
        _interpreter = await Interpreter.fromAsset(
          'assets/models/best_float16.tflite',
          options: options,
        );
        print('Loaded bundled model from assets');
      }

      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> classifyImage(String imagePath) async {
    if (_interpreter == null) {
      await loadModel();
    }

    final imageData = await _preprocessImage(imagePath);

    final output =
    List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

    _interpreter!.run(imageData, output);

    final predictions = output[0] as List<double>;

    int maxIndex = 0;
    double maxConfidence = predictions[0];

    for (int i = 1; i < predictions.length; i++) {
      if (predictions[i] > maxConfidence) {
        maxConfidence = predictions[i];
        maxIndex = i;
      }
    }

    final predictedLabel = _labels[maxIndex];
    final weight = averageWeights[predictedLabel] ?? 0.05;

    return {
      'label': predictedLabel,
      'confidence': maxConfidence,
      'weight': weight,
      'allPredictions': Map.fromIterables(_labels, predictions),
    };
  }

  Future<Uint8List> _preprocessImage(String imagePath) async {
    final imageBytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // ✅ FIX 1: Correct EXIF orientation.
    // Android cameras often write photos rotated 90° in the file but store
    // the correct orientation in EXIF metadata. Without this, the model sees
    // a sideways image that never appeared in training data.
    image = img.bakeOrientation(image);

    // ✅ FIX 2: Center-crop to a square BEFORE resizing.
    // A 9:16 photo resized directly to 224×224 squishes/stretches everything.
    // Center-cropping first keeps aspect ratio intact — matching how the
    // training dataset images were likely preprocessed (same as YOLOv8-cls
    // default: center crop then resize).
    final cropSize = image.width < image.height ? image.width : image.height;
    final cropX = (image.width - cropSize) ~/ 2;
    final cropY = (image.height - cropSize) ~/ 2;

    final cropped = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropSize,
      height: cropSize,
    );

    // ✅ FIX 3: Resize the square crop to 224×224 (no distortion now)
    final resized = img.copyResize(cropped, width: 224, height: 224,
        interpolation: img.Interpolation.linear);

    // ✅ Normalize pixels to [0, 1] — matches YOLOv8 training pipeline
    final inputList = <double>[];
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        inputList.add(pixel.r.toDouble() / 255.0);
        inputList.add(pixel.g.toDouble() / 255.0);
        inputList.add(pixel.b.toDouble() / 255.0);
      }
    }

    final input = Float32List.fromList(inputList);
    return input.buffer.asUint8List();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  bool get isModelLoaded => _interpreter != null;
}