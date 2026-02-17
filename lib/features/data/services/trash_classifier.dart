import '../../user/services/update_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
    'e-waste': 0.30,     // ADD - electronics are heavier
    'glass': 0.25,
    'medical': 0.05,     // ADD - medical waste
    'metal': 0.015,
    'paper': 0.01,
    'plastic': 0.02,
  };

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions()..threads = 4;

      // Check if updated model exists
      final appDir = await getApplicationDocumentsDirectory();
      final downloadedModelPath = '${appDir.path}/best_float16.tflite';
      final downloadedModel = File(downloadedModelPath);

      if (await downloadedModel.exists()) {
        // Load downloaded model
        _interpreter = await Interpreter.fromFile(
          downloadedModel,
          options: options,
        );
        print('Loaded updated model from storage');
      } else {
        // Load bundled model from assets
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

    // Load and preprocess image
    final imageData = await _preprocessImage(imagePath);

    // Prepare output buffer
    final output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

    // Run inference
    _interpreter!.run(imageData, output);

    // Get results
    final predictions = output[0] as List<double>;

    // Find the index with highest confidence
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
    // Read image file
    final imageBytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // // Resize to 224x224 (YOLOv8-cls default)
    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

    // Convert to Float32List with pixel values 0-255 (not normalized)
    final imageMatrix = List.generate(
      224,
          (y) => List.generate(
        224,
            (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [
            pixel.r.toDouble() / 255.0,  // ✅ Normalize to 0-1
            pixel.g.toDouble() / 255.0,  // ✅ Normalize to 0-1
            pixel.b.toDouble() / 255.0,  // ✅ Normalize to 0-1
          ];
        },
      ),
    );

    // Flatten to 1D array and convert to Float32List
    final inputList = <double>[];
    for (var row in imageMatrix) {
      for (var pixel in row) {
        inputList.addAll(pixel);
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