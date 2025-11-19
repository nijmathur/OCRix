import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart' hide CameraException;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import '../core/interfaces/camera_service_interface.dart';
import '../core/base/base_service.dart';
import '../core/exceptions/app_exceptions.dart';

class CameraService extends BaseService implements ICameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  @override
  String get serviceName => 'CameraService';

  @override
  List<CameraDescription> get cameras => _cameras;

  @override
  CameraController? get controller => _controller;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('No cameras available');
      }
      _isInitialized = true;
      logInfo('Camera service initialized with ${_cameras.length} cameras');
    } catch (e) {
      logError('Failed to initialize camera service', e);
      if (e is CameraException) {
        rethrow;
      }
      throw CameraException(
        'Failed to initialize camera service: ${e.toString()}',
        originalError: e,
      );
    }
  }

  Future<void> initializeController({
    int cameraIndex = 0,
    ResolutionPreset resolution = ResolutionPreset.high,
    bool enableAudio = false,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (cameraIndex >= _cameras.length) {
        throw Exception('Camera index out of range');
      }

      final camera = _cameras[cameraIndex];

      _controller = CameraController(
        camera,
        resolution,
        enableAudio: enableAudio,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      logInfo('Camera controller initialized for ${camera.name}');
    } catch (e) {
      logError('Failed to initialize camera controller', e);
      if (e is CameraException) {
        rethrow;
      }
      throw CameraException(
        'Failed to initialize camera controller: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<String> captureImage() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) {
        throw CameraException('Camera controller not initialized');
      }

      final XFile image = await _controller!.takePicture();

      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'scan_$timestamp.jpg';
      final filePath = path.join(directory.path, 'scans', fileName);

      // Create scans directory if it doesn't exist
      final scansDir = Directory(path.dirname(filePath));
      if (!await scansDir.exists()) {
        await scansDir.create(recursive: true);
      }

      // Copy image to our directory
      await File(image.path).copy(filePath);

      logInfo('Image captured and saved to: $filePath');
      return filePath;
    } catch (e) {
      logError('Failed to capture image: $e');
      rethrow;
    }
  }

  @override
  Future<List<int>> captureImageBytes() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) {
        throw CameraException('Camera controller not initialized');
      }

      final XFile image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();

      logInfo('Image captured as bytes: ${bytes.length} bytes');
      return bytes.toList();
    } catch (e) {
      logError('Failed to capture image bytes', e);
      if (e is CameraException) {
        rethrow;
      }
      throw CameraException(
        'Failed to capture image bytes: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<String> processAndSaveImage(List<int> imageBytes,
      {String? fileName}) async {
    try {
      // Decode and process image
      final image = img.decodeImage(Uint8List.fromList(imageBytes));
      if (image == null) {
        throw CameraException('Failed to decode image');
      }

      // Apply image processing
      final processedImage = _processImage(image);

      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFileName = fileName ?? 'processed_$timestamp.jpg';
      final filePath = path.join(directory.path, 'scans', finalFileName);

      // Create scans directory if it doesn't exist
      final scansDir = Directory(path.dirname(filePath));
      if (!await scansDir.exists()) {
        await scansDir.create(recursive: true);
      }

      // Save processed image
      final file = File(filePath);
      await file.writeAsBytes(img.encodeJpg(processedImage, quality: 95));

      logInfo('Processed image saved to: $filePath');
      return filePath;
    } catch (e) {
      logError('Failed to process and save image', e);
      if (e is CameraException) {
        rethrow;
      }
      throw CameraException(
        'Failed to process and save image: ${e.toString()}',
        originalError: e,
      );
    }
  }

  img.Image _processImage(img.Image image) {
    // Resize if too large
    if (image.width > 2000 || image.height > 2000) {
      image = img.copyResize(
        image,
        width: image.width > 2000 ? 2000 : image.width,
        height: image.height > 2000 ? 2000 : image.height,
      );
    }

    // Convert to grayscale for better document scanning
    image = img.grayscale(image);

    // Enhance contrast
    image = img.contrast(image, contrast: 1.2);

    // Apply sharpening - simplified version
    // image = img.convolution(image, [0, -1, 0, -1, 5, -1, 0, -1, 0]);

    return image;
  }

  @override
  Future<void> startPreview() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) {
        throw CameraException('Camera controller not initialized');
      }
      await _controller!.startImageStream(_onImageStream);
      logInfo('Camera preview started');
    } catch (e) {
      logError('Failed to start camera preview', e);
      if (e is CameraException) {
        rethrow;
      }
      throw CameraException(
        'Failed to start camera preview: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<void> stopPreview() async {
    try {
      if (_controller != null) {
        await _controller!.stopImageStream();
        logInfo('Camera preview stopped');
      }
    } catch (e) {
      logError('Failed to stop camera preview: $e');
    }
  }

  void _onImageStream(CameraImage image) {
    // Handle image stream if needed for real-time processing
    // This could be used for live document detection
  }

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.setFlashMode(mode);
        logInfo('Flash mode set to: $mode');
      }
    } catch (e) {
      logError('Failed to set flash mode: $e');
    }
  }

  @override
  Future<void> setFocusMode(FocusMode mode) async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.setFocusMode(mode);
        logInfo('Focus mode set to: $mode');
      }
    } catch (e) {
      logError('Failed to set focus mode: $e');
    }
  }

  @override
  Future<void> setExposureMode(ExposureMode mode) async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.setExposureMode(mode);
        logInfo('Exposure mode set to: $mode');
      }
    } catch (e) {
      logError('Failed to set exposure mode: $e');
    }
  }

  @override
  Future<void> setFocusPoint(Offset point) async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.setFocusPoint(point);
        logInfo('Focus point set to: $point');
      }
    } catch (e) {
      logError('Failed to set focus point: $e');
    }
  }

  @override
  Future<void> setExposurePoint(Offset point) async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.setExposurePoint(point);
        logInfo('Exposure point set to: $point');
      }
    } catch (e) {
      logError('Failed to set exposure point: $e');
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await stopPreview();
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      logInfo('Camera service disposed');
    } catch (e) {
      logError('Failed to dispose camera service: $e');
    }
  }
}
