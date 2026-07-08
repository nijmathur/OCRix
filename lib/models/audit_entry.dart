import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import '../core/models/audit_log_level.dart';
import 'audit_log.dart';

part 'audit_entry.freezed.dart';
part 'audit_entry.g.dart';

/// Tamper-proof audit entry with checksums and chaining for integrity verification
@freezed
abstract class AuditEntry with _$AuditEntry {
  const AuditEntry._();

  const factory AuditEntry({
    required String id,
    required AuditLogLevel level,
    required AuditAction action,
    required String resourceType,
    required String resourceId,
    required String userId,
    required DateTime timestamp,
    String? details,
    String? location,
    String? deviceInfo,
    required bool isSuccess,
    String? errorMessage,
    // Tamper-proof fields
    required String checksum,
    String? previousEntryId,
    String? previousChecksum,
  }) = _AuditEntry;

  factory AuditEntry.create({
    required AuditLogLevel level,
    required AuditAction action,
    required String resourceType,
    required String resourceId,
    required String userId,
    String? details,
    String? location,
    String? deviceInfo,
    bool isSuccess = true,
    String? errorMessage,
    String? previousEntryId,
    String? previousChecksum,
  }) {
    final id = const Uuid().v4();
    // Normalize timestamp to milliseconds precision (database stores only milliseconds)
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().millisecondsSinceEpoch,
    );

    // Create checksum from entry data (excluding checksum itself)
    final entryData = {
      'id': id,
      'level': level.name,
      'action': action.name,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'userId': userId,
      'timestamp': _normalizeTimestampForChecksum(timestamp).toIso8601String(),
      'details': details ?? '',
      'location': location ?? '',
      'deviceInfo': deviceInfo ?? '',
      'isSuccess': isSuccess,
      'errorMessage': errorMessage ?? '',
      'previousEntryId': previousEntryId ?? '',
      'previousChecksum': previousChecksum ?? '',
    };

    final checksum = _calculateChecksum(entryData);

    return AuditEntry(
      id: id,
      level: level,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      userId: userId,
      timestamp: timestamp,
      details: details,
      location: location,
      deviceInfo: deviceInfo,
      isSuccess: isSuccess,
      errorMessage: errorMessage,
      checksum: checksum,
      previousEntryId: previousEntryId,
      previousChecksum: previousChecksum,
    );
  }

  /// Normalize timestamp to milliseconds precision for checksum calculation
  /// This ensures consistency with database storage (which stores milliseconds only)
  static DateTime _normalizeTimestampForChecksum(DateTime timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(
      timestamp.millisecondsSinceEpoch,
    );
  }

  /// Calculate SHA-256 checksum of entry data
  static String _calculateChecksum(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify the checksum of this entry
  bool verifyChecksum() {
    // Normalize timestamp to match database precision (milliseconds only)
    final normalizedTimestamp = _normalizeTimestampForChecksum(timestamp);

    final entryData = {
      'id': id,
      'level': level.name,
      'action': action.name,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'userId': userId,
      'timestamp': normalizedTimestamp.toIso8601String(),
      'details': details ?? '',
      'location': location ?? '',
      'deviceInfo': deviceInfo ?? '',
      'isSuccess': isSuccess,
      'errorMessage': errorMessage ?? '',
      'previousEntryId': previousEntryId ?? '',
      'previousChecksum': previousChecksum ?? '',
    };

    final calculatedChecksum = _calculateChecksum(entryData);
    return calculatedChecksum == checksum;
  }

  /// Verify chain integrity with previous entry
  bool verifyChain(String? previousEntryChecksum) {
    if (previousEntryId == null) {
      // First entry in chain, no previous to verify
      return true;
    }
    return previousChecksum == previousEntryChecksum;
  }

  factory AuditEntry.fromJson(Map<String, dynamic> json) =>
      _$AuditEntryFromJson(json);
}
