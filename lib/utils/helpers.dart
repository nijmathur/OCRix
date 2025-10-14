import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

class FileHelper {
  static Future<String> getDocumentsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<String> getTempDirectory() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  static Future<String> createDirectory(String dirPath) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return dirPath;
  }

  static Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  static Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<String> copyFile(
      String sourcePath, String destinationPath) async {
    final sourceFile = File(sourcePath);

    // Create destination directory if it doesn't exist
    await createDirectory(path.dirname(destinationPath));

    await sourceFile.copy(destinationPath);
    return destinationPath;
  }

  static Future<String> moveFile(
      String sourcePath, String destinationPath) async {
    final sourceFile = File(sourcePath);

    // Create destination directory if it doesn't exist
    await createDirectory(path.dirname(destinationPath));

    await sourceFile.rename(destinationPath);
    return destinationPath;
  }

  static Future<Uint8List> readFileAsBytes(String filePath) async {
    final file = File(filePath);
    return await file.readAsBytes();
  }

  static Future<String> readFileAsString(String filePath) async {
    final file = File(filePath);
    return await file.readAsString();
  }

  static Future<void> writeFile(String filePath, Uint8List bytes) async {
    final file = File(filePath);
    await createDirectory(path.dirname(filePath));
    await file.writeAsBytes(bytes);
  }

  static Future<void> writeStringToFile(String filePath, String content) async {
    final file = File(filePath);
    await createDirectory(path.dirname(filePath));
    await file.writeAsString(content);
  }

  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  static String getDirectoryPath(String filePath) {
    return path.dirname(filePath);
  }

  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  static Future<DateTime> getFileModifiedDate(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.lastModified();
    }
    return DateTime.now();
  }
}

class ImageHelper {
  static Future<Uint8List> resizeImage(
    Uint8List imageBytes, {
    int? maxWidth,
    int? maxHeight,
    int quality = 95,
  }) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    img.Image resizedImage = image;

    if (maxWidth != null || maxHeight != null) {
      resizedImage = img.copyResize(
        image,
        width: maxWidth,
        height: maxHeight,
        maintainAspect: true,
      );
    }

    return Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
  }

  static Future<Uint8List> enhanceImage(Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Convert to grayscale
    img.Image enhancedImage = img.grayscale(image);

    // Enhance contrast
    enhancedImage = img.contrast(enhancedImage, contrast: 1.2);

    // Apply sharpening - simplified version
    // enhancedImage = img.convolution(enhancedImage, [0, -1, 0, -1, 5, -1, 0, -1, 0]);

    return Uint8List.fromList(img.encodeJpg(enhancedImage, quality: 95));
  }

  static Future<Map<String, int>> getImageDimensions(
      Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    return {
      'width': image.width,
      'height': image.height,
    };
  }

  static Future<bool> isValidImage(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      return image != null;
    } catch (e) {
      return false;
    }
  }
}

class DateHelper {
  static String formatDate(DateTime date, {String pattern = 'MMM dd, yyyy'}) {
    return DateFormat(pattern).format(date);
  }

  static String formatTime(DateTime date, {String pattern = 'HH:mm'}) {
    return DateFormat(pattern).format(date);
  }

  static String formatDateTime(DateTime date,
      {String pattern = 'MMM dd, yyyy HH:mm'}) {
    return DateFormat(pattern).format(date);
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      return DateFormat('MMM dd').format(date);
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

class ValidationHelper {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidUrl(String url) {
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }

  static bool isValidFileName(String fileName) {
    // Check for invalid characters
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    return !invalidChars.hasMatch(fileName) && fileName.trim().isNotEmpty;
  }

  static bool isValidImageFile(String filePath) {
    final extension = FileHelper.getFileExtension(filePath).toLowerCase();
    const validExtensions = ['.jpg', '.jpeg', '.png', '.bmp', '.gif', '.webp'];
    return validExtensions.contains(extension);
  }

  static bool isValidDocumentFile(String filePath) {
    final extension = FileHelper.getFileExtension(filePath).toLowerCase();
    const validExtensions = ['.pdf', '.doc', '.docx', '.txt', '.rtf'];
    return validExtensions.contains(extension);
  }

  static String sanitizeFileName(String fileName) {
    // Remove invalid characters
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }
}

class ColorHelper {
  static Color getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        return Colors.green;
      case 'warning':
      case 'pending':
        return Colors.orange;
      case 'error':
      case 'failed':
        return Colors.red;
      case 'info':
      case 'processing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  static Color getDocumentTypeColor(String documentType) {
    switch (documentType.toLowerCase()) {
      case 'receipt':
        return Colors.blue;
      case 'contract':
        return Colors.purple;
      case 'manual':
        return Colors.green;
      case 'invoice':
        return Colors.orange;
      case 'businesscard':
        return Colors.teal;
      case 'id':
        return Colors.red;
      case 'passport':
        return Colors.indigo;
      case 'license':
        return Colors.amber;
      case 'certificate':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}

class StringHelper {
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength - suffix.length)}$suffix';
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String capitalizeWords(String text) {
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  static String removeExtraSpaces(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String extractKeywords(String text, {int maxKeywords = 10}) {
    // Simple keyword extraction - remove common words and get unique words
    final commonWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'is',
      'are',
      'was',
      'were',
      'be',
      'been',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'could',
      'should'
    };

    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(' ')
        .where((word) => word.length > 2 && !commonWords.contains(word))
        .toSet()
        .take(maxKeywords)
        .toList();

    return words.join(' ');
  }
}
