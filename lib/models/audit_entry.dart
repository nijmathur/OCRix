import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../core/models/audit_log_level.dart';
import 'audit_log.dart';

part 'audit_entry.g.dart';

/// Tamper-proof audit entry with checksums and chaining for integrity verification
@JsonSerializable()
class AuditEntry extends Equatable {
  final String id;
  final AuditLogLevel level;
  final AuditAction action;
  final String resourceType;
  final String resourceId;
  final String userId;
  final DateTime timestamp;
  final String? details;
  final String? location;
  final String? deviceInfo;
  final bool isSuccess;
  final String? errorMessage;

  // Tamper-proof fields
  final String checksum; // SHA-256 hash of entry data
  final String? previousEntryId; // Chain to previous entry
  final String? previousChecksum; // Verify chain integrity

  const AuditEntry({
    required this.id,
    required this.level,
    required this.action,
    required this.resourceType,
    required this.resourceId,
    required this.userId,
    required this.timestamp,
    this.details,
    this.location,
    this.deviceInfo,
    required this.isSuccess,
    this.errorMessage,
    required this.checksum,
    this.previousEntryId,
    this.previousChecksum,
  });

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
    final timestamp = DateTime.now();

    // Create checksum from entry data (excluding checksum itself)
    final entryData = {
      'id': id,
      'level': level.name,
      'action': action.name,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
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

  /// Calculate SHA-256 checksum of entry data
  static String _calculateChecksum(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify the checksum of this entry
  bool verifyChecksum() {
    final entryData = {
      'id': id,
      'level': level.name,
      'action': action.name,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
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
  Map<String, dynamic> toJson() => _$AuditEntryToJson(this);

  @override
  List<Object?> get props => [
        id,
        level,
        action,
        resourceType,
        resourceId,
        userId,
        timestamp,
        details,
        location,
        deviceInfo,
        isSuccess,
        errorMessage,
        checksum,
        previousEntryId,
        previousChecksum,
      ];
}
