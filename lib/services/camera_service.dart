import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  final Logger _logger = Logger();
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  List<CameraDescription> get cameras => _cameras;
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }
      _isInitialized = true;
      _logger.i('Camera service initialized with ${_cameras.length} cameras');
    } catch (e) {
      _logger.e('Failed to initialize camera service: $e');
      rethrow;
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
      _logger.i('Camera controller initialized for ${camera.name}');
    } catch (e) {
      _logger.e('Failed to initialize camera controller: $e');
      rethrow;
    }
  }

  Future<String> captureImage() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) {
        throw Exception('Camera controller not initialized');
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

      _logger.i('Image captured and saved to: $filePath');
      return filePath;
    } catch (e) {
      _logger.e('Failed to capture image: $e');
      rethrow;
    }
  }

  Future<Uint8List> captureImageBytes() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) {
        throw Exception('Camera controller not initialized');
      }

      final XFile image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();

      _logger.i('Image captured as bytes: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      _logger.e('Failed to capture image bytes: $e');
      rethrow;
    }
  }

  Future<String> processAndSaveImage(Uint8List imageBytes,
      {String? fileName}) async {
    try {
      // Decode and process image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
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

      _logger.i('Processed image saved to: $filePath');
      return filePath;
    } catch (e) {
      _logger.e('Failed to process and save image: $e');
      rethrow;
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

  Future<void> startPreview() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) {
        throw Exception('Camera controller not initialized');
      }
      await _controller!.startImageStream(_onImageStream);
      _logger.i('Camera preview started');
    } catch (e) {
      _logger.e('Failed to start camera preview: $e');
      rethrow;
    }
  }

  Future<void> stopPreview() async {
    try {
      if (_controller != null) {
        await _controller!.stopImageStream();
        _logger.i('Camera preview stopped');
      }
    } catch (e) {
      _logger.e('Failed to stop camera preview: $e');
    }
  }

  void _onImageStream(CameraImage image) {
    // Handle image stream if needed for real-time processing
    // This could be used for live document detection
  }

  Future<void> setFlashMode(FlashMode mode) async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.setFlashMode(mode);
        _logger.i('Flash mode set to: $mode');
      }
    } catch (e) {
      _logger.e('Failed to set flash mode: $e');
    }
  }

  Future<void> setFocusMode(FocusMode mode) async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.setFocusMode(mode);
        _logger.i('Focus mode set to: $mode');
      }
    } catch (e) {
      _logger.e('Failed to set focus mode: $e');
    }
  }

  Future<void> setExposureMode(ExposureMode mode) async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.setExposureMode(mode);
        _logger.i('Exposure mode set to: $mode');
      }
    } catch (e) {
      _logger.e('Failed to set exposure mode: $e');
    }
  }

  Future<void> setFocusPoint(Offset point) async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.setFocusPoint(point);
        _logger.i('Focus point set to: $point');
      }
    } catch (e) {
      _logger.e('Failed to set focus point: $e');
    }
  }

  Future<void> setExposurePoint(Offset point) async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.setExposurePoint(point);
        _logger.i('Exposure point set to: $point');
      }
    } catch (e) {
      _logger.e('Failed to set exposure point: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await stopPreview();
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _logger.i('Camera service disposed');
    } catch (e) {
      _logger.e('Failed to dispose camera service: $e');
    }
  }
}
