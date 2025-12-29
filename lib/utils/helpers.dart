import 'dart:io';
import 'dart:typed_data';
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

  static String removeExtraSpaces(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
