# Troubleshooting Logging System

## Overview

The troubleshooting logging system provides comprehensive, verbose logging of all app activities and errors to help diagnose issues when users report problems. The system follows SOLID principles and DRY patterns for maintainability and extensibility.

## Architecture

### SOLID Principles Applied

1. **Single Responsibility Principle (SRP)**
   - `LogFormatterService`: Only formats log entries
   - `LogFileService`: Only handles file operations
   - `LogRotationService`: Only handles log rotation
   - `TroubleshootingLoggerService`: Coordinates logging operations

2. **Open/Closed Principle (OCP)**
   - Services implement interfaces, allowing extension without modification
   - New log formatters can be added by implementing `ILogFormatter`

3. **Liskov Substitution Principle (LSP)**
   - All services can be substituted with their interface types

4. **Interface Segregation Principle (ISP)**
   - Separate interfaces for each concern (`ILogFormatter`, `ILogFileService`, `ILogRotationService`, `ITroubleshootingLogger`)

5. **Dependency Inversion Principle (DIP)**
   - High-level modules depend on abstractions (interfaces), not concrete implementations
   - Dependency injection via Riverpod providers

### DRY Pattern

- Log rotation logic is centralized in `LogRotationService` and reused
- Log formatting is centralized in `LogFormatterService`
- Base service integration ensures all services automatically log without code duplication

## Components

### 1. Log Levels

```dart
enum LogLevel {
  debug,    // Verbose debugging information
  info,     // Informational messages
  warning,  // Warning messages
  error,    // Error messages
  critical, // Critical errors requiring immediate attention
}
```

### 2. Log Entry Model

Each log entry contains:
- Timestamp
- Log level
- Message
- Tag (service name)
- Error details (if applicable)
- Stack trace (if applicable)
- Metadata (additional context)

### 3. Log Formatter Service

Formats log entries into human-readable strings with:
- Timestamps
- Emoji indicators for quick visual scanning
- Structured error information
- Stack traces (limited to 20 lines)
- JSON-formatted metadata

### 4. Log File Service

Manages log file operations:
- Creates log directory structure
- Writes log entries to file
- Reads log content
- Tracks file size

**Log File Location:**
- Path: `{app_documents}/logs/app.log`
- Format: Human-readable text file

### 5. Log Rotation Service

Implements rolling log mechanism:
- **Rotation Interval**: 24 hours (configurable)
- **Max File Size**: 10MB (configurable)
- **Archive Management**: Keeps last 5 archived logs
- **Archive Location**: `{app_documents}/logs/archive/app_{timestamp}.log`

### 6. Troubleshooting Logger Service

Main service that coordinates all logging:
- Filters logs based on minimum log level
- Maintains in-memory buffer (last 100 entries)
- Integrates with file service and rotation service
- Provides export functionality

### 7. Error Handler

Global error handler that captures:
- Flutter framework errors
- Uncaught exceptions
- Zone errors (async errors)

## Configuration

Configuration is centralized in `AppConfig`:

```dart
static const String logDirectory = 'logs';
static const String logFileName = 'app.log';
static const Duration logRotationInterval = Duration(hours: 24);
static const int maxLogFileSize = 10 * 1024 * 1024; // 10MB
static const LogLevel defaultLogLevel = LogLevel.debug; // Verbose by default
```

## Integration

### Automatic Logging

All services extending `BaseService` automatically log:
- Info messages → `logInfo()`
- Warnings → `logWarning()`
- Errors → `logError()`
- Debug messages → `logDebug()`

### Manual Logging

For custom logging:

```dart
final logger = ref.read(troubleshootingLoggerProvider);

await logger.info('User performed action', tag: 'UserAction');
await logger.error('Operation failed', tag: 'Operation', error: exception);
await logger.critical('Critical system failure', tag: 'System', error: error, stackTrace: stackTrace);
```

## Log Export

Users can export logs for troubleshooting:

1. **Via UI**: Use `LogExportDialog` widget
2. **Programmatically**: Call `troubleshootingLogger.exportLogs()`

### Export Format

Exported logs include:
- Application information (platform, OS version)
- Recent in-memory entries (last 100)
- Full log file content
- Formatted for easy reading

## Usage in UI

To add log export functionality to your app:

```dart
import 'package:ocrix/ui/widgets/log_export_dialog.dart';

// Show dialog
showDialog(
  context: context,
  builder: (context) => const LogExportDialog(),
);
```

## Best Practices

1. **Tag Usage**: Always use descriptive tags (service name, feature name)
2. **Error Context**: Include relevant metadata in error logs
3. **Stack Traces**: Include stack traces for errors and critical issues
4. **Metadata**: Add structured metadata for better debugging
5. **Log Levels**: Use appropriate log levels:
   - `debug`: Development/debugging information
   - `info`: Normal operations
   - `warning`: Potential issues
   - `error`: Errors that don't break functionality
   - `critical`: Critical errors requiring immediate attention

## Performance Considerations

- Logging is asynchronous and non-blocking
- In-memory buffer limits memory usage
- Log rotation prevents disk space issues
- File writes are batched when possible

## Security Considerations

- Logs may contain sensitive information
- Users should review logs before sharing
- Consider adding log sanitization for production

## Future Enhancements

- Remote log upload capability
- Log filtering and search
- Custom log formatters
- Log compression
- Encrypted log storage

