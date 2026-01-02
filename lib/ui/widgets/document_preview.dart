import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

class DocumentPreview extends StatefulWidget {
  final String imagePath;
  final VoidCallback? onRetake;
  final VoidCallback? onContinue;

  const DocumentPreview({
    super.key,
    required this.imagePath,
    this.onRetake,
    this.onContinue,
  });

  @override
  State<DocumentPreview> createState() => _DocumentPreviewState();
}

class _DocumentPreviewState extends State<DocumentPreview> {
  int _rotationAngle = 0; // 0, 90, 180, 270
  bool _isRotating = false;

  void _rotateImage() async {
    if (_isRotating) return;

    setState(() {
      _isRotating = true;
      _rotationAngle = (_rotationAngle + 90) % 360;
    });

    try {
      // Read the image file
      final imageFile = File(widget.imagePath);
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        // Rotate the image 90 degrees clockwise
        final rotated = img.copyRotate(image, angle: 90);

        // Save the rotated image back to the file
        await imageFile.writeAsBytes(img.encodeJpg(rotated));
      }
    } catch (e) {
      debugPrint('Error rotating image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRotating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Image preview with rotation
          Positioned.fill(
            child: Transform.rotate(
              angle: _rotationAngle * math.pi / 180,
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.contain,
                key: ValueKey(_rotationAngle), // Force rebuild on rotation
              ),
            ),
          ),

          // Top controls
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildControlButton(
                  context,
                  Icons.close,
                  Colors.black.withValues(alpha: 0.5),
                  widget.onRetake,
                ),
                _buildControlButton(
                  context,
                  _isRotating ? Icons.hourglass_empty : Icons.rotate_right,
                  Colors.black.withValues(alpha: 0.5),
                  _isRotating ? null : _rotateImage,
                ),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  'Retake',
                  Icons.camera_alt,
                  Colors.white,
                  Colors.black.withValues(alpha: 0.7),
                  widget.onRetake,
                ),
                _buildActionButton(
                  context,
                  'Continue',
                  Icons.check,
                  Colors.green,
                  Colors.white,
                  widget.onContinue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context,
    IconData icon,
    Color backgroundColor,
    VoidCallback? onPressed,
  ) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color backgroundColor,
    Color textColor,
    VoidCallback? onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
