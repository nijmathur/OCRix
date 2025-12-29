import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'user_settings.g.dart';

@JsonSerializable()
class UserSettings extends Equatable {
  final String metadataStorageProvider;
  final String fileStorageProvider;
  final bool autoSync;
  final int syncIntervalMinutes;
  final bool biometricAuth;
  final bool encryptionEnabled;
  final String defaultDocumentType;
  final List<String> defaultTags;
  final bool privacyAuditEnabled;
  final String language;
  final String theme;
  final bool notificationsEnabled;
  final bool autoCategorization;
  final double ocrConfidenceThreshold;
  final bool backupEnabled;
  final DateTime? lastBackupAt;
  final Map<String, dynamic> customSettings;

  const UserSettings({
    required this.metadataStorageProvider,
    required this.fileStorageProvider,
    required this.autoSync,
    required this.syncIntervalMinutes,
    required this.biometricAuth,
    required this.encryptionEnabled,
    required this.defaultDocumentType,
    required this.defaultTags,
    required this.privacyAuditEnabled,
    required this.language,
    required this.theme,
    required this.notificationsEnabled,
    required this.autoCategorization,
    required this.ocrConfidenceThreshold,
    required this.backupEnabled,
    this.lastBackupAt,
    required this.customSettings,
  });

  factory UserSettings.defaultSettings() {
    return const UserSettings(
      metadataStorageProvider: 'local',
      fileStorageProvider: 'local',
      autoSync: false,
      syncIntervalMinutes: 60,
      biometricAuth: false,
      encryptionEnabled: true,
      defaultDocumentType: 'other',
      defaultTags: [],
      privacyAuditEnabled: true,
      language: 'en',
      theme: 'system',
      notificationsEnabled: true,
      autoCategorization: false,
      ocrConfidenceThreshold: 0.7,
      backupEnabled: false,
      customSettings: {},
    );
  }

  UserSettings copyWith({
    String? metadataStorageProvider,
    String? fileStorageProvider,
    bool? autoSync,
    int? syncIntervalMinutes,
    bool? biometricAuth,
    bool? encryptionEnabled,
    String? defaultDocumentType,
    List<String>? defaultTags,
    bool? privacyAuditEnabled,
    String? language,
    String? theme,
    bool? notificationsEnabled,
    bool? autoCategorization,
    double? ocrConfidenceThreshold,
    bool? backupEnabled,
    DateTime? lastBackupAt,
    Map<String, dynamic>? customSettings,
  }) {
    return UserSettings(
      metadataStorageProvider:
          metadataStorageProvider ?? this.metadataStorageProvider,
      fileStorageProvider: fileStorageProvider ?? this.fileStorageProvider,
      autoSync: autoSync ?? this.autoSync,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      defaultDocumentType: defaultDocumentType ?? this.defaultDocumentType,
      defaultTags: defaultTags ?? this.defaultTags,
      privacyAuditEnabled: privacyAuditEnabled ?? this.privacyAuditEnabled,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoCategorization: autoCategorization ?? this.autoCategorization,
      ocrConfidenceThreshold:
          ocrConfidenceThreshold ?? this.ocrConfidenceThreshold,
      backupEnabled: backupEnabled ?? this.backupEnabled,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);

  @override
  List<Object?> get props => [
    metadataStorageProvider,
    fileStorageProvider,
    autoSync,
    syncIntervalMinutes,
    biometricAuth,
    encryptionEnabled,
    defaultDocumentType,
    defaultTags,
    privacyAuditEnabled,
    language,
    theme,
    notificationsEnabled,
    autoCategorization,
    ocrConfidenceThreshold,
    backupEnabled,
    lastBackupAt,
    customSettings,
  ];
}
