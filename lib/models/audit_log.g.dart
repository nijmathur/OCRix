// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditLog _$AuditLogFromJson(Map<String, dynamic> json) => AuditLog(
  id: json['id'] as String,
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
);

Map<String, dynamic> _$AuditLogToJson(AuditLog instance) => <String, dynamic>{
  'id': instance.id,
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
