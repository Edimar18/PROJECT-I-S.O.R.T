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
    'glass',
    'metal',
    'organic',
    'paper',
    'plastic',
    'trash'
  ];

  // Average weights in kg for each category
  static const Map<String, double> averageWeights = {
    'cardboard': 0.05, // 50g average cardboard piece
    'glass': 0.25, // 250g average glass bottle
    'metal': 0.015, // 15g average aluminum can
    'organic': 0.1, // 100g average organic waste
    'paper': 0.01, // 10g average paper
    'plastic': 0.02, // 20g average plastic bottle
    'trash': 0.05, // 50g average mixed trash
  };

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions()..threads = 4;

      // Check if updated model exists
      final appDir = await getApplicationDocumentsDirectory();
      final downloadedModelPath = '${appDir.path}/model.lite';
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
          'assets/models/model.lite',
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

    // Resize to 160x160
    img.Image resizedImage = img.copyResize(image, width: 160, height: 160);

    // Convert to Float32List with pixel values 0-255 (not normalized)
    final imageMatrix = List.generate(
      160,
          (y) => List.generate(
        160,
            (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [
            pixel.r.toDouble(),
            pixel.g.toDouble(),
            pixel.b.toDouble(),
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