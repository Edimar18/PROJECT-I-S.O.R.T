
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isFlashOn = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      _showError("Camera permission is required to scan QR codes.");
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _toggleFlash() {
    controller.toggleTorch();
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    // For now, we'll just show the dialog after any QR is detected
    // In the future, you would verify the QR code here
    if (_capturedImagePath != null) return; // Dialog already shown

    final image = capture.image;
    if (image != null) {
      // This is a simplified example of saving the image.
      // You might want a more robust solution for production.
      final imagePath = '/data/user/0/isla.cluster.c.i_sort/cache/captured_qr.png';
      File(imagePath).writeAsBytes(image);
      setState(() {
        _capturedImagePath = imagePath;
      });
    }

    _showRewardDialog();
  }

  void _showRewardDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: Colors.amber, size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reward Verified',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                const SizedBox(height: 8),
                const Text(
                  '+20 Points Claimed',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'IOT STATION: CARMEN HUB 042',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text('Collect Reward'),
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
        );
      },
    ).then((_) {
      // Reset after dialog is dismissed
      setState(() {
        _capturedImagePath = null;
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          if (_capturedImagePath != null)
            SizedBox.expand(
              child: Image.file(File(_capturedImagePath!), fit: BoxFit.cover),
            )
          else
            MobileScanner(
              controller: controller,
              onDetect: _onDetect,
            ),
          // Custom painter for the QR code overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Colors.teal,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ),
          ),
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
          const Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Text(
              'Scan IoT Reward QR\nto claim points',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = 0.8,
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left + borderRadius, rect.top)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.left, rect.top + borderRadius);
    }

    return _getLeftTopPath(rect)
      ..lineTo(rect.left, rect.bottom - borderRadius)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left + borderRadius, rect.bottom)
      ..lineTo(rect.right - borderRadius, rect.bottom)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.bottom - borderRadius)
      ..lineTo(rect.right, rect.top + borderRadius)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right - borderRadius, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final cutOutWidth = (width < cutOutSize) ? width - 20 : cutOutSize;
    final cutOutHeight = (height < cutOutSize) ? height - 20 : cutOutSize;

    final backgroundPaint = Paint()
      ..color = Color.fromRGBO(0, 0, 0, overlayColor)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxWidth = cutOutWidth;
    final boxHeight = cutOutHeight;

    final cutOutRect = Rect.fromLTWH(
      rect.left + (width - boxWidth) / 2,
      rect.top + (height - boxHeight) / 2,
      boxWidth,
      boxHeight,
    );

    canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(rect),
          Path()
            ..addRRect(
                RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)))
            ..close(),
        ),
        backgroundPaint);

    // Draw the corner borders
    final cornerSide = borderLength;
    final double rectLeft = cutOutRect.left;
    final double rectTop = cutOutRect.top;
    final double rectRight = cutOutRect.right;
    final double rectBottom = cutOutRect.bottom;

    // Top-left corner
    canvas.drawPath(
        Path()
          ..moveTo(rectLeft, rectTop + cornerSide)
          ..lineTo(rectLeft, rectTop)
          ..lineTo(rectLeft + cornerSide, rectTop),
        borderPaint);

    // Top-right corner
    canvas.drawPath(
        Path()
          ..moveTo(rectRight - cornerSide, rectTop)
          ..lineTo(rectRight, rectTop)
          ..lineTo(rectRight, rectTop + cornerSide),
        borderPaint);

    // Bottom-left corner
    canvas.drawPath(
        Path()
          ..moveTo(rectLeft, rectBottom - cornerSide)
          ..lineTo(rectLeft, rectBottom)
          ..lineTo(rectLeft + cornerSide, rectBottom),
        borderPaint);

    // Bottom-right corner
    canvas.drawPath(
        Path()
          ..moveTo(rectRight - cornerSide, rectBottom)
          ..lineTo(rectRight, rectBottom)
          ..lineTo(rectRight, rectBottom - cornerSide),
        borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return this;
  }
}
