import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

part 'audit_log.g.dart';

@JsonSerializable()
class AuditLog extends Equatable {
  final String id;
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

  const AuditLog({
    required this.id,
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
  });

  factory AuditLog.create({
    required AuditAction action,
    required String resourceType,
    required String resourceId,
    required String userId,
    String? details,
    String? location,
    String? deviceInfo,
    bool isSuccess = true,
    String? errorMessage,
  }) {
    return AuditLog(
      id: const Uuid().v4(),
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      userId: userId,
      timestamp: DateTime.now(),
      details: details,
      location: location,
      deviceInfo: deviceInfo,
      isSuccess: isSuccess,
      errorMessage: errorMessage,
    );
  }

  factory AuditLog.fromJson(Map<String, dynamic> json) =>
      _$AuditLogFromJson(json);
  Map<String, dynamic> toJson() => _$AuditLogToJson(this);

  @override
  List<Object?> get props => [
        id,
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
      ];
}

enum AuditAction {
  create,
  read,
  update,
  delete,
  sync,
  export,
  import,
  login,
  logout,
  encrypt,
  decrypt,
  backup,
  restore,
}

extension AuditActionExtension on AuditAction {
  String get displayName {
    switch (this) {
      case AuditAction.create:
        return 'Create';
      case AuditAction.read:
        return 'Read';
      case AuditAction.update:
        return 'Update';
      case AuditAction.delete:
        return 'Delete';
      case AuditAction.sync:
        return 'Sync';
      case AuditAction.export:
        return 'Export';
      case AuditAction.import:
        return 'Import';
      case AuditAction.login:
        return 'Login';
      case AuditAction.logout:
        return 'Logout';
      case AuditAction.encrypt:
        return 'Encrypt';
      case AuditAction.decrypt:
        return 'Decrypt';
      case AuditAction.backup:
        return 'Backup';
      case AuditAction.restore:
        return 'Restore';
    }
  }
}
