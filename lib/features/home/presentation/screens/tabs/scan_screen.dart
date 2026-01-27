import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../data/services/trash_classifier.dart';
import '../../../../data/trash_facts.dart';
import '../../../../user/services/user_service.dart';

class ScanScreen extends StatefulWidget {
  final VoidCallback? onDashboardSelected;

  const ScanScreen({super.key, this.onDashboardSelected});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  XFile? _capturedImage;
  bool _isFlashOn = false;
  bool _isProcessing = false;

  // AI classifier - uncomment when you have the imports
  final TrashClassifier _classifier = TrashClassifier();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
    _loadModel();
  }


  Future<void> _loadModel() async {
    try {
      await _classifier.loadModel();
      print('AI model loaded successfully');
    } catch (e) {
      print('Error loading AI model: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load AI model: $e')),
        );
      }
    }
  }


  Future<void> _initializeCamera() async {
    final cameraStatus = await Permission.camera.request();

    if (cameraStatus.isGranted) {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        return _controller!.initialize().then((_) {
          if (!mounted) {
            return;
          }
          setState(() {});
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras available.')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _classifier.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isFlashOn) {
      _controller!.setFlashMode(FlashMode.off);
    } else {
      _controller!.setFlashMode(FlashMode.torch);
    }
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  Future<void> _processImage(String imagePath) async {
    setState(() {
      _isProcessing = true;
    });

    try {

      final result = await _classifier.classifyImage(imagePath);
      final category = result['label'] as String;
      final confidence = result['confidence'] as double;
      final weight = result['weight'] as double;

      // Record scan to Firebase
      await _userService.recordScan(category, weight);

      // Show detection dialog
      _showDetectionDialog(category, confidence, weight);


      // TEMPORARY: For testing without AI model
      // Remove this and uncomment above when ready


    } catch (e) {
      print('Error processing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showDetectionDialog(String category, double confidence, double weight) {
    final isRecyclable = _isRecyclable(category);
    final displayName = _getDisplayName(category);
    final typeDescription = _getTypeDescription(category);
    final randomFact = _getRandomFact(category);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTrashIcon(category),
                      const Chip(
                        label: Text('+1 pt'),
                        backgroundColor: Colors.teal,
                        labelStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'OBJECT IDENTIFIED',
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoChip('TYPE', typeDescription),
                      _buildInfoChip('RECYCLABLE', isRecyclable ? 'Yes' : 'No',
                          isRecyclable: isRecyclable),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                          color: Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Dynamic text sizing based on content length
                              double fontSize = 13;
                              if (randomFact.length > 150) {
                                fontSize = 11;
                              } else if (randomFact.length > 100) {
                                fontSize = 12;
                              }

                              return Text(
                                randomFact,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  height: 1.4,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _capturedImage = null;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Scan Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 60, vertical: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'cardboard':
        return 'Cardboard';
      case 'glass':
        return 'Glass Container';
      case 'metal':
        return 'Metal Can';
      case 'organic':
        return 'Organic Waste';
      case 'paper':
        return 'Paper';
      case 'plastic':
        return 'PET Plastic Bottle';
      case 'trash':
        return 'General Waste';
      default:
        return 'Unknown Item';
    }
  }

  String _getTypeDescription(String category) {
    switch (category.toLowerCase()) {
      case 'cardboard':
        return 'Cardboard';
      case 'glass':
        return 'Glass';
      case 'metal':
        return 'Metal/Aluminum';
      case 'organic':
        return 'Organic';
      case 'paper':
        return 'Paper';
      case 'plastic':
        return 'PET Plastic';
      case 'trash':
        return 'Mixed Waste';
      default:
        return 'Unknown';
    }
  }

  bool _isRecyclable(String category) {
    switch (category.toLowerCase()) {
      case 'cardboard':
      case 'glass':
      case 'metal':
      case 'paper':
      case 'plastic':
        return true;
      case 'organic':
      case 'trash':
        return false;
      default:
        return false;
    }
  }

  String _getRandomFact(String category) {
    // Uncomment when you have TrashFacts imported
    return TrashFacts.getRandomFact(category);

    // Temporary fallback
    return 'This is a ${category} item. Remember to dispose of it properly!';
  }

  Widget _buildTrashIcon(String type) {
    IconData iconData;
    switch (type.toLowerCase()) {
      case 'cardboard':
        iconData = Icons.inventory_2_outlined;
        break;
      case 'glass':
        iconData = Icons.wine_bar_outlined;
        break;
      case 'metal':
        iconData = Icons.settings_input_component_outlined;
        break;
      case 'paper':
        iconData = Icons.article_outlined;
        break;
      case 'plastic':
        iconData = Icons.local_drink_outlined;
        break;
      case 'organic':
        iconData = Icons.eco_outlined;
        break;
      case 'trash':
        iconData = Icons.delete_outline;
        break;
      default:
        iconData = Icons.help_outline;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(iconData, color: Colors.teal, size: 35),
    );
  }

  Widget _buildInfoChip(String title, String value,
      {bool isRecyclable = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          title == 'RECYCLABLE'
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRecyclable ? Icons.check_circle : Icons.cancel,
                color: isRecyclable ? Colors.green : Colors.red,
                size: 18,
              ),
              const SizedBox(width: 5),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          )
              : Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_controller != null && _controller!.value.isInitialized) {
              return Stack(
                children: [
                  // Camera preview or captured image
                  _capturedImage == null
                      ? SizedBox.expand(
                    child: CameraPreview(_controller!),
                  )
                      : SizedBox.expand(
                    child: Image.file(
                      File(_capturedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Processing overlay
                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Analyzing trash...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Close button
                  Positioned(
                    top: 50,
                    left: 20,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          widget.onDashboardSelected?.call();
                        },
                      ),
                    ),
                  ),

                  // Flash toggle
                  if (_capturedImage == null)
                    Positioned(
                      top: 50,
                      right: 20,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        child: IconButton(
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                          ),
                          onPressed: _toggleFlash,
                        ),
                      ),
                    ),

                  // Title
                  Positioned(
                    top: 120,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        const Text(
                          'AI Trash Detection',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black54,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'PROJECT I-S.O.R.T.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                blurRadius: 8.0,
                                color: Colors.black54,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                        if (_isProcessing)
                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                              'Analyzing...',
                              style: TextStyle(
                                color: Colors.teal,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Capture button
                  if (_capturedImage == null && !_isProcessing)
                    Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () async {
                            if (_controller == null ||
                                !_controller!.value.isInitialized ||
                                _isProcessing) {
                              return;
                            }
                            try {
                              final image = await _controller!.takePicture();
                              setState(() {
                                _capturedImage = image;
                              });

                              // Process image with AI
                              await _processImage(image.path);

                            } catch (e) {
                              print('Error capturing image: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            } else {
              return const Center(
                child: Text(
                  'Failed to initialize camera. Please check permissions.',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              );
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            );
          }
        },
      ),
    );
  }
}