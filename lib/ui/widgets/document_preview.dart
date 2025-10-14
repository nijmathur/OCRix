import 'package:flutter/material.dart';
import 'dart:io';

class DocumentPreview extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Image preview
          Positioned.fill(
            child: Image.file(
              File(imagePath),
              fit: BoxFit.contain,
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
                  Colors.black.withOpacity(0.5),
                  onRetake,
                ),
                _buildControlButton(
                  context,
                  Icons.rotate_right,
                  Colors.black.withOpacity(0.5),
                  () {
                    // TODO: Implement image rotation
                  },
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
                  Colors.black.withOpacity(0.7),
                  onRetake,
                ),
                _buildActionButton(
                  context,
                  'Continue',
                  Icons.check,
                  Colors.green,
                  Colors.white,
                  onContinue,
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
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
