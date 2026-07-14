import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'audit_log.freezed.dart';
part 'audit_log.g.dart';

@freezed
abstract class AuditLog with _$AuditLog {
  const AuditLog._();

  const factory AuditLog({
    required String id,
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
  }) = _AuditLog;

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
  String get displayName => switch (this) {
    AuditAction.create => 'Create',
    AuditAction.read => 'Read',
    AuditAction.update => 'Update',
    AuditAction.delete => 'Delete',
    AuditAction.sync => 'Sync',
    AuditAction.export => 'Export',
    AuditAction.import => 'Import',
    AuditAction.login => 'Login',
    AuditAction.logout => 'Logout',
    AuditAction.encrypt => 'Encrypt',
    AuditAction.decrypt => 'Decrypt',
    AuditAction.backup => 'Backup',
    AuditAction.restore => 'Restore',
  };
}
