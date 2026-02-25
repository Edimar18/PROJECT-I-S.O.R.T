import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../data/services/trash_classifier.dart';
import '../../../../data/trash_facts.dart';
import '../../../../user/services/user_service.dart';
import 'package:image/image.dart' as img;

class ScanScreen extends StatefulWidget {
  final VoidCallback? onDashboardSelected;

  const ScanScreen({super.key, this.onDashboardSelected});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  XFile? _capturedImage;
  bool _isFlashOn = false;
  bool _isProcessing = false;

  // Animated scanning line
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  final TrashClassifier _classifier = TrashClassifier();
  final UserService _userService = UserService();

  // All supported categories
  static const List<String> _allCategories = [
    'cardboard',
    'e-waste',
    'glass',
    'medical',
    'metal',
    'paper',
    'plastic',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
    _loadModel();

    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
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
          if (!mounted) return;
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
    _scanLineController.dispose();
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

      await _userService.recordScan(category, weight);
      _showDetectionDialog(category, confidence, weight);
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

  // ─── Detection dialog (stateful via StatefulBuilder) ──────────────────────
  void _showDetectionDialog(
      String initialCategory, double confidence, double weight) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Local mutable state for the dialog
        String currentCategory = initialCategory;
        String currentFact = _getRandomFact(initialCategory);
        bool corrected = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isRecyclable = _isRecyclable(currentCategory);
            final displayName = _getDisplayName(currentCategory);
            final typeDescription = _getTypeDescription(currentCategory);

            return Dialog(
              backgroundColor: Colors.white.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Header row: icon + points chip ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTrashIcon(currentCategory),
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

                      // ── Label row with "corrected" badge ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (corrected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.orange.shade300, width: 1),
                              ),
                              child: const Text(
                                'Corrected',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
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
                        corrected
                            ? 'Manually corrected'
                            : 'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: corrected ? Colors.orange : Colors.black54,
                          fontSize: 12,
                          fontStyle: corrected
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Type + recyclable chips ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoChip('TYPE', typeDescription),
                          _buildInfoChip(
                            'RECYCLABLE',
                            isRecyclable ? 'Yes' : 'No',
                            isRecyclable: isRecyclable,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Fun fact box ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.blue, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  double fontSize = 13;
                                  if (currentFact.length > 150) {
                                    fontSize = 11;
                                  } else if (currentFact.length > 100) {
                                    fontSize = 12;
                                  }
                                  return Text(
                                    currentFact,
                                    style: TextStyle(
                                        fontSize: fontSize, height: 1.4),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── "Wrong prediction?" correction button ──
                      OutlinedButton.icon(
                        onPressed: () {
                          _showCategoryPicker(
                            context,
                            currentCategory,
                            onSelected: (newCategory) {
                              setDialogState(() {
                                currentCategory = newCategory;
                                currentFact = _getRandomFact(newCategory);
                                corrected = true;
                              });
                            },
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Wrong prediction? Correct it'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Scan Again button ──
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
      },
    );
  }

  // ─── Bottom sheet category picker ─────────────────────────────────────────
  void _showCategoryPicker(
      BuildContext context,
      String currentCategory, {
        required ValueChanged<String> onSelected,
      }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select the correct category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Help us improve by picking the right trash type.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _allCategories.map((cat) {
                  final isSelected = cat == currentCategory;
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      onSelected(cat);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.teal
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color:
                          isSelected ? Colors.teal : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(cat),
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getDisplayName(cat),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cardboard':
        return Icons.inventory_2_outlined;
      case 'e-waste':
        return Icons.phone_android_outlined;
      case 'glass':
        return Icons.wine_bar_outlined;
      case 'medical':
        return Icons.medical_services_outlined;
      case 'metal':
        return Icons.settings_input_component_outlined;
      case 'paper':
        return Icons.article_outlined;
      case 'plastic':
        return Icons.local_drink_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _getDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'cardboard':
        return 'Cardboard';
      case 'e-waste':
        return 'Electronic Waste';
      case 'glass':
        return 'Glass Container';
      case 'medical':
        return 'Medical Waste';
      case 'metal':
        return 'Metal Can';
      case 'paper':
        return 'Paper';
      case 'plastic':
        return 'PET Plastic Bottle';
      default:
        return 'Unknown Item';
    }
  }

  String _getTypeDescription(String category) {
    switch (category.toLowerCase()) {
      case 'cardboard':
        return 'Cardboard';
      case 'e-waste':
        return 'Electronics';
      case 'glass':
        return 'Glass';
      case 'medical':
        return 'Medical';
      case 'metal':
        return 'Metal/Aluminum';
      case 'paper':
        return 'Paper';
      case 'plastic':
        return 'PET Plastic';
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
      case 'e-waste':
      case 'medical':
        return false;
      default:
        return false;
    }
  }

  String _getRandomFact(String category) {
    return TrashFacts.getRandomFact(category);
  }

  Widget _buildTrashIcon(String type) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(_getCategoryIcon(type), color: Colors.teal, size: 35),
    );
  }

  Widget _buildInfoChip(String title, String value,
      {bool isRecyclable = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
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

  // ─── Crop guide & dim overlay (unchanged) ─────────────────────────────────

  Widget _buildCropGuide(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boxSize = screenWidth * 0.75;
    const cornerLen = 28.0;
    const cornerThickness = 4.0;
    const cornerRadius = 6.0;

    return Center(
      child: SizedBox(
        width: boxSize,
        height: boxSize,
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (_, __) {
                return Positioned(
                  top: _scanLineAnimation.value * (boxSize - 2),
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.teal.withValues(alpha: 0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              child: _buildCorner(
                  topLeft: true,
                  cornerLen: cornerLen,
                  thickness: cornerThickness,
                  radius: cornerRadius),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: _buildCorner(
                  topRight: true,
                  cornerLen: cornerLen,
                  thickness: cornerThickness,
                  radius: cornerRadius),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: _buildCorner(
                  bottomLeft: true,
                  cornerLen: cornerLen,
                  thickness: cornerThickness,
                  radius: cornerRadius),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: _buildCorner(
                  bottomRight: true,
                  cornerLen: cornerLen,
                  thickness: cornerThickness,
                  radius: cornerRadius),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
    required double cornerLen,
    required double thickness,
    required double radius,
  }) {
    return CustomPaint(
      size: Size(cornerLen, cornerLen),
      painter: _CornerPainter(
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
        thickness: thickness,
        radius: radius,
        color: Colors.teal,
      ),
    );
  }

  Widget _buildDimOverlay(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final boxSize = screenSize.width * 0.75;
    final sideMargin = (screenSize.width - boxSize) / 2;
    final cameraAreaHeight = screenSize.height - 160;
    final topMargin = (cameraAreaHeight - boxSize) / 2 + 80;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topMargin,
          child: Container(color: Colors.black.withValues(alpha: 0.55)),
        ),
        Positioned(
          top: topMargin + boxSize,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(color: Colors.black.withValues(alpha: 0.55)),
        ),
        Positioned(
          top: topMargin,
          left: 0,
          width: sideMargin,
          height: boxSize,
          child: Container(color: Colors.black.withValues(alpha: 0.55)),
        ),
        Positioned(
          top: topMargin,
          right: 0,
          width: sideMargin,
          height: boxSize,
          child: Container(color: Colors.black.withValues(alpha: 0.55)),
        ),
        Positioned(
          top: topMargin,
          left: sideMargin,
          child: _buildCropGuide(context),
        ),
        Positioned(
          top: topMargin + boxSize + 10,
          left: 0,
          right: 0,
          child: const Text(
            'Place object inside the box',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                    blurRadius: 6,
                    color: Colors.black54,
                    offset: Offset(1, 1))
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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

                  if (_capturedImage == null && !_isProcessing)
                    _buildDimOverlay(context),

                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.teal),
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

                  Positioned(
                    top: 50,
                    left: 20,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          widget.onDashboardSelected?.call();
                        },
                      ),
                    ),
                  ),

                  if (_capturedImage == null)
                    Positioned(
                      top: 50,
                      right: 20,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                        child: IconButton(
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                          ),
                          onPressed: _toggleFlash,
                        ),
                      ),
                    ),

                  Positioned(
                    top: 90,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        const Text(
                          'AI Trash Classifier',
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
                              border:
                              Border.all(color: Colors.white, width: 6),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                  Colors.black.withValues(alpha: 0.3),
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

// ─── Corner bracket painter ───────────────────────────────────────────────────
class _CornerPainter extends CustomPainter {
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;
  final double thickness;
  final double radius;
  final Color color;

  const _CornerPainter({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
    required this.thickness,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final r = radius;

    if (topLeft) {
      canvas.drawPath(
        Path()
          ..moveTo(0, h)
          ..lineTo(0, r)
          ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
          ..lineTo(w, 0),
        paint,
      );
    }
    if (topRight) {
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(w - r, 0)
          ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
          ..lineTo(w, h),
        paint,
      );
    }
    if (bottomLeft) {
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(0, h - r)
          ..arcToPoint(Offset(r, h), radius: Radius.circular(r))
          ..lineTo(w, h),
        paint,
      );
    }
    if (bottomRight) {
      canvas.drawPath(
        Path()
          ..moveTo(0, h)
          ..lineTo(w - r, h)
          ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r))
          ..lineTo(w, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}