// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) => UserSettings(
  metadataStorageProvider: json['metadataStorageProvider'] as String,
  fileStorageProvider: json['fileStorageProvider'] as String,
  autoSync: json['autoSync'] as bool,
  syncIntervalMinutes: (json['syncIntervalMinutes'] as num).toInt(),
  biometricAuth: json['biometricAuth'] as bool,
  encryptionEnabled: json['encryptionEnabled'] as bool,
  defaultDocumentType: json['defaultDocumentType'] as String,
  defaultTags: (json['defaultTags'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  privacyAuditEnabled: json['privacyAuditEnabled'] as bool,
  language: json['language'] as String,
  theme: json['theme'] as String,
  notificationsEnabled: json['notificationsEnabled'] as bool,
  autoCategorization: json['autoCategorization'] as bool,
  ocrConfidenceThreshold: (json['ocrConfidenceThreshold'] as num).toDouble(),
  backupEnabled: json['backupEnabled'] as bool,
  lastBackupAt: json['lastBackupAt'] == null
      ? null
      : DateTime.parse(json['lastBackupAt'] as String),
  customSettings: json['customSettings'] as Map<String, dynamic>,
);

Map<String, dynamic> _$UserSettingsToJson(UserSettings instance) =>
    <String, dynamic>{
      'metadataStorageProvider': instance.metadataStorageProvider,
      'fileStorageProvider': instance.fileStorageProvider,
      'autoSync': instance.autoSync,
      'syncIntervalMinutes': instance.syncIntervalMinutes,
      'biometricAuth': instance.biometricAuth,
      'encryptionEnabled': instance.encryptionEnabled,
      'defaultDocumentType': instance.defaultDocumentType,
      'defaultTags': instance.defaultTags,
      'privacyAuditEnabled': instance.privacyAuditEnabled,
      'language': instance.language,
      'theme': instance.theme,
      'notificationsEnabled': instance.notificationsEnabled,
      'autoCategorization': instance.autoCategorization,
      'ocrConfidenceThreshold': instance.ocrConfidenceThreshold,
      'backupEnabled': instance.backupEnabled,
      'lastBackupAt': instance.lastBackupAt?.toIso8601String(),
      'customSettings': instance.customSettings,
    };
