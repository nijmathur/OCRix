// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditEntry _$AuditEntryFromJson(Map<String, dynamic> json) => AuditEntry(
      id: json['id'] as String,
      level: $enumDecode(_$AuditLogLevelEnumMap, json['level']),
      action: $enumDecode(_$AuditActionEnumMap, json['action']),
      resourceType: json['resourceType'] as String,
      resourceId: json['resourceId'] as String,
      userId: json['userId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      details: json['details'] as String?,
      location: json['location'] as String?,
      deviceInfo: json['deviceInfo'] as String?,
      isSuccess: json['isSuccess'] as bool,
      errorMessage: json['errorMessage'] as String?,
      checksum: json['checksum'] as String,
      previousEntryId: json['previousEntryId'] as String?,
      previousChecksum: json['previousChecksum'] as String?,
    );

Map<String, dynamic> _$AuditEntryToJson(AuditEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'level': _$AuditLogLevelEnumMap[instance.level]!,
      'action': _$AuditActionEnumMap[instance.action]!,
      'resourceType': instance.resourceType,
      'resourceId': instance.resourceId,
      'userId': instance.userId,
      'timestamp': instance.timestamp.toIso8601String(),
      'details': instance.details,
      'location': instance.location,
      'deviceInfo': instance.deviceInfo,
      'isSuccess': instance.isSuccess,
      'errorMessage': instance.errorMessage,
      'checksum': instance.checksum,
      'previousEntryId': instance.previousEntryId,
      'previousChecksum': instance.previousChecksum,
    };

const _$AuditLogLevelEnumMap = {
  AuditLogLevel.info: 'info',
  AuditLogLevel.verbose: 'verbose',
  AuditLogLevel.compulsory: 'compulsory',
};

const _$AuditActionEnumMap = {
  AuditAction.create: 'create',
  AuditAction.read: 'read',
  AuditAction.update: 'update',
  AuditAction.delete: 'delete',
  AuditAction.sync: 'sync',
  AuditAction.export: 'export',
  AuditAction.import: 'import',
  AuditAction.login: 'login',
  AuditAction.logout: 'logout',
  AuditAction.encrypt: 'encrypt',
  AuditAction.decrypt: 'decrypt',
  AuditAction.backup: 'backup',
  AuditAction.restore: 'restore',
};
