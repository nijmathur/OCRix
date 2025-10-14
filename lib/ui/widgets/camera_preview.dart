import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/document_provider.dart';

class CameraPreviewWidget extends ConsumerWidget {
  final VoidCallback? onCapture;
  final bool isCapturing;

  const CameraPreviewWidget({
    super.key,
    this.onCapture,
    this.isCapturing = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(scannerNotifierProvider);
    final cameraController = ref.read(cameraServiceProvider).controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: CameraPreview(cameraController),
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
                Icons.flash_off,
                () => _toggleFlash(ref),
              ),
              _buildControlButton(
                context,
                Icons.flip_camera_ios,
                () => _switchCamera(ref),
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
              _buildControlButton(
                context,
                Icons.photo_library,
                () => _pickFromGallery(context),
              ),
              _buildCaptureButton(context, ref),
              _buildControlButton(
                context,
                Icons.settings,
                () => _showCameraSettings(context, ref),
              ),
            ],
          ),
        ),

        // Focus indicator
        if (scannerState.isCapturing)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildControlButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCaptureButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: isCapturing ? null : onCapture,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
        ),
        child: isCapturing
            ? const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
              )
            : const Center(
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.grey,
                  size: 32,
                ),
              ),
      ),
    );
  }

  void _toggleFlash(WidgetRef ref) {
    // TODO: Implement flash toggle
  }

  void _switchCamera(WidgetRef ref) {
    // TODO: Implement camera switching
  }

  void _pickFromGallery(BuildContext context) {
    // TODO: Implement gallery picker
  }

  void _showCameraSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Camera Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.flash_on),
              title: const Text('Flash'),
              trailing: Switch(
                value: false, // TODO: Get from state
                onChanged: (value) {
                  // TODO: Toggle flash
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Timer'),
              trailing: const Text('Off'),
              onTap: () {
                // TODO: Show timer options
              },
            ),
            ListTile(
              leading: const Icon(Icons.aspect_ratio),
              title: const Text('Aspect Ratio'),
              trailing: const Text('4:3'),
              onTap: () {
                // TODO: Show aspect ratio options
              },
            ),
          ],
        ),
      ),
    );
  }
}
