import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/interfaces/log_file_service_interface.dart';
import '../core/interfaces/log_rotation_service_interface.dart';
import '../core/interfaces/troubleshooting_logger_interface.dart';
import '../core/interfaces/log_formatter_interface.dart';
import '../services/log_file_service.dart';
import '../services/log_rotation_service.dart';
import '../services/troubleshooting_logger_service.dart';
import '../services/log_formatter_service.dart';

/// Provider for log formatter (SOLID - Dependency Injection)
final logFormatterProvider = Provider<ILogFormatter>((ref) {
  return const LogFormatterService();
});

/// Provider for log file service (SOLID - Dependency Injection)
final logFileServiceProvider = Provider<ILogFileService>((ref) {
  final formatter = ref.read(logFormatterProvider);
  return LogFileService(formatter: formatter);
});

/// Provider for log rotation service (SOLID - Dependency Injection)
final logRotationServiceProvider = Provider<ILogRotationService>((ref) {
  final logFileService = ref.read(logFileServiceProvider);
  return LogRotationService(logFileService);
});

/// Provider for troubleshooting logger (SOLID - Dependency Injection)
final troubleshootingLoggerProvider = Provider<ITroubleshootingLogger>((ref) {
  final logFileService = ref.read(logFileServiceProvider);
  final rotationService = ref.read(logRotationServiceProvider);
  return TroubleshootingLoggerService(logFileService, rotationService);
});

