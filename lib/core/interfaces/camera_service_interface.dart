import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Interface for camera operations
abstract class ICameraService {
  /// Get available cameras
  List<CameraDescription> get cameras;

  /// Get current camera controller
  CameraController? get controller;

  /// Check if service is initialized
  bool get isInitialized;

  /// Initialize the camera service
  Future<void> initialize();

  /// Initialize camera controller
  Future<void> initializeController({
    int cameraIndex = 0,
    ResolutionPreset resolution = ResolutionPreset.high,
    bool enableAudio = false,
  });

  /// Capture image and return file path
  Future<String> captureImage();

  /// Capture image and return bytes
  Future<List<int>> captureImageBytes();

  /// Process and save image
  Future<String> processAndSaveImage(List<int> imageBytes, {String? fileName});

  /// Start camera preview
  Future<void> startPreview();

  /// Stop camera preview
  Future<void> stopPreview();

  /// Set flash mode
  Future<void> setFlashMode(FlashMode mode);

  /// Set focus mode
  Future<void> setFocusMode(FocusMode mode);

  /// Set exposure mode
  Future<void> setExposureMode(ExposureMode mode);

  /// Set focus point
  Future<void> setFocusPoint(Offset point);

  /// Set exposure point
  Future<void> setExposurePoint(Offset point);

  /// Dispose resources
  Future<void> dispose();
}

