import 'dart:io';
import 'package:path/path.dart';
import '../core/interfaces/log_rotation_service_interface.dart';
import '../core/interfaces/log_file_service_interface.dart';
import '../core/config/app_config.dart';
import '../core/base/base_service.dart';

/// Service for log rotation (SOLID - Single Responsibility, DRY - Reusable)
class LogRotationService extends BaseService implements ILogRotationService {
  final ILogFileService _logFileService;
  Duration _rotationInterval = AppConfig.logRotationInterval;
  DateTime? _lastRotationTime;

  LogRotationService(this._logFileService);

  @override
  String get serviceName => 'LogRotationService';

  @override
  Duration get rotationInterval => _rotationInterval;

  @override
  void setRotationInterval(Duration interval) {
    _rotationInterval = interval;
    logInfo('Log rotation interval set to: ${interval.inHours} hours');
  }

  @override
  Future<void> checkAndRotate() async {
    try {
      final now = DateTime.now();

      // Check if rotation is needed
      if (_lastRotationTime == null) {
        // First time - check file modification time
        final logFile = File(_logFileService.currentLogFilePath);
        if (await logFile.exists()) {
          final modified = await logFile.lastModified();
          _lastRotationTime = modified;
        } else {
          _lastRotationTime = now;
          return; // No file to rotate
        }
      }

      final timeSinceLastRotation = now.difference(_lastRotationTime!);

      // Check if rotation interval has passed
      if (timeSinceLastRotation >= _rotationInterval) {
        await rotate();
      }

      // Also check file size
      final fileSize = await _logFileService.getFileSize();
      if (fileSize > AppConfig.maxLogFileSize) {
        logInfo('Log file size ($fileSize bytes) exceeds maximum, rotating...');
        await rotate();
      }
    } catch (e) {
      logError('Failed to check and rotate logs', e);
      // Don't throw - rotation failures shouldn't break the app
    }
  }

  @override
  Future<void> rotate() async {
    try {
      logInfo('Rotating log file...');

      final currentLogFile = File(_logFileService.currentLogFilePath);
      final logsDir = currentLogFile.parent;

      // Create archive directory
      final archiveDir = Directory(join(logsDir.path, 'archive'));
      if (!await archiveDir.exists()) {
        await archiveDir.create(recursive: true);
      }

      // Generate archive filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final archivePath = join(archiveDir.path, 'app_$timestamp.log');

      // Move current log to archive
      if (await currentLogFile.exists()) {
        await currentLogFile.copy(archivePath);
        logInfo('Log archived to: $archivePath');
      }

      // Clear current log file (start fresh)
      await _logFileService.clear();

      // Update rotation time
      _lastRotationTime = DateTime.now();

      // Clean up old archives (keep last 5)
      await _cleanupOldArchives(archiveDir);

      logInfo('Log rotation completed');
    } catch (e) {
      logError('Failed to rotate log file', e);
      // Don't throw - rotation failures shouldn't break the app
    }
  }

  Future<void> _cleanupOldArchives(Directory archiveDir) async {
    try {
      final files = archiveDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.log'))
          .toList();

      // Sort by modification time (oldest first)
      files.sort(
        (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()),
      );

      // Keep only last 5 archives
      const maxArchives = 5;
      if (files.length > maxArchives) {
        final toDelete = files.take(files.length - maxArchives).toList();
        for (final file in toDelete) {
          await file.delete();
          logInfo('Deleted old log archive: ${file.path}');
        }
      }
    } catch (e) {
      logError('Failed to cleanup old archives', e);
    }
  }
}
